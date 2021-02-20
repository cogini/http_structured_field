# http_structured_field

Elixir library to parse and generate RFC 8941 Structured Field Values for HTTP.

HTTP headers often need to carry complex structures such as lists of values.
[RFC 8941]((https://tools.ietf.org/html/rfc8941) specifies a standard format
for these fields independent of the RFCs that define the headers.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `http_structured_field` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:http_structured_field, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/http_structured_field](https://hexdocs.pm/http_structured_field).

