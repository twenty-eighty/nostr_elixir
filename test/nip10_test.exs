defmodule NostrElixir.Nip10Test do
  use ExUnit.Case, async: true
  alias NostrElixir.Nip10
  alias NostrElixir.Keys
  alias NostrElixir.Event

  test "create_text_note creates a valid event" do
    keys = Keys.generate_keypair()
    event_json = Nip10.create_text_note(keys, "Hello, NIP-10!")
    assert is_binary(event_json)
    assert Event.verify(event_json)
    event = Jason.decode!(event_json)
    assert event["kind"] == 1
    assert event["content"] == "Hello, NIP-10!"
  end

  test "create_reply creates a valid reply event" do
    root_keys = Keys.generate_keypair()
    reply_keys = Keys.generate_keypair()
    root_json = Nip10.create_text_note(root_keys, "Root post")
    reply_json = Nip10.create_reply(reply_keys, "Reply!", root_json)
    assert is_binary(reply_json)
    assert Event.verify(reply_json)
    reply = Jason.decode!(reply_json)
    assert reply["kind"] == 1
    assert reply["content"] == "Reply!"
    assert Enum.any?(reply["tags"], fn tag -> tag |> List.first() == "e" end)
    assert Enum.any?(reply["tags"], fn tag -> tag |> List.first() == "p" end)
  end

  test "create_reply with root and relay_url" do
    root_keys = Keys.generate_keypair()
    reply_keys = Keys.generate_keypair()
    root_json = Nip10.create_text_note(root_keys, "Root post")
    reply_json = Nip10.create_reply(reply_keys, "Reply!", root_json, root_json, "wss://relay.example.com")
    assert is_binary(reply_json)
    assert Event.verify(reply_json)
    reply = Jason.decode!(reply_json)
    assert reply["kind"] == 1
    assert reply["content"] == "Reply!"
    assert Enum.any?(reply["tags"], fn tag -> tag |> List.first() == "e" end)
    assert Enum.any?(reply["tags"], fn tag -> tag |> List.first() == "p" end)
    assert Enum.any?(reply["tags"], fn tag -> tag |> List.first() == "e" and Enum.any?(tag, &(&1 == "wss://relay.example.com")) end)
  end

  test "pretty_print outputs content and tags" do
    keys = Keys.generate_keypair()
    event_json = Nip10.create_text_note(keys, "Pretty print test")
    assert is_map(Nip10.pretty_print(event_json))
  end
end
