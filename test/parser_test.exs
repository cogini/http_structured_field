defmodule ParserTest do
  use ExUnit.Case

  alias HttpStructuredField.Parser

  test "integer" do
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

  describe "decimal" do
    test "decimal" do
      # Examples from RFC
      assert {:ok, {:decimal, 4.5}} == Parser.parse("4.5")
    end

    test "Parse decimal with leading and trailing zeros" do
      # Examples from RFC
      assert {:ok, {:decimal, 2.5}} == Parser.parse("0002.5")
      assert {:ok, {:decimal, -1.334}} == Parser.parse("-01.334")
      assert {:ok, {:decimal, 5.23}} == Parser.parse("5.230")
      assert {:ok, {:decimal, 0}} == Parser.parse("-0.0")
    end
  end

  describe "boolean" do
    test "boolean" do
      assert {:ok, {:boolean, true}} == Parser.parse("?1")
      assert {:ok, {:boolean, false}} == Parser.parse("?0")
    end
  end

  describe "string" do
    test "string" do
      assert {:ok, {:string, "hi"}} == Parser.parse(~S("hi"))
      assert {:ok, {:string, "hello world"}} == Parser.parse(~S("hello world"))
      assert {:ok, {:string, ""}} == Parser.parse(~S(""))
    end

    test "string with escapes" do
      assert {:ok, {:string, "hi\"ho"}} == Parser.parse(~S("hi\"ho"))
      assert {:ok, {:string, "hi\\ho"}} == Parser.parse(~S("hi\\ho"))
    end
  end

  describe "token" do
    test "token" do
      assert {:ok, {:token, "foo123/456"}} == Parser.parse("foo123/456")
    end
  end

  describe "binary" do
    test "binary" do
      assert {:ok, {:binary, "pretend this is binary content."}} == Parser.parse(":cHJldGVuZCB0aGlzIGlzIGJpbmFyeSBjb250ZW50Lg==:")
      assert {:error, "Invalid base64"} == Parser.parse(":cHJldGVuZCB0aGlzIGlzIGJpbmFyeSBjb250ZW50Lg=:")
    end
  end

  test "parameters" do
    assert {:ok, {:integer, 1, [{"abc", {:boolean, true}}, {"b", {:boolean, false}}]}} == Parser.parse("1; abc; b=?0")
    assert {:ok, {:integer, 1, [{"a", {:boolean, true}}, {"b", {:boolean, false}}]}} == Parser.parse("1; a; b=?0")
  end

  test "list" do
    assert {:ok, {:list, [{:token, "foo"}, {:token, "bar"}]}} == Parser.parse("foo, bar")
  end

end
