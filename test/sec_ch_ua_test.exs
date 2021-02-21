defmodule SecChUaTestt do
  @moduledoc """
  https://wicg.github.io/ua-client-hints/
  """
  use ExUnit.Case

  alias HttpStructuredField.Parser

  test "Sec-CH-UA header" do
    assert {:ok, [
      {:string, "Examplary Browser", [{"v", {:string, "73"}}]},
      {:string, ";Not?A.Brand", [{"v", {:string, "27"}}]}
    ]} == Parser.parse(~S<"Examplary Browser"; v="73", ";Not?A.Brand"; v="27">)
  end
end
