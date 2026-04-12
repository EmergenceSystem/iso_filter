# iso_filter
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE.md)

An [em_filter](https://hex.pm/packages/em_filter) agent that searches [ISO](https://www.iso.org/) for international standards by reference or keyword and returns results as [Emergence](https://github.com/EmergenceSystem/em_disco) results.

## Query

Any ISO standard reference or keyword accepted by the iso.org search.

| Input form | Example |
|---|---|
| Standard reference | `ISO 9001`, `ISO/IEC 27001` |
| Keyword | `quality management`, `information security` |
| Number only | `9001`, `27001` |

| Field | Example |
|---|---|
| title | `ISO 9001:2015 — Quality management systems` |
| resume | short description from the standard page |
| url | `https://www.iso.org/standard/...` |
| source | `iso.org` |

## Usage

**Via curl (direct to em_disco):**

```bash
# By reference
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -d '{"value": "ISO 9001", "capabilities": ["iso"]}'

# By keyword
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -d '{"value": "information security management", "capabilities": ["iso"]}'
```

**Via Erlang shell:**

```erlang
emquest_cli:query(<<"ISO 27001">>).
emquest_cli:query(<<"quality management">>).
```

## Installation

```bash
git clone https://github.com/EmergenceSystem/iso_filter.git
cd iso_filter
rebar3 shell --apps iso_filter
```

Requires `em_disco` running on `localhost:8080` (configured in `emergence.conf`).

## Capabilities

`search`, `query`, `normes`, `iso`, `standards`, `international`, `certification`, `reglementation`

## License

Apache 2.0 — see [LICENSE.md](LICENSE.md).
