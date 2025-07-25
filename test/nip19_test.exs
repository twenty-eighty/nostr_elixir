defmodule NostrElixir.Nip19Test do
  use ExUnit.Case, async: true
  alias NostrElixir.Nip19

  test "nip19_encode and nip19_decode work" do
    test_pubkey = "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"
    npub = Nip19.encode("npub", test_pubkey)
    assert String.starts_with?(npub, "npub")
    decoded_json = Nip19.decode(npub)
    decoded = Jason.decode!(decoded_json)
    assert decoded["data_type"] == "npub"
    assert decoded["data"] == test_pubkey
  end

  test "nip19_encode raises error for invalid input" do
    assert_raise ArgumentError, fn ->
      Nip19.encode("invalid", "invalid")
    end
  end

  test "nip19_decode raises error for invalid input" do
    assert_raise ArgumentError, fn ->
      Nip19.decode("invalid")
    end
  end

  test "nip19_decode_map returns a map with data_type and data" do
    test_pubkey = "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"
    npub = Nip19.encode("npub", test_pubkey)
    result = Nip19.decode_map(npub)
    assert result.data_type == "npub"
    assert result.data == test_pubkey
  end

  test "nip19_decode_map raises error for invalid input" do
    assert_raise ArgumentError, fn ->
      Nip19.decode_map("invalid")
    end
  end
end
