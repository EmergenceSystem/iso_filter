%%%-------------------------------------------------------------------
%%% @doc ISO international standards search agent (iso.org).
%%%
%%% Searches iso.org for ISO standards by reference or keyword.
%%% Returns url embryos linking to the standard page.
%%%
%%% Handler contract: handle/2 (Body, Memory) -> {RawList, Memory}.
%%% @end
%%%-------------------------------------------------------------------
-module(iso_filter_app).
-behaviour(application).

-export([start/2, stop/1]).
-export([handle/2, base_capabilities/0]).

%% Exported for testing
-export([extract_standard_links/1, is_standard_href/1, build_embryo/2]).

-define(SEARCH_URL, "https://www.iso.org/search.html?q=").
-define(BASE_URL,   "https://www.iso.org").
-define(USER_AGENT, "Emergence-ISO-Filter/1.0").

%%====================================================================
%% Capability cascade
%%====================================================================

-spec base_capabilities() -> [binary()].
base_capabilities() ->
    em_filter:base_capabilities() ++
        [<<"normes">>, <<"iso">>, <<"standards">>,
         <<"international">>, <<"certification">>, <<"reglementation">>].

%%====================================================================
%% Application behaviour
%%====================================================================

start(_Type, _Args) ->
    em_filter:start_agent(iso_filter, ?MODULE, #{
        capabilities => base_capabilities()
    }),
    {ok, self()}.

stop(_State) ->
    em_filter:stop_agent(iso_filter).

%%====================================================================
%% Agent handler
%%====================================================================

handle(Body, Memory) when is_binary(Body) ->
    {search(Body), Memory};
handle(_Body, Memory) ->
    {[], Memory}.

%%====================================================================
%% Search
%%====================================================================

search(QueryBin) ->
    {Query, Timeout} = extract_params(QueryBin),
    Url = ?SEARCH_URL ++ uri_string:quote(Query) ++ "&sort=rel&rows=20",
    Headers = [{"User-Agent", ?USER_AGENT},
               {"Accept",     "text/html,application/xhtml+xml"}],
    case httpc:request(get, {Url, Headers},
                       [{timeout, Timeout * 1000}],
                       [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Body}} ->
            Html = binary_to_list(Body),
            extract_standard_links(Html);
        _ ->
            []
    end.

extract_params(JsonBinary) ->
    try json:decode(JsonBinary) of
        Map when is_map(Map) ->
            Value   = binary_to_list(maps:get(<<"value">>, Map,
                          maps:get(<<"query">>, Map, <<"">>))),
            Timeout = case maps:get(<<"timeout">>, Map, undefined) of
                undefined            -> 10;
                T when is_integer(T) -> T;
                T when is_binary(T)  -> binary_to_integer(T)
            end,
            {Value, Timeout};
        _ ->
            {binary_to_list(JsonBinary), 10}
    catch
        _:_ -> {binary_to_list(JsonBinary), 10}
    end.

%%====================================================================
%% HTML parsing
%%====================================================================

%% @doc Extract ISO standard links from iso.org search HTML.
%% Regex-based extraction to handle any page structure.
-spec extract_standard_links(string() | binary()) -> [map()].
extract_standard_links(Html) ->
    Bin     = unicode:characters_to_binary(Html),
    Pattern = "<a[^>]+href=[\"']([^\"']+)[\"'][^>]*>(.*?)</a>",
    case re:run(Bin, Pattern,
                [global, {capture, all_but_first, binary}, caseless, dotall, unicode]) of
        {match, Pairs} ->
            Seen = sets:new(),
            {Results, _} = lists:foldl(fun([Href, Inner], {Acc, Visited}) ->
                Text = string:trim(em_filter:get_text(binary_to_list(Inner))),
                case is_standard_href(binary_to_list(Href))
                     andalso Text =/= ""
                     andalso not sets:is_element(Href, Visited) of
                    true ->
                        Embryo = build_embryo(binary_to_list(Href), Text),
                        {[Embryo | Acc], sets:add_element(Href, Visited)};
                    false ->
                        {Acc, Visited}
                end
            end, {[], Seen}, Pairs),
            lists:reverse(Results);
        _ ->
            []
    end.

%% @doc True if the href points to an ISO standard page.
-spec is_standard_href(string()) -> boolean().
is_standard_href(Href) ->
    re:run(Href, "^/standard/[0-9]+", [{capture, none}]) =:= match.

%% @doc Build a url embryo from an ISO standard href and its link text.
-spec build_embryo(string(), string()) -> map().
build_embryo(Href, Title) ->
    FullUrl = case string:prefix(Href, "http") of
        nomatch -> ?BASE_URL ++ Href;
        _       -> Href
    end,
    #{<<"type">>       => <<"url">>,
      <<"properties">> => #{
          <<"url">>    => unicode:characters_to_binary(FullUrl),
          <<"title">>  => unicode:characters_to_binary(Title),
          <<"source">> => <<"iso.org">>
      }}.
