defmodule NostrElixir.Nip17 do
  @moduledoc """
  NIP-17: Private Direct Messages (encrypted DMs, kind 4 events)

  ## Examples

      iex> alias NostrElixir.Nip17
      iex> secret_key = "..." # hex
      iex> public_key = "..." # hex
      iex> plaintext = "hello!"
      iex> ciphertext = Nip17.encrypt_dm(secret_key, public_key, plaintext)
      iex> decrypted = Nip17.decrypt_dm(secret_key, public_key, ciphertext)
      iex> decrypted == plaintext
      true
  """

  @doc """
  Encrypt a private direct message (NIP-17, kind 4 event).
  """
  def encrypt_dm(secret_key, public_key, plaintext) do
    case NostrElixir.nip17_encrypt_dm_nif(secret_key, public_key, plaintext) do
      {:error, reason} -> raise ArgumentError, "NIP-17 encrypt_dm failed: #{reason}"
      result -> result
    end
  end

  @doc """
  Decrypt a private direct message (NIP-17, kind 4 event).
  """
  def decrypt_dm(secret_key, public_key, ciphertext) do
    case NostrElixir.nip17_decrypt_dm_nif(secret_key, public_key, ciphertext) do
      {:error, reason} -> raise ArgumentError, "NIP-17 decrypt_dm failed: #{reason}"
      result -> result
    end
  end
end
