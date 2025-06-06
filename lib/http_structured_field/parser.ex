defmodule HttpStructuredField.Parser do
  @moduledoc """
  Parse structured fields.
  """
  import NimbleParsec

  # sf-integer = ["-"] 1*15DIGIT

  # Convert charlist into integer
  defp process_integer(rest, acc, context, _line, _offset) do
    case Integer.parse(to_string(Enum.reverse(acc))) do
      {value, ""} ->
        {rest, [value], context}

      :error ->
        {:error, "Invalid integer"}
    end
  end

  sf_integer =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1, max: 15)
    |> label("integer")
    # |> concat(basic_integer) |> label("integer")
    |> post_traverse(:process_integer)
    |> unwrap_and_tag(:integer)

  # sf-decimal = ["-"] 1*12DIGIT "." 1*3DIGIT

  # Convert charlist into float
  defp process_decimal(rest, acc, context, _line, _offset) do
    case Float.parse(to_string(Enum.reverse(acc))) do
      {value, ""} ->
        {rest, [value], context}

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
    |> post_traverse(:process_decimal)
    |> unwrap_and_tag(:decimal)

  # ascii 63 = ?
  sf_boolean =
    ignore(ascii_char([63]))
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

  # Convert charlist to string
  defp process_string(rest, acc, context, _line, _offset) do
    {rest, [IO.iodata_to_binary(Enum.reverse(acc))], context}
  end

  sf_string =
    ignore(ascii_char([?"]))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> choice([
        ~S(\") |> string() |> replace(?"),
        ~S(\\) |> string() |> replace(0x5C),
        # Printable ASCII
        utf8_string([0x20..0x21, 0x23..0x5B, 0x5D..0x7E], min: 1)
      ])
    )
    |> ignore(ascii_char([?"]))
    |> label("string")
    |> post_traverse(:process_string)
    |> unwrap_and_tag(:string)

  # sf-token = ( ALPHA / "*" ) *( tchar / ":" / "/" )
  # tchar    = "!" / "#" / "$" / "%" / "&" / "'" / "*"
  #             / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
  #             / DIGIT / ALPHA
  #             ; any VCHAR, except delimiters
  # VCHAR    =  %x21-7E ; visible (printing) characters

  # ALPHA    =  %x41-5A / %x61-7A   ; A-Z / a-z
  alpha = ascii_char([0x41..0x5A, 0x61..0x7A]) |> label("ALPHA")

  # DIGIT    =  %x30-39 ; 0-9
  digit = ascii_char([0x30..0x39]) |> label("DIGIT")

  # tchar    = "!" / "#" / "$" / "%" / "&" / "'" / "*"
  #             / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
  #             / DIGIT / ALPHA
  tchar =
    choice([
      ascii_char([
        ?!,
        ?#,
        # $
        0x24,
        # %,
        0x25,
        # &
        0x26,
        # '
        0x27,
        # *
        0x2A,
        # +
        0x2B,
        # -
        0x2D,
        # .
        0x2E,
        # ^
        0x5E,
        # _
        0x5F,
        # `
        0x60,
        # |
        0x7C,
        # ~
        0x7E
      ]),
      digit,
      alpha
    ])
    |> label("tchar")

  sf_token =
    choice([alpha, ascii_char([?*])])
    |> optional(repeat(choice([tchar, ascii_char([?:, ?/])])))
    |> label("token")
    |> post_traverse(:process_string)
    |> unwrap_and_tag(:token)

  # sf-binary = ":" *(base64) ":"
  # base64    = ALPHA / DIGIT / "+" / "/" / "="

  base64 =
    choice([
      alpha,
      digit,
      ascii_char([
        # +
        0x2B,
        ?/,
        ?=
      ])
    ])
    |> label("base64")

  # Convert base64 to binary
  defp process_base64(rest, acc, context, _line, _offset) do
    value =
      acc
      |> Enum.reverse()
      |> IO.iodata_to_binary()

    case Base.decode64(value) do
      {:ok, binary} ->
        {rest, [binary], context}

      :error ->
        {:error, "Invalid base64"}
    end
  end

  sf_binary =
    ignore(ascii_char([?:]))
    |> repeat(lookahead_not(ascii_char([?:])) |> concat(base64))
    |> ignore(ascii_char([?:]))
    |> label("binary")
    |> post_traverse(:process_base64)
    |> unwrap_and_tag(:binary)

  # sf-item   = bare-item parameters
  # bare-item = sf-integer / sf-decimal / sf-string / sf-token /
  #             sf-binary / sf-boolean
  bare_item =
    choice([
      sf_token,
      sf_boolean,
      sf_binary,
      sf_string,
      sf_decimal,
      sf_integer
    ])
    |> label("bare-item")

  # parameters    = *( ";" *SP parameter )
  # parameter     = param-key [ "=" param-value ]
  # param-key     = key
  # key           = ( lcalpha / "*" )
  #                 *( lcalpha / DIGIT / "_" / "-" / "." / "*" )
  # lcalpha       = %x61-7A ; a-z
  # param-value   = bare-item

  lcalpha =
    ascii_char([?a..?z])
    |> label("lcalpha")

  key =
    choice([lcalpha, ascii_char([?*])])
    |> optional(
      repeat(
        choice([
          lcalpha,
          digit,
          ascii_char([
            # _
            0x5F,
            # -
            0x2D,
            # .
            0x2E,
            # *
            0x2A
          ])
        ])
      )
    )
    |> label("key")
    |> post_traverse(:process_string)

  param_value =
    bare_item
    |> label("param-value")

  # Space
  sp =
    ascii_char([0x20])
    |> label("SP")

  defp process_parameter(rest, [value], context, _line, _offset) do
    {rest, [{value, {:boolean, true}}], context}
  end

  defp process_parameter(rest, acc, context, _line, _offset) do
    value =
      acc
      |> Enum.reverse()
      |> List.to_tuple()

    {rest, [value], context}
  end

  parameter =
    ignore(ascii_char([?;]))
    |> ignore(optional(repeat(sp)))
    |> concat(key)
    |> optional(
      ignore(ascii_char([?=]))
      |> concat(param_value)
    )
    |> label("parameter")
    |> post_traverse(:process_parameter)

  parameters =
    repeat(parameter)
    |> label("parameters")

  # If there are parameters, make a 3-tuple like {tag, value, params}
  defp process_parameters(rest, [_value] = acc, context, _line, _offset) do
    {rest, acc, context}
  end

  defp process_parameters(rest, acc, context, _line, _offset) do
    case Enum.reverse(acc) do
      [{tag, value}, {:parameters, []}] ->
        {rest, [{tag, value}], context}

      [{tag, value}, {:parameters, params}] ->
        {rest, [{tag, value, params}], context}
    end
  end

  sf_item =
    bare_item
    |> optional(parameters |> tag(:parameters))
    |> label("sf-item")
    |> post_traverse(:process_parameters)

  # OWS  = *( SP / HTAB ) ; optional whitespace
  # HTAB =  %x09 ; horizontal tab

  ows =
    ascii_char([0x20, 0x09])
    |> label("OWS")

  # inner-list = "(" *SP [ sf-item *( 1*SP sf-item ) *SP ] ")" parameters

  inner_list =
    ignore(ascii_char([?(]))
    |> ignore(optional(repeat(sp)))
    |> optional(sf_item)
    |> optional(repeat(ignore(repeat(sp)) |> concat(sf_item)))
    |> ignore(optional(repeat(sp)))
    |> ignore(ascii_char([?)]))
    |> label("inner-list")
    |> tag(:inner_list)
    |> optional(parameters |> tag(:parameters))
    |> post_traverse(:process_parameters)

  list_member = choice([sf_item, inner_list])

  sf_list =
    list_member
    |> optional(
      repeat(
        ignore(optional(ows))
        |> ignore(ascii_char([?,]))
        |> ignore(optional(ows))
        |> concat(list_member)
      )
    )

  # sf-dictionary  = dict-member *( OWS "," OWS dict-member )
  # dict-member    = member-key ( parameters / ( "=" member-value ))
  # member-key     = key
  # member-value   = sf-item / inner-list

  # Simple boolean value
  defp process_dict_member(rest, [key], context, _line, _offset) do
    {rest, [{key, {:boolean, true}}], context}
  end

  defp process_dict_member(rest, acc, context, _line, _offset) do
    case Enum.reverse(acc) do
      # key is simple boolean, but with parameters
      [key, {:parameters, []}] ->
        {rest, [{key, {:boolean, true}}], context}

      [key, {:parameters, params}] ->
        {rest, [{key, {:boolean, true}, params}], context}

      #   {[{key, {:boolean, true, params}}], context}
      # key = inner-list
      [key, {:inner_list, value}] ->
        {rest, [{key, value}], context}

      # key = inner-list, where inner-list has params
      [key, {:inner_list, value, params}] ->
        {rest, [{key, value, params}], context}

      # key = item value
      [key, {tag, _value} = item] when is_atom(tag) ->
        {rest, [{key, item}], context}

      # key = item value, where item has params
      [key, {tag, _value, _params} = item] when is_atom(tag) ->
        {rest, [{key, item}], context}
    end
  end

  member_value =
    choice([sf_item, inner_list |> unwrap_and_tag(:inner_list)])
    |> label("member-value")

  dict_member =
    key
    |> choice([
      ignore(ascii_char([?=])) |> concat(member_value),
      parameters |> tag(:parameters)
    ])
    |> post_traverse(:process_dict_member)

  sf_dictionary =
    dict_member
    |> optional(
      repeat(
        ignore(optional(ows))
        |> ignore(ascii_char([?,]))
        |> ignore(optional(ows))
        |> concat(dict_member)
      )
    )

  defparsec(:parsec_parse_list, sf_list)
  defparsec(:parsec_parse_dict, sf_dictionary)

  @doc """
  Parse Structured Field.

  By default, assumes that input is a single Item or a List.
  For Dictionaries, set the `type: :dict` option.

  Returns a tagged tuple with the result or an error if parsing failed.  If the
  item has paramerters, then the tuple also contains a list of parameters.
  Parmeters and dictionary members are represented as lists of tuples where the
  name is the first tuple element.
  """
  @spec parse(binary(), Keyword.t()) ::
          {:ok, HttpStructuredField.item() | list()} | {:error, term()}
  def parse(input, opts \\ [])
  def parse("", _opts), do: {:ok, []}

  def parse(input, opts) do
    type = opts[:type] || :list

    result =
      case type do
        :list ->
          parsec_parse_list(input)

        :dict ->
          parsec_parse_dict(input)
      end

    case result do
      {:ok, [value], _, _, _, _} ->
        {:ok, value}

      {:ok, values, _, _, _, _} ->
        {:ok, values}

      {:error, reason, _, _, _, _} ->
        {:error, reason}
    end
  end
end
