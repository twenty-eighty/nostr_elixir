defmodule NostrElixir.Nip06 do
  @moduledoc """
  NIP-06: HD Wallet Derivation for Nostr

  This module provides functions for deriving keys from BIP-39 mnemonics and seeds as specified in NIP-06.
  For mnemonic generation, validation, and seed conversion, use `NostrElixir.Mnemonic`.

  ## Examples

      iex> mnemonic = NostrElixir.Mnemonic.generate(12)
      iex> seed = NostrElixir.Mnemonic.to_seed(mnemonic)
      iex> NostrElixir.Nip06.derive_key(Base.encode16(seed, case: :lower), "m/44'/1237'/0'/0/0")
      %{"public_key" => _pub, "secret_key" => _sec, "derivation_path" => "m/44'/1237'/0'/0/0"}

  """

  @doc """
  Derives a key from a seed (hex string) and derivation path.

  ## Parameters
    * `seed_hex` - The seed as a hex string (use `Base.encode16(seed, case: :lower)`)
    * `derivation_path` - The BIP-32/44 derivation path (e.g., "m/44'/1237'/0'/0/0")

  ## Returns
    * `%{"public_key" => pub, "secret_key" => sec, "derivation_path" => path}`
  """
  def derive_key(seed_hex, derivation_path) do
    NostrElixir.nip06_derive_key_nif(seed_hex, derivation_path)
    |> Jason.decode!()
  end
end
