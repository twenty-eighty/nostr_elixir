defmodule NostrElixir.Nip44Test do
  use ExUnit.Case, async: true
  alias NostrElixir.Nip44
  alias NostrElixir.Keys

  test "encrypt and decrypt round-trip" do
    keys1 = Keys.generate_keypair()
    keys2 = Keys.generate_keypair()
    plaintext = "hello nip44!"
    ciphertext = Nip44.encrypt(keys1.secret_key, keys2.public_key, plaintext)
    assert is_binary(ciphertext)
    decrypted = Nip44.decrypt(keys2.secret_key, keys1.public_key, ciphertext)
    assert decrypted == plaintext
  end

  test "decrypt with wrong key fails" do
    keys1 = Keys.generate_keypair()
    keys2 = Keys.generate_keypair()
    keys3 = Keys.generate_keypair()
    plaintext = "test"
    ciphertext = Nip44.encrypt(keys1.secret_key, keys2.public_key, plaintext)
    assert_raise ArgumentError, ~r/NIP-44 decrypt failed/, fn ->
      Nip44.decrypt(keys3.secret_key, keys1.public_key, ciphertext)
    end
  end
end
