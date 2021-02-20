defmodule HttpStructuredField do
  @moduledoc """
  Top level API to parse and serialize data.
  """

  @doc """
  Parse field data.

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
      {:ok, {:list, [{:token, "foo"}, {:token, "bar"}]}}
  """
  @spec parse(binary()) :: {:ok, term()} | {:error, term()}
  defdelegate parse(value), to: HttpStructuredField.Parser
end
