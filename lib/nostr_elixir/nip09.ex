defmodule NostrElixir.Nip09 do
  @moduledoc """
  NIP-09: Event Deletion

  This module provides helpers for creating event deletion events (kind 5) according to NIP-09.

  **Implementation note:**
  > Tag construction is implemented in pure Elixir for full NIP-09 spec compliance. This ensures correct and predictable behavior for event deletion tags.

  See: https://github.com/nostr-protocol/nips/blob/master/09.md

  ## Examples

      iex> keys = NostrElixir.Keys.generate_keypair()
      iex> event_ids = ["event_id_1", "event_id_2"]
      iex> reason = "Content was inappropriate"
      iex> event_json = NostrElixir.Nip09.create_deletion_event(keys, event_ids, reason)
      iex> NostrElixir.Event.verify(event_json)
      true
  """

  defmodule Deletion do
    @moduledoc """
    Struct representing a NIP-09 event deletion.
    """
    defstruct [:event_ids, :reason]
  end

  @doc """
  Create and sign an event deletion event (kind 5).

  ## Parameters

  - `keys` - keypair map or JSON
  - `event_ids` - list of event IDs to delete
  - `reason` - (optional) reason for deletion

  ## Examples
      iex> keys = NostrElixir.Keys.generate_keypair()
      iex> event_ids = ["abc123", "def456"]
      iex> event_json = NostrElixir.Nip09.create_deletion_event(keys, event_ids)
      iex> is_binary(event_json)
      true
  """
  def create_deletion_event(keys, event_ids, reason \\ nil) when is_list(event_ids) do
    tags = build_deletion_tags(event_ids)
    create_and_sign_event(keys, reason || "", 5, tags)
  end

  @doc """
  Extract deletion information from an event deletion event JSON.
  Returns a %Deletion{} struct with the extracted data.

  ## Examples
      iex> event_json = "{\"kind\": 5, \"content\": \"Inappropriate content\", \"tags\": [[\"e\", \"event_id_1\"], [\"e\", \"event_id_2\"]]}"
      iex> deletion = NostrElixir.Nip09.extract_deletion(event_json)
      iex> deletion.event_ids
      ["event_id_1", "event_id_2"]
      iex> deletion.reason
      "Inappropriate content"
  """
  def extract_deletion(event_json) when is_binary(event_json) do
    event = Jason.decode!(event_json)
    tags = event["tags"] || []

    event_ids = find_tag_values(tags, "e")

    %Deletion{
      event_ids: event_ids,
      reason: event["content"]
    }
  end

  @doc """
  Pretty-print an event deletion event (shows event IDs and reason).
  """
  def pretty_print(event_json) when is_binary(event_json) do
    deletion = extract_deletion(event_json)
    event = Jason.decode!(event_json)

    """
    🗑️  Event Deletion
    ─────────────────
    Deleted Events: #{length(deletion.event_ids)}
    #{Enum.map_join(deletion.event_ids, "\n", fn id -> "  • #{id}" end)}
    #{if deletion.reason && deletion.reason != "", do: "Reason: #{deletion.reason}", else: ""}

    Event ID: #{event["id"]}
    Author: #{event["pubkey"]}
    """
  end

  @doc """
  Build NIP-09 deletion tags from a list of event IDs.
  """
  def build_deletion_tags(event_ids) when is_list(event_ids) do
    Enum.map(event_ids, fn event_id -> ["e", event_id] end)
  end

  defp create_and_sign_event(keys, content, kind, tags) do
    tags_json = Jason.encode!(tags)
    pubkey = if is_map(keys), do: keys.public_key, else: Jason.decode!(keys)["public_key"]
    event_json = NostrElixir.event_new_nif(pubkey, content, kind, tags_json)
    secret_key = if is_map(keys), do: keys.secret_key, else: Jason.decode!(keys)["secret_key"]
    NostrElixir.event_sign_nif(event_json, secret_key)
  end

  defp find_tag_values(tags, tag_name) do
    tags
    |> Enum.filter(fn tag -> List.first(tag) == tag_name end)
    |> Enum.map(fn tag -> Enum.at(tag, 1) end)
  end
end
