defmodule HttpStructuredField.Parser do
  @moduledoc """
  Parse structured fields.
  """
  import NimbleParsec

  # sf-integer = ["-"] 1*15DIGIT

  defp parse_integer(_rest, acc, context, _line, _offset) do
    case Integer.parse(to_string(Enum.reverse(acc))) do
      {value, ""} ->
        {[value], context}

      :error ->
        {:error, "Invalid integer"}
    end
  end

  sf_integer =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1, max: 15)
    |> label("integer")
    # |> concat(basic_integer) |> label("integer")
    |> post_traverse(:parse_integer)
    |> unwrap_and_tag(:integer)


  # sf-decimal  = ["-"] 1*12DIGIT "." 1*3DIGIT

  defp parse_decimal(_rest, acc, context, _line, _offset) do
    case Float.parse(to_string(Enum.reverse(acc))) do
      {value, ""} ->
        {[value], context}

      :error ->
        {:error, "Invalid decimal"}
    end
  end

  sf_decimal =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1, max: 12)
    |> ascii_char([?.])
    |> ascii_string([?0..?9], min: 1, max: 3)
    |> label("decimal")
    |> post_traverse(:parse_decimal)
    |> unwrap_and_tag(:decimal)


  sf_boolean =
    ignore(ascii_char([63])) # ?
    |> choice([
      ascii_char([?0]) |> replace(false),
      ascii_char([?1]) |> replace(true)
    ])
    |> label("boolean")
    |> unwrap_and_tag(:boolean)


  # sf-string = DQUOTE *chr DQUOTE
  # chr       = unescaped / escaped
  # unescaped = %x20-21 / %x23-5B / %x5D-7E
  # escaped   = "\" ( DQUOTE / "\" )

  defp parse_string(_rest, acc, context, _line, _offset) do
    {[IO.iodata_to_binary(Enum.reverse(acc))], context}
  end

  sf_string =
    ignore(ascii_char([?"]))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> choice([
        ~S(\") |> string() |> replace(?"),
        ~S(\\) |> string() |> replace(0x5c),
        utf8_string([0x20..0x21, 0x23..0x5b, 0x5d..0x7e], min: 1) # Printable ASCII
      ])
    )
    |> ignore(ascii_char([?"]))
    |> label("string")
    |> post_traverse(:parse_string)
    |> unwrap_and_tag(:string)


  # sf-item   = bare-item parameters
  # bare-item = sf-integer / sf-decimal / sf-string / sf-token
  #              / sf-binary / sf-boolean
  sf_item = choice([sf_boolean, sf_decimal, sf_integer, sf_string]) |> label("item")

  defparsec(:parsec_parse, sf_item)

  @spec parse(binary()) ::
          {:ok, {:integer, integer()} | {:decimal, float()} | {:boolean, bool()}}
          | {:error, term()}
  def parse(input) do
    case parsec_parse(input) do
      {:ok, [value], _, _, _, _} ->
        {:ok, value}

      {:error, reason, _, _, _, _} ->
        {:error, reason}
    end
  end
end
