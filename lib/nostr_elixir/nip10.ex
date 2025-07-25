defmodule NostrElixir.Nip10 do
  @moduledoc """
  NIP-10: Text Notes and Threads (Replies, Mentions)

  This module provides helpers for creating text note events (kind 1) and threaded replies according to NIP-10.

  **Implementation note:**
  > Tag construction is implemented in pure Elixir for full NIP-10 spec compliance. This is because the Rust `nostr` crate's tag logic is either not spec-compliant or is in flux (as observed in recent versions, where `"p"` tags are missing from replies). By building tags in Elixir, we ensure correct and predictable behavior, and make it easy to adapt to future spec changes.

  See: https://github.com/nostr-protocol/nips/blob/master/10.md

  ## Examples

      iex> keys = NostrElixir.Keys.generate_keypair()
      iex> event_json = NostrElixir.Nip10.create_text_note(keys, "Hello, Nostr!")
      iex> NostrElixir.Event.verify(event_json)
      true

      iex> reply_json = NostrElixir.Nip10.create_reply(keys, "Replying!", event_json)
      iex> NostrElixir.Event.verify(reply_json)
      true
  """

  defmodule TextNote do
    @moduledoc """
    Struct representing a NIP-10 text note or reply.
    """
    defstruct [:content, :tags]
  end

  @doc """
  Create and sign a text note event (kind 1).

  ## Examples
      iex> keys = NostrElixir.Keys.generate_keypair()
      iex> event_json = NostrElixir.Nip10.create_text_note(keys, "Hello!")
      iex> is_binary(event_json)
      true
  """
  def create_text_note(keys, content) do
    tags = []
    create_and_sign_event(keys, content, 1, tags)
  end

  @doc """
  Create and sign a text note reply event (kind 1) with proper NIP-10 tags.

  - `keys`: keypair map or JSON
  - `content`: reply text
  - `reply_to_event_json`: JSON of the event being replied to
  - `root_event_json`: (optional) JSON of the thread root event
  - `relay_url`: (optional) relay URL for tags

  ## Examples
      iex> keys = NostrElixir.Keys.generate_keypair()
      iex> root_json = NostrElixir.Nip10.create_text_note(keys, "Root post")
      iex> reply_json = NostrElixir.Nip10.create_reply(keys, "Reply!", root_json)
      iex> is_binary(reply_json)
      true
  """
  def create_reply(keys, content, reply_to_event_json, root_event_json \\ nil, relay_url \\ nil) do
    reply_to = Jason.decode!(reply_to_event_json)
    root = if root_event_json, do: Jason.decode!(root_event_json), else: nil
    tags = build_reply_tags(reply_to, root, relay_url)
    create_and_sign_event(keys, content, 1, tags)
  end

  defp create_and_sign_event(keys, content, kind, tags) do
    tags_json = Jason.encode!(tags)
    pubkey = if is_map(keys), do: keys.public_key, else: Jason.decode!(keys)["public_key"]
    event_json = NostrElixir.event_new_nif(pubkey, content, kind, tags_json)
    secret_key = if is_map(keys), do: keys.secret_key, else: Jason.decode!(keys)["secret_key"]
    NostrElixir.event_sign_nif(event_json, secret_key)
  end

  @doc """
  Build NIP-10 tags for a reply event, given the reply-to and (optional) root event.
  """
  def build_reply_tags(reply_to, root, relay_url) do
    relay = relay_url || ""
    tags =
      cond do
        root && root["id"] != reply_to["id"] ->
          [
            ["e", reply_to["id"], relay, "reply"],
            ["p", reply_to["pubkey"]],
            ["e", root["id"], relay, "root"],
            ["p", root["pubkey"]]
          ]
        true ->
          [
            ["e", reply_to["id"], relay, "reply"],
            ["p", reply_to["pubkey"]]
          ]
      end
    tags
  end

  @doc """
  Pretty-print a text note event JSON (shows content and tags).
  """
  def pretty_print(event_json) do
    event = Jason.decode!(event_json)
    IO.puts("Content: #{event["content"]}")
    IO.inspect(event["tags"], label: "Tags")
    event
  end
end
