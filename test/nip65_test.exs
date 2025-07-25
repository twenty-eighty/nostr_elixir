defmodule NostrElixir.Nip65Test do
  use ExUnit.Case, async: true
  alias NostrElixir.Nip65

  @pubkey "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"

  test "create and extract relay list event round-trip" do
    relays = [
      {"wss://relay1.example.com", "read"},
      {"wss://relay2.example.com", "write"},
      {"wss://relay3.example.com", nil}
    ]
    event_json = Nip65.create_relay_list_event(relays, @pubkey)
    assert is_binary(event_json)
    extracted = Nip65.extract_relay_list(event_json)
    assert Enum.sort(extracted) == Enum.sort(relays)
  end

  test "create relay list event with empty list" do
    event_json = Nip65.create_relay_list_event([], @pubkey)
    assert is_binary(event_json)
    extracted = Nip65.extract_relay_list(event_json)
    assert extracted == []
  end

  test "extract relay list from event with only nil metadata" do
    relays = [
      {"wss://relay4.example.com", nil},
      {"wss://relay5.example.com", nil}
    ]
    event_json = Nip65.create_relay_list_event(relays, @pubkey)
    extracted = Nip65.extract_relay_list(event_json)
    assert Enum.sort(extracted) == Enum.sort(relays)
  end
end
