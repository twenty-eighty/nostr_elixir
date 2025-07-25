defmodule NostrElixir.Nip09Test do
  use ExUnit.Case, async: true
  alias NostrElixir.{Keys, Nip09, Event}

  test "create_deletion_event creates a valid deletion event" do
    keys = Keys.generate_keypair()
    event_ids = ["abc123", "def456"]
    reason = "Content was inappropriate"

    event_json = Nip09.create_deletion_event(keys, event_ids, reason)

    assert is_binary(event_json)
    assert Event.verify(event_json)

    event = Jason.decode!(event_json)
    assert event["kind"] == 5
    assert event["content"] == reason

    # Check for event ID tags
    tags = event["tags"]
    assert length(tags) == 2

    event_id_values = Enum.map(tags, fn tag -> Enum.at(tag, 1) end)
    assert "abc123" in event_id_values
    assert "def456" in event_id_values

    # All tags should be "e" tags
    assert Enum.all?(tags, fn tag -> List.first(tag) == "e" end)
  end

  test "create_deletion_event without reason" do
    keys = Keys.generate_keypair()
    event_ids = ["single_event"]

    event_json = Nip09.create_deletion_event(keys, event_ids)

    assert is_binary(event_json)
    assert Event.verify(event_json)

    event = Jason.decode!(event_json)
    assert event["kind"] == 5
    assert event["content"] == ""

    tags = event["tags"]
    assert length(tags) == 1
    assert List.first(List.first(tags)) == "e"
    assert Enum.at(List.first(tags), 1) == "single_event"
  end

  test "create_deletion_event with empty event_ids list" do
    keys = Keys.generate_keypair()
    event_ids = []
    reason = "No specific events"

    event_json = Nip09.create_deletion_event(keys, event_ids, reason)

    assert is_binary(event_json)
    assert Event.verify(event_json)

    event = Jason.decode!(event_json)
    assert event["kind"] == 5
    assert event["content"] == reason
    assert event["tags"] == []
  end

  test "extract_deletion extracts all fields correctly" do
    event_json = """
    {
      "kind": 5,
      "content": "Inappropriate content",
      "tags": [
        ["e", "event_id_1"],
        ["e", "event_id_2"],
        ["e", "event_id_3"]
      ]
    }
    """

    deletion = Nip09.extract_deletion(event_json)

    assert deletion.event_ids == ["event_id_1", "event_id_2", "event_id_3"]
    assert deletion.reason == "Inappropriate content"
  end

  test "extract_deletion handles empty content" do
    event_json = """
    {
      "kind": 5,
      "content": "",
      "tags": [
        ["e", "event_id_1"]
      ]
    }
    """

    deletion = Nip09.extract_deletion(event_json)

    assert deletion.event_ids == ["event_id_1"]
    assert deletion.reason == ""
  end

  test "extract_deletion handles missing tags" do
    event_json = """
    {
      "kind": 5,
      "content": "No events specified",
      "tags": []
    }
    """

    deletion = Nip09.extract_deletion(event_json)

    assert deletion.event_ids == []
    assert deletion.reason == "No events specified"
  end

  test "pretty_print formats output correctly" do
    event_json = """
    {
      "id": "deletion_event_id",
      "pubkey": "deletion_author",
      "kind": 5,
      "content": "Content was inappropriate",
      "tags": [
        ["e", "event_id_1"],
        ["e", "event_id_2"]
      ]
    }
    """

    output = Nip09.pretty_print(event_json)

    assert output =~ "🗑️  Event Deletion"
    assert output =~ "Deleted Events: 2"
    assert output =~ "  • event_id_1"
    assert output =~ "  • event_id_2"
    assert output =~ "Reason: Content was inappropriate"
    assert output =~ "Event ID: deletion_event_id"
    assert output =~ "Author: deletion_author"
  end

  test "pretty_print without reason" do
    event_json = """
    {
      "id": "deletion_event_id",
      "pubkey": "deletion_author",
      "kind": 5,
      "content": "",
      "tags": [
        ["e", "event_id_1"]
      ]
    }
    """

    output = Nip09.pretty_print(event_json)

    assert output =~ "🗑️  Event Deletion"
    assert output =~ "Deleted Events: 1"
    assert output =~ "  • event_id_1"
    refute output =~ "Reason:"
    assert output =~ "Event ID: deletion_event_id"
    assert output =~ "Author: deletion_author"
  end

  test "build_deletion_tags creates correct tag structure" do
    event_ids = ["id1", "id2", "id3"]

    tags = Nip09.build_deletion_tags(event_ids)

    expected_tags = [
      ["e", "id1"],
      ["e", "id2"],
      ["e", "id3"]
    ]

    assert tags == expected_tags
  end

  test "build_deletion_tags handles empty list" do
    tags = Nip09.build_deletion_tags([])
    assert tags == []
  end

  test "round-trip: create and extract deletion" do
    keys = Keys.generate_keypair()
    original_event_ids = ["event_1", "event_2", "event_3"]
    original_reason = "Testing round-trip"

    event_json = Nip09.create_deletion_event(keys, original_event_ids, original_reason)
    deletion = Nip09.extract_deletion(event_json)

    assert deletion.event_ids == original_event_ids
    assert deletion.reason == original_reason
  end
end
