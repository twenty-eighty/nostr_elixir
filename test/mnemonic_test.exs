defmodule NostrElixir.MnemonicTest do
  use ExUnit.Case, async: true
  alias NostrElixir.Mnemonic

  test "generate/1 returns a valid mnemonic struct and phrase" do
    for wc <- [12, 15, 18, 21, 24] do
      mnemonic = Mnemonic.generate(wc)
      assert %Mnemonic{phrase: phrase} = mnemonic
      assert String.split(phrase) |> length() == wc
    end
  end

  test "from_phrase/1 creates a struct" do
    phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    mnemonic = Mnemonic.from_phrase(phrase)
    assert %Mnemonic{phrase: ^phrase} = mnemonic
  end

  test "valid?/1 returns true for valid mnemonic" do
    phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    assert Mnemonic.valid?(phrase)
    assert Mnemonic.valid?(Mnemonic.from_phrase(phrase))
  end

  test "valid?/1 returns false for invalid mnemonic" do
    refute Mnemonic.valid?("not a real mnemonic")
    refute Mnemonic.valid?(Mnemonic.from_phrase("not a real mnemonic"))
  end

  test "to_seed/2 returns a 64-byte binary" do
    phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    mnemonic = Mnemonic.from_phrase(phrase)
    seed = Mnemonic.to_seed(mnemonic)
    assert is_binary(seed)
    assert byte_size(seed) == 64
  end

  test "to_seed/2 supports passphrase" do
    phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    mnemonic = Mnemonic.from_phrase(phrase)
    seed = Mnemonic.to_seed(mnemonic, "testpass")
    assert is_binary(seed)
    assert byte_size(seed) == 64
  end
end
