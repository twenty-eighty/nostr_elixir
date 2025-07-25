defmodule NostrElixir.Nip19 do
  @moduledoc """
  NIP-19 encoding and decoding functions for NostrElixir.

  ## Examples

      iex> alias NostrElixir.Nip19
      iex> npub = Nip19.encode("npub", "eec7...619")
      iex> Nip19.decode_map(npub)
      %{data_type: "npub", data: _}
  """

  @type bech32 :: String.t()
  @type hex :: String.t()
  @type nip19_result :: %{data_type: String.t(), data: String.t()}

  defdelegate nip19_encode_nif(type, data), to: NostrElixir
  defdelegate nip19_decode_nif(bech32_string), to: NostrElixir

  @doc "Encode data to bech32 format (npub, nsec, note)."
  @spec encode(String.t(), String.t()) :: bech32
  def encode(type, data) do
    case nip19_encode_nif(type, data) do
      {:error, reason} -> raise ArgumentError, "Failed to encode NIP-19: #{reason}"
      result -> result
    end
  end

  @doc "Decode bech32 format to JSON string."
  @spec decode(bech32) :: String.t()
  def decode(bech32_string) do
    case nip19_decode_nif(bech32_string) do
      {:error, reason} -> raise ArgumentError, "Failed to decode NIP-19: #{reason}"
      result -> result
    end
  end

  @doc "Decode NIP-19 bech32 format and return as a map."
  @spec decode_map(bech32) :: nip19_result
  def decode_map(bech32_string) do
    result_json = decode(bech32_string)
    result = Jason.decode!(result_json)

    %{
      data_type: result["data_type"],
      data: result["data"]
    }
  end
end
