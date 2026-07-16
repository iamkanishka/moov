defmodule Moov.CaseConverter do
  @moduledoc """
  Converts map keys between the `snake_case` Elixir developers expect and the
  `camelCase` JSON Moov's API speaks.

  `Moov.Client` automatically applies `to_camel_case/1` to every outgoing
  request body, so you can write idiomatic Elixir:

      Moov.Accounts.create(client, %{
        account_type: "business",
        profile: %{business: %{legal_business_name: "Whole Body Fitness LLC"}}
      })

  and it is sent to Moov as:

      {"accountType":"business","profile":{"business":{"legalBusinessName":"Whole Body Fitness LLC"}}}

  Response bodies are returned with their keys untouched (camelCase strings,
  exactly as Moov sent them) to avoid surprising key collisions and to keep
  forward-compatibility with fields Moov adds in the future. Call
  `to_snake_case/1` yourself if you'd like snake_case string keys on the way
  out, too.

  Both functions:

    * recurse into nested maps and lists
    * leave struct values (`DateTime`, `Date`, etc.) untouched, so they keep
      being encoded by their own `Jason.Encoder` implementation
    * leave atom, number, boolean, nil, and binary leaf values untouched
    * only rewrite keys that are atoms or binaries - anything else (e.g. an
      integer key in a hand-built map) is left as-is
  """

  @doc """
  Deeply converts `snake_case`/`camelCase`-mixed map keys to `camelCase`
  strings, recursing into nested maps and lists. Struct values are passed
  through untouched.

  Keys may be given as atoms or strings; the result always uses string keys
  (matching how Moov's JSON API + `Jason` work).

  ## Examples

      iex> Moov.CaseConverter.to_camel_case(%{legal_business_name: "Acme", address: %{postal_code: "80301"}})
      %{"legalBusinessName" => "Acme", "address" => %{"postalCode" => "80301"}}

      iex> Moov.CaseConverter.to_camel_case([%{first_name: "Ada"}])
      [%{"firstName" => "Ada"}]
  """
  @spec to_camel_case(term()) :: term()
  def to_camel_case(value) when is_struct(value), do: value

  def to_camel_case(%{} = map) do
    Map.new(map, fn {key, value} -> {camelize_key(key), to_camel_case(value)} end)
  end

  def to_camel_case(list) when is_list(list), do: Enum.map(list, &to_camel_case/1)
  def to_camel_case(value), do: value

  @doc """
  The inverse of `to_camel_case/1`: deeply converts `camelCase` map keys to
  `snake_case` strings. Keys remain binaries (never atoms) so this is safe to
  run against untrusted, server-controlled response data without growing the
  atom table.

  ## Examples

      iex> Moov.CaseConverter.to_snake_case(%{"accountID" => "abc", "displayName" => "Ada"})
      %{"account_id" => "abc", "display_name" => "Ada"}
  """
  @spec to_snake_case(term()) :: term()
  def to_snake_case(value) when is_struct(value), do: value

  def to_snake_case(%{} = map) do
    Map.new(map, fn {key, value} -> {underscore_key(key), to_snake_case(value)} end)
  end

  def to_snake_case(list) when is_list(list), do: Enum.map(list, &to_snake_case/1)
  def to_snake_case(value), do: value

  defp camelize_key(key) when is_atom(key), do: key |> Atom.to_string() |> camelize_string()
  defp camelize_key(key) when is_binary(key), do: camelize_string(key)
  defp camelize_key(key), do: key

  defp camelize_string(string) do
    case String.split(string, "_") do
      [single] ->
        single

      [first | rest] ->
        Enum.join([first | Enum.map(rest, &capitalize_segment/1)])
    end
  end

  defp capitalize_segment(""), do: ""

  defp capitalize_segment(segment) do
    {first, rest} = String.split_at(segment, 1)
    String.upcase(first) <> rest
  end

  defp underscore_key(key) when is_atom(key), do: key |> Atom.to_string() |> Macro.underscore()
  defp underscore_key(key) when is_binary(key), do: Macro.underscore(key)
  defp underscore_key(key), do: key
end
