defmodule NostrElixir.Nip17Test do
  use ExUnit.Case, async: true
  alias NostrElixir.Nip17

  @sender_secret_key "6b911fd37cdf5c81d4c0adb1ab7fa822ed253ab0ad9aa18d77257c88b29b718e"
  @receiver_secret_key "7b911fd37cdf5c81d4c0adb1ab7fa822ed253ab0ad9aa18d77257c88b29b718e"
  @sender_pubkey "02d0de0aaeaefad02b8bdc8a01a1b8b11c696bd3e2b1a7b4d4b8a0c7eab2cc8c76"
  @receiver_pubkey "02d0de0aaeaefad02b8bdc8a01a1b8b11c696bd3e2b1a7b4d4b8a0c7eab2cc8c76"

  describe "encrypt_dm/3 and decrypt_dm/3" do
    test "round-trip encryption and decryption with known-good vector" do
      plaintext = "Saturn, bringer of old age"
      sender_pubkey = NostrElixir.Keys.parse_keypair(@sender_secret_key).public_key
      receiver_pubkey = NostrElixir.Keys.parse_keypair(@receiver_secret_key).public_key
      ciphertext = Nip17.encrypt_dm(@sender_secret_key, receiver_pubkey, plaintext)
      decrypted = Nip17.decrypt_dm(@receiver_secret_key, sender_pubkey, ciphertext)
      assert decrypted == plaintext
    end

    test "raises on invalid secret key" do
      assert_raise ArgumentError, ~r/NIP-17 encrypt_dm failed:/, fn ->
        Nip17.encrypt_dm("invalid", @receiver_pubkey, "hi")
      end
      assert_raise ArgumentError, ~r/NIP-17 decrypt_dm failed:/, fn ->
        Nip17.decrypt_dm("invalid", @sender_pubkey, "ciphertext")
      end
    end

    test "raises on invalid ciphertext" do
      assert_raise ArgumentError, ~r/NIP-17 decrypt_dm failed:/, fn ->
        Nip17.decrypt_dm(@receiver_secret_key, @sender_pubkey, "not-a-ciphertext")
      end
    end
  end
end
