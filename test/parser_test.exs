defmodule ParserTest do
  use ExUnit.Case

  alias HttpStructuredField.Parser

  test "Parse integer" do
    # Examples from RFC
    assert {:ok, {:integer, 1}} == Parser.parse("1")
    assert {:ok, {:integer, 42}} == Parser.parse("42")
    assert {:ok, {:integer, 999_999_999_999_999}} == Parser.parse("999999999999999")
    assert {:ok, {:integer, 999_999_999_999_999}} == Parser.parse("9999999999999999")
    assert {:ok, {:integer, 2}} == Parser.parse("0002")
    assert {:ok, {:integer, -42}} == Parser.parse("-42")
    assert {:ok, {:integer, -999_999_999_999_999}} == Parser.parse("-999999999999999")
    assert {:ok, {:integer, -1}} == Parser.parse("-01")
    assert {:ok, {:integer, 0}} == Parser.parse("-0")
  end

  describe "Parse decimal" do
    test "Parse decimal" do
      # Examples from RFC
      assert {:ok, {:decimal, 4.5}} == Parser.parse("4.5")
    end

    test "Parse decimal with leading and trailing zeros" do
      # Examples from RFC
      assert {:ok, {:decimal, 2.5}} == Parser.parse("0002.5")
      assert {:ok, {:decimal, -1.334}} == Parser.parse("-01.334")
      assert {:ok, {:decimal, 5.23}} == Parser.parse("5.230")
      assert {:ok, {:decimal, 0}} == Parser.parse("-0.0")

      # Note that the serialization algorithm (Section 4.1.5) rounds input
      # with more than three digits of precision in the fractional component.
      # If an alternative rounding strategy is desired, this should be
      # specified by the header definition to occur before serialization.
    end
  end

  describe "Parse boolean" do
    test "Parse boolean" do
      assert {:ok, {:boolean, true}} == Parser.parse("?1")
      assert {:ok, {:boolean, false}} == Parser.parse("?0")
    end
  end

  describe "Parse invalid" do
    test "Parse invalid" do
      assert {:ok, {:boolean, true}} == Parser.parse("fish")
    end
  end
end
