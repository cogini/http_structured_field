defmodule HttpStructuredField do
  @moduledoc """
  Top level API to parse and serialize data.
  """

  @type item() :: {:integer, integer()} | {:decimal, float(), []}
  | {:boolean, bool()} | {:boolean, bool(), []}
  | {:string, binary()} | {:string, binary(), []}
  | {:token, binary()} | {:token, binary(), []}
  | {:binary, binary()} | {:binary, binary(), []}
  | list()

  @doc """
  Parse Structured Field datadata.

  By default, expects a list

  ## Examples

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
  """
  @spec parse(binary(), Keyword.t()) :: {:ok, item()} | {:error, term()}
  defdelegate parse(value, opts \\ []), to: HttpStructuredField.Parser
end
