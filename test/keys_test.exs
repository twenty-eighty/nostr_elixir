defmodule NostrElixir.KeysTest do
  use ExUnit.Case, async: true
  alias NostrElixir.Keys

  test "generate_keys returns a JSON string with public_key and secret_key" do
    keys_json = Keys.generate_keys()
    keys = Jason.decode!(keys_json)
    assert is_map(keys)
    assert Map.has_key?(keys, "public_key")
    assert Map.has_key?(keys, "secret_key")
    assert is_binary(keys["public_key"])
    assert is_binary(keys["secret_key"])
    assert String.length(keys["public_key"]) == 64
    assert String.length(keys["secret_key"]) == 64
  end

  test "parse_keys works with hex secret key" do
    test_secret = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    keys_json = Keys.parse_keys(test_secret)
    keys = Jason.decode!(keys_json)
    assert is_map(keys)
    assert Map.has_key?(keys, "public_key")
    assert Map.has_key?(keys, "secret_key")
  end

  test "parse_keys works with bech32 secret key" do
    test_nsec = "nsec1j4c6269y9w0q2er2xjw8sv2ehyrtfxq3jwgdlxj6qfn8z4gjsq5qfvfk99"
    keys_json = Keys.parse_keys(test_nsec)
    keys = Jason.decode!(keys_json)
    assert is_map(keys)
    assert Map.has_key?(keys, "public_key")
    assert Map.has_key?(keys, "secret_key")
  end

  test "get_public_key and get_secret_key work" do
    keys_json = Keys.generate_keys()
    public_key = Keys.get_public_key(keys_json)
    secret_key = Keys.get_secret_key(keys_json)
    keys = Jason.decode!(keys_json)
    assert public_key == keys["public_key"]
    assert secret_key == keys["secret_key"]
  end

  test "public_key_to_bech32 converts hex to bech32" do
    test_pubkey = "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"
    bech32 = Keys.public_key_to_bech32(test_pubkey)
    assert String.starts_with?(bech32, "npub")
    assert String.length(bech32) > 60
  end

  test "public_key_to_bech32 raises error for invalid input" do
    assert_raise ArgumentError, ~r/Failed to convert public key to bech32/, fn ->
      Keys.public_key_to_bech32("invalid")
    end
  end

  test "secret_key_to_bech32 converts hex to bech32" do
    test_secret = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    bech32 = Keys.secret_key_to_bech32(test_secret)
    assert String.starts_with?(bech32, "nsec")
    assert String.length(bech32) > 60
  end

  test "secret_key_to_bech32 raises error for invalid input" do
    assert_raise ArgumentError, ~r/Failed to convert secret key to bech32/, fn ->
      Keys.secret_key_to_bech32("invalid")
    end
  end

  test "secret_key_to_hex converts bech32 to hex" do
    test_nsec = "nsec1j4c6269y9w0q2er2xjw8sv2ehyrtfxq3jwgdlxj6qfn8z4gjsq5qfvfk99"
    hex = Keys.secret_key_to_hex(test_nsec)
    assert String.length(hex) == 64
    assert String.match?(hex, ~r/^[0-9a-f]+$/)
  end

  test "secret_key_to_hex raises error for invalid input" do
    assert_raise ArgumentError, ~r/Failed to convert secret key to hex/, fn ->
      Keys.secret_key_to_hex("invalid")
    end
  end

  test "generate_keypair returns a map with all keys" do
    keys = Keys.generate_keypair()
    assert Map.has_key?(keys, :public_key)
    assert Map.has_key?(keys, :secret_key)
    assert Map.has_key?(keys, :npub)
    assert Map.has_key?(keys, :nsec)
    assert String.starts_with?(keys.npub, "npub")
    assert String.starts_with?(keys.nsec, "nsec")
  end

  test "parse_keypair returns a map with all keys" do
    test_secret = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    keys = Keys.parse_keypair(test_secret)
    assert Map.has_key?(keys, :public_key)
    assert Map.has_key?(keys, :secret_key)
    assert Map.has_key?(keys, :npub)
    assert Map.has_key?(keys, :nsec)
    assert String.starts_with?(keys.npub, "npub")
    assert String.starts_with?(keys.nsec, "nsec")
  end
end
