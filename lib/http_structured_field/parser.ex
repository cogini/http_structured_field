defmodule HttpStructuredField.Parser do
  @moduledoc """
  Parse structured fields.
  """
  import NimbleParsec

  # sign =
  #   ascii_char([?-])

  # basic_integer =
  #   integer(min: 1, max: 15)

  # # post_traverse function
  # defp apply_sign(_rest, [value, ?-], context, _line, _offset) do
  #   {[-value], context}
  # end
  # defp apply_sign(_rest, acc, context, _line, _offset) do
  #   {acc, context}
  # end

  defp parse_integer(_rest, acc, context, _line, _offset) do
    case Integer.parse(to_string(Enum.reverse(acc))) do
      {value, ""} ->
        {[value], context}

      :error ->
        {:error, "Invalid integer"}
    end
  end

  defp parse_decimal(_rest, acc, context, _line, _offset) do
    case Float.parse(to_string(Enum.reverse(acc))) do
      {value, ""} ->
        {[value], context}

      :error ->
        {:error, "Invalid decimal"}
    end
  end

  # decimal =
  #   optional(ascii_char([?-]))
  #   ascii_string([?0..?9], min: 1, max: 12)
  #   optional(ascii_string([?., ?0..?9], min: 1, max: 3))

  # sf-integer = ["-"] 1*15DIGIT
  sf_integer =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1, max: 15)
    |> label("integer")
    # |> concat(basic_integer) |> label("integer")
    |> post_traverse(:parse_integer)
    |> unwrap_and_tag(:integer)

  # sf-decimal  = ["-"] 1*12DIGIT "." 1*3DIGIT
  sf_decimal =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1, max: 12)
    |> ascii_char([?.])
    |> ascii_string([?0..?9], min: 1, max: 3)
    |> label("decimal")
    |> post_traverse(:parse_decimal)
    |> unwrap_and_tag(:decimal)

  # ?
  sf_boolean =
    ignore(ascii_char([63]))
    |> choice([
      ascii_char([?0]) |> replace(false),
      ascii_char([?1]) |> replace(true)
    ])
    |> label("boolean")
    |> unwrap_and_tag(:boolean)

  # sf-item   = bare-item parameters
  # bare-item = sf-integer / sf-decimal / sf-string / sf-token
  #              / sf-binary / sf-boolean
  sf_item = choice([sf_boolean, sf_decimal, sf_integer])

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
