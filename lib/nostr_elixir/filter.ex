defmodule NostrElixir.Filter do
  @moduledoc """
  Filter creation and helpers for NostrElixir.

  ## Examples

      iex> alias NostrElixir.Filter
      iex> filter_json = Filter.user_notes_filter("eec7...619")
      iex> filter = Jason.decode!(filter_json)
      iex> filter["authors"]
      ["eec7...619"]
  """

  @type filter_json :: String.t()
  @type filter_spec :: map

  defdelegate filter_new_nif(filter_spec), to: NostrElixir
  defdelegate filter_to_json_nif(filter_json), to: NostrElixir
  defdelegate filter_from_json_nif(json_string), to: NostrElixir

  @doc "Create a filter from a specification (JSON string)."
  @spec new(filter_spec) :: filter_json
  def new(filter_spec) do
    case filter_new_nif(Jason.encode!(filter_spec)) do
      {:error, reason} -> raise ArgumentError, "Failed to create filter: #{reason}"
      result -> result
    end
  end

  @doc "Convert filter to JSON (identity function)."
  @spec to_json(filter_json) :: filter_json
  def to_json(filter_json), do: filter_to_json_nif(filter_json)

  @doc "Parse filter from JSON (validates required fields)."
  @spec from_json(filter_json) :: filter_json
  def from_json(json_string), do: filter_from_json_nif(json_string)

  @doc "Create a filter for fetching text notes (kind 1) by a user."
  @spec user_notes_filter(String.t()) :: filter_json
  def user_notes_filter(pubkey) do
    new(%{
      authors: [pubkey],
      kinds: [1],
      limit: 100
    })
  end

  @doc "Create a filter for fetching a user's follow list (kind 3)."
  @spec user_follow_list_filter(String.t()) :: filter_json
  def user_follow_list_filter(pubkey) do
    new(%{
      authors: [pubkey],
      kinds: [3],
      limit: 1
    })
  end

  @doc "Create a filter for getting user metadata."
  @spec get_user_metadata(String.t()) :: filter_json
  def get_user_metadata(pubkey) do
    new(%{
      authors: [pubkey],
      kinds: [0]
    })
  end

  @doc "Create a filter for hashtag search."
  @spec search_hashtag(String.t()) :: filter_json
  def search_hashtag(hashtag) do
    new(%{
      hashtags: [hashtag],
      kinds: [1],
      limit: 50
    })
  end

  @doc "Create a filter for recent events."
  @spec recent_events() :: filter_json
  def recent_events do
    new(%{
      kinds: [1],
      limit: 20
    })
  end
end
