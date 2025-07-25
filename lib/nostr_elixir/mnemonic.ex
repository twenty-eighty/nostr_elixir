defmodule NostrElixir.Mnemonic do
  @moduledoc """
  BIP-39 Mnemonic utilities for Nostr (NIP-06 compatible).

  This module provides functions to generate, validate, and use BIP-39 mnemonics.
  It is the recommended entry point for mnemonic-related operations in Elixir.

  ## Examples

      iex> mnemonic = NostrElixir.Mnemonic.generate(12)
      %NostrElixir.Mnemonic{phrase: phrase} = mnemonic
      String.split(phrase) |> length() == 12

      iex> NostrElixir.Mnemonic.valid?(mnemonic)
      true

      iex> NostrElixir.Mnemonic.valid?(NostrElixir.Mnemonic.from_phrase("not a real mnemonic"))
      false

      iex> NostrElixir.Mnemonic.to_seed(mnemonic)
      <<_::512>>

      iex> NostrElixir.Mnemonic.to_seed(mnemonic, "passphrase") |> byte_size()
      64

  """

  defstruct [:phrase]

  @type t :: %__MODULE__{phrase: String.t()}

  @doc """
  Generate a new mnemonic with the given word count (12, 15, 18, 21, or 24).
  """
  def generate(word_count) when word_count in [12, 15, 18, 21, 24] do
    result = NostrElixir.nip06_generate_mnemonic_nif(word_count) |> Jason.decode!()
    %__MODULE__{phrase: result["phrase"]}
  end

  @doc """
  Create a mnemonic struct from a phrase string.
  """
  def from_phrase(phrase) when is_binary(phrase), do: %__MODULE__{phrase: phrase}

  @doc """
  Check if a mnemonic is valid.
  """
  def valid?(%__MODULE__{phrase: phrase}), do: NostrElixir.nip06_validate_mnemonic_nif(phrase)
  def valid?(phrase) when is_binary(phrase), do: NostrElixir.nip06_validate_mnemonic_nif(phrase)

  @doc """
  Convert a mnemonic to a binary seed. Optionally takes a passphrase.
  """
  def to_seed(mnemonic_or_phrase, passphrase \\ "")
  def to_seed(%__MODULE__{phrase: phrase}, passphrase), do: to_seed(phrase, passphrase)
  def to_seed(phrase, passphrase) when is_binary(phrase) do
    result = NostrElixir.nip06_mnemonic_to_seed_nif(phrase, passphrase) |> Jason.decode!()
    Base.decode16!(result["seed"], case: :lower)
  end
end
