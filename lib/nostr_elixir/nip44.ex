defmodule NostrElixir.Nip44 do
  @moduledoc """
  NIP-44: Encrypted DMs v2 (ChaCha20, HKDF, HMAC, base64)

  This module provides functions to encrypt and decrypt messages using NIP-44 (v2).

  ## Examples

      iex> alias NostrElixir.Nip44
      iex> sk = "...hex secret key..."
      iex> pk = "...hex public key..."
      iex> ciphertext = Nip44.encrypt(sk, pk, "hello!")
      iex> is_binary(ciphertext)
      true
      iex> Nip44.decrypt(sk, pk, ciphertext)
      "hello!"

  """

  @doc """
  Encrypt a message using NIP-44 (v2).

  ## Parameters
    * `secret_key` - hex string of sender's secret key
    * `public_key` - hex string of recipient's public key
    * `content` - plaintext message

  ## Returns
    * base64-encoded ciphertext (string)
  """
  def encrypt(secret_key, public_key, content) do
    case NostrElixir.nip44_encrypt_nif(secret_key, public_key, content) do
      {:error, reason} -> raise ArgumentError, "NIP-44 encrypt failed: #{reason}"
      result -> result
    end
  end

  @doc """
  Decrypt a NIP-44 (v2) message.

  ## Parameters
    * `secret_key` - hex string of recipient's secret key
    * `public_key` - hex string of sender's public key
    * `payload` - base64-encoded ciphertext

  ## Returns
    * plaintext message (string)
  """
  def decrypt(secret_key, public_key, payload) do
    case NostrElixir.nip44_decrypt_nif(secret_key, public_key, payload) do
      {:error, reason} -> raise ArgumentError, "NIP-44 decrypt failed: #{reason}"
      result -> result
    end
  end
end
