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
    assert {:ok, {:integer, 1, [{"a", {:boolean, true}}, {"b", {:boolean, false}}]}} == Parser.parse("1; a; b=?0")
    # Longer name
    assert {:ok, {:integer, 1, [{"abc", {:boolean, true}}, {"b", {:boolean, false}}]}} == Parser.parse("1; abc; b=?0")
  end

  test "inner list" do
    # From RFC
    assert {:ok, [
      {:inner_list, [string: "foo", string: "bar"]},
      {:inner_list, [string: "baz"]},
      {:inner_list, [string: "bat", string: "one"]},
      {:inner_list, []}
    ]} == Parser.parse(~S<("foo" "bar"), ("baz"), ("bat" "one"), ()>)

    assert {:ok, [
      {:inner_list, [{:string, "foo", [{"a", {:integer, 1}}, {"b", {:integer, 2}}]}], [{"lvl", {:integer, 5}}]},
      {:inner_list, [string: "bar", string: "baz"], [{"lvl", {:integer, 1}}]}
    ]} == Parser.parse(~S<("foo"; a=1;b=2);lvl=5, ("bar" "baz");lvl=1>)

    assert {:ok, {:inner_list, []}} == Parser.parse(~S<()>)
  end

  test "list" do
    # From RFC
    assert {:ok, [{:token, "sugar"}, {:token, "tea"}, {:token, "rum"}]} == Parser.parse("sugar, tea, rum")
    assert {:ok, [
      {:token, "abc", [{"a", {:integer, 1}}, {"b", {:integer, 2}}, {"cde_456", {:boolean, true}}]},
      {:inner_list, [{:token, "ghi", [{"jk", {:integer, 4}}]}, {:token, "l"}], [{"q", {:string, "9"}}, {"r", {:token, "w"}}]}
    ]} == Parser.parse(~S<abc;a=1;b=2; cde_456, (ghi;jk=4 l);q="9";r=w>)
  end

  test "dictionary" do
    # From RFC
    assert {:ok, [
      {"en", {:string, "Applepie"}},
      {"da", {:binary, "Æbletærte"}}
    ]} == Parser.parse(~S<en="Applepie", da=:w4ZibGV0w6ZydGU=:>, type: :dict)

    assert {:ok, [
      {"a", {:boolean, false}},
      {"b", {:boolean, true}},
      {"c", {:boolean, true}, [{"foo", {:token, "bar"}}, {"biz", {:token, "baz"}}]}
    ]} == Parser.parse(~S<a=?0, b, c; foo=bar; biz=baz>, type: :dict)

    assert {:ok, [
      {"a", {:boolean, false}},
      {"b", {:boolean, true}},
      {"c", {:boolean, true}, [{"foo", {:token, "bar"}}]}
    ]} == Parser.parse(~S<a=?0, b, c; foo=bar>, type: :dict)

    assert {:ok, [
      {"rating", {:decimal, 1.5}},
      {"feelings", {:inner_list, [token: "joy", token: "sadness"]}}
    ]} == Parser.parse(~S<rating=1.5, feelings=(joy sadness)>, type: :dict)

    assert {:ok, [
      {"a", {:inner_list, [integer: 1, integer: 2]}},
      {"b", {:integer, 3}},
      {"c", {:integer, 4, [{"aa", {:token, "bb"}}]}},
      {"d", {:inner_list, [integer: 5, integer: 6], [{"valid", {:boolean, true}}]}}
    ]} == Parser.parse(~S<a=(1 2), b=3, c=4;aa=bb, d=(5 6);valid>, type: :dict)
  end

  test "empty input" do
    assert {:ok, []} == Parser.parse("")
  end

end
