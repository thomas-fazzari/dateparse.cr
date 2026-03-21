# DateParse

[![CI](https://github.com/thomas-fazzari/dateparse.cr/actions/workflows/ci.yml/badge.svg)](https://github.com/thomas-fazzari/dateparse.cr/actions/workflows/ci.yml)

Parse date and time strings in Crystal. Give `DateParse.parse` a string in any common format, and it returns a `Time`.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  dateparse:
    github: thomas-fazzari/dateparse.cr
```

Run `shards install`.

## Usage

```crystal
require "dateparse"
```

`parse` returns `Time?` (`nil` when no format matches):

```crystal
DateParse.parse("Mon, 02 Jan 2006 15:04:05 +0000")
# => 2006-01-02 15:04:05 UTC

DateParse.parse("2006-01-02T15:04:05Z")
# => 2006-01-02 15:04:05 UTC

DateParse.parse("not a date")
# => nil
```

`parse!` returns `Time` or raises `DateParse::Error`:

```crystal
DateParse.parse!("2006-01-02T15:04:05Z")
# => 2006-01-02 15:04:05 UTC

DateParse.parse!("not a date")
# raises DateParse::Error
```

## Supported Formats

| Format          | Example                                                |
| --------------- | ------------------------------------------------------ |
| RFC 3339        | `2006-01-02T15:04:05Z`, `2006-01-02T15:04:05+07:00`    |
| RFC 2822        | `Mon, 02 Jan 2006 15:04:05 +0000`                      |
| RFC 822         | `02 Jan 06 15:04 +0000`                                |
| ISO 8601        | `2006-01-02T15:04:05+0700`                             |
| SQL             | `2006-01-02 15:04:05 +0000`, `2006-01-02 15:04:05`     |
| HTTP (RFC 7231) | `Sat, 21 Mar 2026 00:00:00 GMT`                        |
| RFC 850         | `Saturday, 21-Mar-26 00:00:00 GMT`                     |
| asctime         | `Sat Mar 21 00:00:00 2026`                             |
| Date only       | `2006-01-02`, `2006-01`, `2006`                        |
| Month + year    | `January 2006`, `Jan 2006`                             |
| Unix timestamp  | `1136214245` (seconds), `1136214245000` (milliseconds) |

The parser recognizes timezone abbreviations EST, EDT, CST, CDT, MST, MDT, PST, PDT, GMT, and UT, and normalizes colon offsets like `+01:00` automatically.

## License

[MIT](LICENSE)
