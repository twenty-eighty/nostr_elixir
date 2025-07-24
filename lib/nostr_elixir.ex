defmodule NostrElixir do
  @moduledoc """
  Elixir wrapper for the nostr Rust library.

  This module provides a clean Elixir interface to the nostr protocol implementation,
  including key management, text parsing, and NIP-19 encoding/decoding.
  """

  # Rust NIF functions
  use Rustler, otp_app: :nostr_elixir, crate: :nostr_nif

  # NIF function stubs (these are replaced by Rustler at runtime)
  def keys_generate_nif, do: :erlang.nif_error(:nif_not_loaded)
  def keys_parse_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def keys_public_key_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def keys_secret_key_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def keys_public_key_bech32_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def keys_secret_key_bech32_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def keys_secret_key_hex_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def parser_parse_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def nip19_encode_nif(_, _), do: :erlang.nif_error(:nif_not_loaded)
  def nip19_decode_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def event_new_nif(_, _, _, _), do: :erlang.nif_error(:nif_not_loaded)
  def event_sign_nif(_, _), do: :erlang.nif_error(:nif_not_loaded)
  def event_verify_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def event_to_json_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def event_from_json_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def filter_new_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def filter_to_json_nif(_), do: :erlang.nif_error(:nif_not_loaded)
  def filter_from_json_nif(_), do: :erlang.nif_error(:nif_not_loaded)

  # Wrapper functions
  def generate_keys, do: keys_generate_nif()
  def parse_keys(secret_key), do: keys_parse_nif(secret_key)
  def get_public_key(keys_json), do: keys_public_key_nif(keys_json)
  def get_secret_key(keys_json), do: keys_secret_key_nif(keys_json)

  def public_key_to_bech32(public_key) do
    case keys_public_key_bech32_nif(public_key) do
      {:error, reason} -> raise ArgumentError, "Failed to convert public key to bech32: #{reason}"
      result -> result
    end
  end

  def secret_key_to_bech32(secret_key) do
    case keys_secret_key_bech32_nif(secret_key) do
      {:error, reason} -> raise ArgumentError, "Failed to convert secret key to bech32: #{reason}"
      result -> result
    end
  end

  def secret_key_to_hex(secret_key) do
    case keys_secret_key_hex_nif(secret_key) do
      {:error, reason} -> raise ArgumentError, "Failed to convert secret key to hex: #{reason}"
      result -> result
    end
  end

  def parse_text(text), do: parser_parse_nif(text)

  def nip19_encode(type, data) do
    case nip19_encode_nif(type, data) do
      {:error, reason} -> raise ArgumentError, "Failed to encode NIP-19: #{reason}"
      result -> result
    end
  end

  def nip19_decode(bech32_string) do
    case nip19_decode_nif(bech32_string) do
      {:error, reason} -> raise ArgumentError, "Failed to decode NIP-19: #{reason}"
      result -> result
    end
  end

  # Event functions
  def new_event(pubkey, content, kind, tags) do
    case event_new_nif(pubkey, content, kind, Jason.encode!(tags)) do
      {:error, reason} -> raise ArgumentError, "Failed to create event: #{reason}"
      result -> result
    end
  end

  def sign_event(event_json, secret_key) do
    case event_sign_nif(event_json, secret_key) do
      {:error, reason} -> raise ArgumentError, "Failed to sign event: #{reason}"
      result -> result
    end
  end

  def verify_event(event_json) do
    case event_verify_nif(event_json) do
      {:error, reason} -> raise ArgumentError, "Failed to verify event: #{reason}"
      result -> result
    end
  end

  def event_to_json(event_json), do: event_to_json_nif(event_json)
  def event_from_json(json_string), do: event_from_json_nif(json_string)

  # Filter functions
  def new_filter(filter_spec) do
    case filter_new_nif(Jason.encode!(filter_spec)) do
      {:error, reason} -> raise ArgumentError, "Failed to create filter: #{reason}"
      result -> result
    end
  end

  def filter_to_json(filter_json), do: filter_to_json_nif(filter_json)
  def filter_from_json(json_string), do: filter_from_json_nif(json_string)

  # Convenience functions for events
  @doc """
  Create a text note event.

  ## Examples

      iex> keys = NostrElixir.generate_keypair()
      iex> event_json = NostrElixir.new_event(keys.public_key, "Hello, Nostr!", 1, [])
      iex> event = Jason.decode!(event_json)
      iex> event["content"]
      "Hello, Nostr!"
      iex> event["kind"]
      1

  """
  def create_text_note(keys, content) do
    keys_json = if is_map(keys) do
      Jason.encode!(%{
        "public_key" => keys.public_key,
        "secret_key" => keys.secret_key
      })
    else
      keys
    end

    keys_map = Jason.decode!(keys_json)
    event_json = new_event(keys_map["public_key"], content, 1, [])
    sign_event(event_json, keys_map["secret_key"])
  end

  @doc """
  Create a metadata event.

  ## Examples

      iex> keys = NostrElixir.generate_keypair()
      iex> metadata = %{name: "Alice", about: "Nostr user"}
      iex> content = Jason.encode!(metadata)
      iex> event_json = NostrElixir.new_event(keys.public_key, content, 0, [])
      iex> event = Jason.decode!(event_json)
      iex> event["kind"]
      0
      iex> content = Jason.decode!(event["content"])
      iex> content["name"]
      "Alice"

  """
  def create_metadata(keys, metadata) do
    keys_json = if is_map(keys) do
      Jason.encode!(%{
        "public_key" => keys.public_key,
        "secret_key" => keys.secret_key
      })
    else
      keys
    end

    keys_map = Jason.decode!(keys_json)
    content = Jason.encode!(metadata)
    event_json = new_event(keys_map["public_key"], content, 0, [])
    sign_event(event_json, keys_map["secret_key"])
  end

  @doc """
  Create a filter for following a user.

  ## Examples

      iex> filter_json = NostrElixir.follow_user("eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619")
      iex> filter = Jason.decode!(filter_json)
      iex> filter["authors"]
      ["eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"]
      iex> filter["kinds"]
      [1]

  """
  def follow_user(pubkey) do
    new_filter(%{
      authors: [pubkey],
      kinds: [1],
      limit: 100
    })
  end

  @doc """
  Create a filter for getting user metadata.

  ## Examples

      iex> filter_json = NostrElixir.get_user_metadata("eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619")
      iex> filter = Jason.decode!(filter_json)
      iex> filter["authors"]
      ["eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"]
      iex> filter["kinds"]
      [0]

  """
  def get_user_metadata(pubkey) do
    new_filter(%{
      authors: [pubkey],
      kinds: [0]
    })
  end

  @doc """
  Create a filter for hashtag search.

  ## Examples

      iex> filter_json = NostrElixir.search_hashtag("nostr")
      iex> filter = Jason.decode!(filter_json)
      iex> filter["kinds"]
      [1]
      iex> filter["limit"]
      50

  """
  def search_hashtag(hashtag) do
    new_filter(%{
      hashtags: [hashtag],
      kinds: [1],
      limit: 50
    })
  end

  @doc """
  Create a filter for recent events.

  ## Examples

      iex> filter_json = NostrElixir.recent_events()
      iex> filter = Jason.decode!(filter_json)
      iex> filter["kinds"]
      [1]
      iex> filter["limit"]
      20

  """
  def recent_events do
    new_filter(%{
      kinds: [1],
      limit: 20
    })
  end

  # Convenience functions that wrap the NIF functions

  @doc """
  Generate a new keypair and return it in a convenient format.

  Returns a map with both hex and bech32 representations.

  ## Examples

      iex> keys = NostrElixir.generate_keypair()
      iex> keys.npub
      iex> keys.nsec
      iex> keys.public_key
      iex> keys.secret_key

  """
  def generate_keypair do
    keys_json = generate_keys()
    keys = Jason.decode!(keys_json)
    %{
      public_key: keys["public_key"],
      secret_key: keys["secret_key"],
      npub: public_key_to_bech32(keys["public_key"]),
      nsec: secret_key_to_bech32(keys["secret_key"])
    }
  end

  @doc """
  Parse a secret key and return it in a convenient format.

  ## Examples

      iex> keys = NostrElixir.parse_keypair("nsec1j4c6269y9w0q2er2xjw8sv2ehyrtfxq3jwgdlxj6qfn8z4gjsq5qfvfk99")
      iex> keys.npub
      iex> keys.nsec
      iex> keys.public_key
      iex> keys.secret_key

  """
  def parse_keypair(secret_key) do
    keys_json = parse_keys(secret_key)
    keys = Jason.decode!(keys_json)
    %{
      public_key: keys["public_key"],
      secret_key: keys["secret_key"],
      npub: public_key_to_bech32(keys["public_key"]),
      nsec: secret_key_to_bech32(keys["secret_key"])
    }
  end

  @doc """
  Parse text and return tokens as a list of maps.

  ## Examples

      iex> tokens = NostrElixir.parse_text_tokens("Hello #nostr https://example.com")
      iex> is_list(tokens)
      true
      iex> Enum.any?(tokens, fn token -> token.token_type == "hashtag" end)
      true

  """
  def parse_text_tokens(text) do
    tokens_json = parse_text(text)
    tokens = Jason.decode!(tokens_json)
    Enum.map(tokens, fn token ->
      %{
        token_type: token["token_type"],
        value: token["value"]
      }
    end)
  end

  @doc """
  Decode NIP-19 bech32 format and return as a map.

  ## Examples

      iex> test_pubkey = "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"
      iex> npub = NostrElixir.nip19_encode("npub", test_pubkey)
      iex> result = NostrElixir.nip19_decode_map(npub)
      iex> result.data_type
      "npub"
      iex> is_binary(result.data)
      true

  """
  def nip19_decode_map(bech32_string) do
    result_json = nip19_decode(bech32_string)
    result = Jason.decode!(result_json)
    %{
      data_type: result["data_type"],
      data: result["data"]
    }
  end
end
