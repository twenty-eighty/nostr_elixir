defmodule NostrElixir.Event do
  @moduledoc """
  Event creation, signing, verification, and helpers for NostrElixir.

  ## Examples

      iex> alias NostrElixir.{Keys, Event}
      iex> keys = Keys.generate_keypair()
      iex> event_json = Event.new(keys.public_key, "Hello, Nostr!", 1, [])
      iex> signed_event_json = Event.sign(event_json, keys.secret_key)
      iex> Event.verify(signed_event_json)
      true
  """

  @type event_json :: String.t()
  @type pubkey :: String.t()
  @type secret_key :: String.t()
  @type tags :: list(list(String.t()))
  @type content :: String.t()

  defdelegate event_new_nif(pubkey, content, kind, tags_json), to: NostrElixir
  defdelegate event_sign_nif(event_json, secret_key), to: NostrElixir
  defdelegate event_verify_nif(event_json), to: NostrElixir
  defdelegate event_to_json_nif(event_json), to: NostrElixir
  defdelegate event_from_json_nif(json_string), to: NostrElixir

  @doc "Create a new unsigned event (JSON string)."
  @spec new(pubkey, content, integer, tags) :: event_json
  def new(pubkey, content, kind, tags) do
    case event_new_nif(pubkey, content, kind, Jason.encode!(tags)) do
      {:error, reason} -> raise ArgumentError, "Failed to create event: #{reason}"
      result -> result
    end
  end

  @doc "Sign an event (JSON string) with a secret key."
  @spec sign(event_json, secret_key) :: event_json
  def sign(event_json, secret_key) do
    case event_sign_nif(event_json, secret_key) do
      {:error, reason} -> raise ArgumentError, "Failed to sign event: #{reason}"
      result -> result
    end
  end

  @doc "Verify an event's signature."
  @spec verify(event_json) :: boolean
  def verify(event_json) do
    case event_verify_nif(event_json) do
      {:error, reason} -> raise ArgumentError, "Failed to verify event: #{reason}"
      result -> result
    end
  end

  @doc "Return the event as JSON (identity function)."
  @spec to_json(event_json) :: event_json
  def to_json(event_json), do: event_to_json_nif(event_json)

  @doc "Parse event from JSON (validates required fields)."
  @spec from_json(event_json) :: event_json
  def from_json(json_string), do: event_from_json_nif(json_string)

  @doc "Create and sign a text note event."
  @spec create_text_note(map | String.t(), content) :: event_json
  def create_text_note(keys, content) do
    keys_json =
      if is_map(keys) do
        Jason.encode!(%{
          "public_key" => keys.public_key,
          "secret_key" => keys.secret_key
        })
      else
        keys
      end

    keys_map = Jason.decode!(keys_json)
    event_json = new(keys_map["public_key"], content, 1, [])
    sign(event_json, keys_map["secret_key"])
  end

  @doc "Create and sign a metadata event."
  @spec create_metadata(map | String.t(), map) :: event_json
  def create_metadata(keys, metadata) do
    keys_json =
      if is_map(keys) do
        Jason.encode!(%{
          "public_key" => keys.public_key,
          "secret_key" => keys.secret_key
        })
      else
        keys
      end

    keys_map = Jason.decode!(keys_json)
    content = Jason.encode!(metadata)
    event_json = new(keys_map["public_key"], content, 0, [])
    sign(event_json, keys_map["secret_key"])
  end
end
