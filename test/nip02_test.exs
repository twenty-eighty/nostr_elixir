defmodule NostrElixir.Nip02Test do
  use ExUnit.Case, async: true
  alias NostrElixir.Nip02
  alias NostrElixir.Nip02.Follow

  @pubkey "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
  @alice "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  @bob   "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  @carol "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
  @dave  "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
  @eve   "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
  @foo   "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  @bar   "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

  test "create and extract follow list event round-trip" do
    follows = [
      {@alice, "wss://relay1.example.com", "Alice"},
      {@bob, nil, nil},
      {@carol, "wss://relay2.example.com", nil}
    ]
    event_json = Nip02.create_follow_list_event(follows, @pubkey)
    assert is_binary(event_json)
    extracted = Nip02.extract_follows(event_json)
    assert Enum.sort(extracted) == Enum.sort(follows)
  end

  test "create follow list event with empty list" do
    event_json = Nip02.create_follow_list_event([], @pubkey)
    assert is_binary(event_json)
    extracted = Nip02.extract_follows(event_json)
    assert extracted == []
  end

  test "extract follow list with only nil fields" do
    follows = [
      {@dave, nil, nil},
      {@eve, nil, nil}
    ]
    event_json = Nip02.create_follow_list_event(follows, @pubkey)
    extracted = Nip02.extract_follows(event_json)
    assert Enum.sort(extracted) == Enum.sort(follows)
  end

  test "tuple <-> struct conversion" do
    tuple = {@foo, "wss://relay.example.com", "Foo"}
    struct = Nip02.tuple_to_struct(tuple)
    assert struct == %Follow{pubkey: @foo, relay_url: "wss://relay.example.com", alias: "Foo"}
    assert Nip02.struct_to_tuple(struct) == tuple
  end

  test "pretty print follow list" do
    follows = [
      %Follow{pubkey: @foo, relay_url: "wss://relay.example.com", alias: "Foo"},
      {@bar, nil, "Bar"}
    ]
    output = Nip02.pretty_print(follows)
    assert output =~ @foo
    assert output =~ "wss://relay.example.com"
    assert output =~ "(Foo)"
    assert output =~ @bar
    assert output =~ "(Bar)"
  end
end
