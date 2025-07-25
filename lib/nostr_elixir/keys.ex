defmodule NostrElixir.Keys do
  @moduledoc """
  Key management functions for NostrElixir.

  ## Examples

      iex> alias NostrElixir.Keys
      iex> keys = Keys.generate_keypair()
      iex> Keys.public_key_to_bech32(keys.public_key)
      "npub..."
  """

  @type hex_key :: String.t()
  @type bech32_key :: String.t()
  @type keys_map :: %{
          public_key: String.t(),
          secret_key: String.t(),
          npub: String.t(),
          nsec: String.t()
        }

  defdelegate keys_generate_nif(), to: NostrElixir
  defdelegate keys_parse_nif(secret_key), to: NostrElixir
  defdelegate keys_public_key_nif(keys_json), to: NostrElixir
  defdelegate keys_secret_key_nif(keys_json), to: NostrElixir
  defdelegate keys_public_key_bech32_nif(public_key), to: NostrElixir
  defdelegate keys_secret_key_bech32_nif(secret_key), to: NostrElixir
  defdelegate keys_secret_key_hex_nif(secret_key), to: NostrElixir

  @doc "Generate a new keypair (JSON string)."
  @spec generate_keys() :: String.t()
  def generate_keys, do: keys_generate_nif()

  @doc "Parse a secret key (hex or bech32) to JSON string."
  @spec parse_keys(hex_key | bech32_key) :: String.t()
  def parse_keys(secret_key), do: keys_parse_nif(secret_key)

  @doc "Extract public key from keys JSON."
  @spec get_public_key(String.t()) :: String.t()
  def get_public_key(keys_json), do: keys_public_key_nif(keys_json)

  @doc "Extract secret key from keys JSON."
  @spec get_secret_key(String.t()) :: String.t()
  def get_secret_key(keys_json), do: keys_secret_key_nif(keys_json)

  @doc "Convert hex public key to bech32 npub."
  @spec public_key_to_bech32(hex_key) :: bech32_key
  def public_key_to_bech32(public_key) do
    case keys_public_key_bech32_nif(public_key) do
      {:error, reason} -> raise ArgumentError, "Failed to convert public key to bech32: #{reason}"
      result -> result
    end
  end

  @doc "Convert hex secret key to bech32 nsec."
  @spec secret_key_to_bech32(hex_key) :: bech32_key
  def secret_key_to_bech32(secret_key) do
    case keys_secret_key_bech32_nif(secret_key) do
      {:error, reason} -> raise ArgumentError, "Failed to convert secret key to bech32: #{reason}"
      result -> result
    end
  end

  @doc "Convert bech32 secret key to hex."
  @spec secret_key_to_hex(bech32_key) :: hex_key
  def secret_key_to_hex(secret_key) do
    case keys_secret_key_hex_nif(secret_key) do
      {:error, reason} -> raise ArgumentError, "Failed to convert secret key to hex: #{reason}"
      result -> result
    end
  end

  @doc "Generate a new keypair and return it in a convenient map format."
  @spec generate_keypair() :: keys_map
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

  @doc "Parse a secret key and return it in a convenient map format."
  @spec parse_keypair(hex_key | bech32_key) :: keys_map
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
end
