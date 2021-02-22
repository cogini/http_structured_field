defmodule SecChUaTestt do
  @moduledoc """
  https://wicg.github.io/ua-client-hints/
  """
  use ExUnit.Case

  alias HttpStructuredField.Parser

  describe "Sec-CH-UA header" do
    test "RFC example" do
      assert {:ok, [
        {:string, "Examplary Browser", [{"v", {:string, "73"}}]},
        {:string, ";Not?A.Brand", [{"v", {:string, "27"}}]}
      ]} == Parser.parse(~S<"Examplary Browser"; v="73", ";Not?A.Brand"; v="27">)
    end

    test "Live examples" do
      assert {:ok, [
        {:string, "Google Chrome", [{"v", {:string, "87"}}]},
        {:string, " Not;A Brand", [{"v", {:string, "99"}}]},
        {:string, "Chromium", [{"v", {:string, "87"}}]}
      ]} == Parser.parse("\"Google Chrome\";v=\"87\", \" Not;A Brand\";v=\"99\", \"Chromium\";v=\"87\"")
      assert {:ok, [
        {:string, "Chromium", [{"v", {:string, "88"}}]},
        {:string, "Google Chrome", [{"v", {:string, "88"}}]},
        {:string, ";Not A Brand", [{"v", {:string, "99"}}]}
      ]} == Parser.parse("\"Chromium\";v=\"88\", \"Google Chrome\";v=\"88\", \";Not A Brand\";v=\"99\"")
    end
  end
end
