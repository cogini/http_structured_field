defmodule HttpStructuredField do
  @moduledoc """
  Top level API to parse and serialize data.
  """

  @doc """
  Parse field data.
  """
  @spec parse(binary()) :: {:ok, term()} | {:error, term()}
  defdelegate parse(value), to: HttpStructuredField.Parser
end
