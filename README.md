Elixir library to parse and generate RFC 8941 Structured Field Values for HTTP.

HTTP headers often need to carry complex structures such as lists of values.
[RFC 8941](https://tools.ietf.org/html/rfc8941) specifies a standard format
for these fields independent of the RFCs that define the headers.

## Usage

```elixir
iex> HttpStructuredField.parse("42")
{:ok, {:integer, 42}}

iex> HttpStructuredField.parse("4.5")
{:ok, {:decimal, 4.5}}

iex> HttpStructuredField.parse("?1")
{:ok, {:boolean, true}}

iex> HttpStructuredField.parse(~S("hello world"))
{:ok, {:string, "hello world"}}

iex> HttpStructuredField.parse("foo123/456")
{:ok, {:token, "foo123/456"}}

iex> HttpStructuredField.parse(":cHJldGVuZCB0aGlzIGlzIGJpbmFyeSBjb250ZW50Lg==:")
{:ok, {:binary, "pretend this is binary content."}}

iex> HttpStructuredField.parse("1; abc; b=?0")
{:ok, {:integer, 1, [{"abc", {:boolean, true}}, {"b", {:boolean, false}}]}}

iex> HttpStructuredField.parse("foo, bar")
{:ok, [{:token, "foo"}, {:token, "bar"}]}

iex> HttpStructuredField.parse("a=(1 2), b=3, c=4;aa=bb, d=(5 6);valid", type: :dict)
{:ok, [
  {"a", {:inner_list, [integer: 1, integer: 2]}},
  {"b", {:integer, 3}},
  {"c", {:integer, 4, [{"aa", {:token, "bb"}}]}},
  {"d", {:inner_list, [integer: 5, integer: 6], [{"valid", {:boolean, true}}]}}
]}
```

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

