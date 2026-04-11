-module(iso_filter_test).
-include_lib("eunit/include/eunit.hrl").

%%====================================================================
%% is_standard_href/1
%%====================================================================

is_standard_href_valid_test() ->
    ?assert(iso_filter_app:is_standard_href("/standard/62085.html")),
    ?assert(iso_filter_app:is_standard_href("/standard/9001.html")),
    ?assert(iso_filter_app:is_standard_href("/standard/123456.html")).

is_standard_href_invalid_test() ->
    ?assertNot(iso_filter_app:is_standard_href("/home.html")),
    ?assertNot(iso_filter_app:is_standard_href("https://www.iso.org/home.html")),
    ?assertNot(iso_filter_app:is_standard_href("/standard/")),        %% no number
    ?assertNot(iso_filter_app:is_standard_href("/standardization/")). %% not /standard/NNN

%%====================================================================
%% build_embryo/2
%%====================================================================

build_embryo_relative_test() ->
    E = iso_filter_app:build_embryo("/standard/62085.html", "ISO 9001:2015"),
    ?assertEqual(<<"url">>, maps:get(<<"type">>, E)),
    Props = maps:get(<<"properties">>, E),
    ?assertEqual(<<"https://www.iso.org/standard/62085.html">>,
                 maps:get(<<"url">>,    Props)),
    ?assertEqual(<<"ISO 9001:2015">>,   maps:get(<<"title">>,  Props)),
    ?assertEqual(<<"iso.org">>,         maps:get(<<"source">>, Props)).

build_embryo_absolute_test() ->
    E = iso_filter_app:build_embryo("https://www.iso.org/standard/1.html", "ISO 1"),
    Props = maps:get(<<"properties">>, E),
    ?assertEqual(<<"https://www.iso.org/standard/1.html">>, maps:get(<<"url">>, Props)).

%%====================================================================
%% extract_standard_links/1
%%====================================================================

extract_standard_links_basic_test() ->
    Html = "<html><body>"
           "<a href=\"/standard/62085.html\">ISO 9001:2015</a>"
           "<a href=\"/standard/45001.html\">ISO 45001:2018 — Santé et sécurité</a>"
           "<a href=\"/home.html\">Home</a>"
           "</body></html>",
    Results = iso_filter_app:extract_standard_links(Html),
    ?assertEqual(2, length(Results)),
    [First | _] = Results,
    Props = maps:get(<<"properties">>, First),
    ?assertEqual(<<"https://www.iso.org/standard/62085.html">>, maps:get(<<"url">>, Props)).

extract_standard_links_dedup_test() ->
    Html = "<a href=\"/standard/1.html\">ISO 1</a>"
           "<a href=\"/standard/1.html\">ISO 1</a>",
    Results = iso_filter_app:extract_standard_links(Html),
    ?assertEqual(1, length(Results)).

extract_standard_links_empty_test() ->
    ?assertEqual([], iso_filter_app:extract_standard_links("<p>no links</p>")).

extract_standard_links_no_standard_test() ->
    Html = "<a href=\"/home.html\">Home</a>"
           "<a href=\"https://example.com\">External</a>",
    ?assertEqual([], iso_filter_app:extract_standard_links(Html)).
