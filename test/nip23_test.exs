defmodule NostrElixir.Nip23Test do
  use ExUnit.Case, async: true
  alias NostrElixir.{Keys, Nip23, Event}

  test "create_long_form creates a valid long-form content event" do
    keys = Keys.generate_keypair()
    opts = %{title: "My Article"}
    content = "# My Article\n\nThis is the full article content."

    event_json = Nip23.create_long_form(keys, content, opts)

    assert is_binary(event_json)
    assert Event.verify(event_json)

    event = Jason.decode!(event_json)
    assert event["kind"] == 30023
    assert event["content"] == content

    # Check for title tag
    assert Enum.any?(event["tags"], fn tag ->
      tag |> List.first() == "title" && Enum.at(tag, 1) == "My Article"
    end)
  end

  test "create_long_form with all optional fields" do
    keys = Keys.generate_keypair()
    opts = %{
      title: "Complete Article",
      summary: "A comprehensive summary",
      image: "https://example.com/image.jpg",
      published_at: 1234567890,
      hashtags: ["nostr", "elixir"],
      canonical: "https://example.com/article",
      lang: "en"
    }
    content = "# Complete Article\n\nFull content here..."

    event_json = Nip23.create_long_form(keys, content, opts)

    assert is_binary(event_json)
    assert Event.verify(event_json)

    event = Jason.decode!(event_json)
    assert event["kind"] == 30023

    tags = event["tags"]

    # Check all tags are present
    assert Enum.any?(tags, fn tag -> tag |> List.first() == "title" && Enum.at(tag, 1) == "Complete Article" end)
    assert Enum.any?(tags, fn tag -> tag |> List.first() == "summary" && Enum.at(tag, 1) == "A comprehensive summary" end)
    assert Enum.any?(tags, fn tag -> tag |> List.first() == "image" && Enum.at(tag, 1) == "https://example.com/image.jpg" end)
    assert Enum.any?(tags, fn tag -> tag |> List.first() == "published_at" && Enum.at(tag, 1) == "1234567890" end)
    assert Enum.any?(tags, fn tag -> tag |> List.first() == "canonical" && Enum.at(tag, 1) == "https://example.com/article" end)
    assert Enum.any?(tags, fn tag -> tag |> List.first() == "lang" && Enum.at(tag, 1) == "en" end)

    # Check hashtags
    hashtag_tags = Enum.filter(tags, fn tag -> List.first(tag) == "t" end)
    assert length(hashtag_tags) == 2
    hashtag_values = Enum.map(hashtag_tags, fn tag -> Enum.at(tag, 1) end)
    assert "nostr" in hashtag_values
    assert "elixir" in hashtag_values
  end

  test "create_long_form with minimal options" do
    keys = Keys.generate_keypair()
    content = "Simple content"

    event_json = Nip23.create_long_form(keys, content)

    assert is_binary(event_json)
    assert Event.verify(event_json)

    event = Jason.decode!(event_json)
    assert event["kind"] == 30023
    assert event["content"] == content
    assert event["tags"] == []
  end

  test "extract_metadata extracts all fields correctly" do
    event_json = """
    {
      "kind": 30023,
      "content": "# Test Article\\n\\nContent here...",
      "tags": [
        ["title", "Test Article"],
        ["summary", "Test summary"],
        ["image", "https://example.com/image.jpg"],
        ["published_at", "1234567890"],
        ["t", "nostr"],
        ["t", "test"],
        ["canonical", "https://example.com/article"],
        ["lang", "en"]
      ]
    }
    """

    metadata = Nip23.extract_metadata(event_json)

    assert metadata.title == "Test Article"
    assert metadata.summary == "Test summary"
    assert metadata.image == "https://example.com/image.jpg"
    assert metadata.published_at == 1234567890
    assert metadata.hashtags == ["nostr", "test"]
    assert metadata.canonical == "https://example.com/article"
    assert metadata.lang == "en"
    assert metadata.content == "# Test Article\n\nContent here..."
  end

  test "extract_metadata handles missing fields" do
    event_json = """
    {
      "kind": 30023,
      "content": "Simple content",
      "tags": []
    }
    """

    metadata = Nip23.extract_metadata(event_json)

    assert metadata.title == nil
    assert metadata.summary == nil
    assert metadata.image == nil
    assert metadata.published_at == nil
    assert metadata.hashtags == []
    assert metadata.canonical == nil
    assert metadata.lang == nil
    assert metadata.content == "Simple content"
  end

  test "extract_metadata handles integer timestamp" do
    event_json = """
    {
      "kind": 30023,
      "content": "Content",
      "tags": [
        ["published_at", "1234567890"]
      ]
    }
    """

    metadata = Nip23.extract_metadata(event_json)
    assert metadata.published_at == 1234567890
  end

  test "pretty_print formats output correctly" do
    event_json = """
    {
      "id": "test_id",
      "pubkey": "test_pubkey",
      "kind": 30023,
      "content": "# Test Article\\n\\nThis is a test article with some content that should be truncated in the preview...",
      "tags": [
        ["title", "Test Article"],
        ["summary", "Test summary"],
        ["published_at", "1234567890"],
        ["t", "nostr"],
        ["lang", "en"]
      ]
    }
    """

    output = Nip23.pretty_print(event_json)

    assert output =~ "📄 Long-form Content Event"
    assert output =~ "Title: Test Article"
    assert output =~ "Summary: Test summary"
    assert output =~ "Published: 1234567890"
    assert output =~ "Tags: nostr"
    assert output =~ "Language: en"
    assert output =~ "Content Preview:"
    assert output =~ "Event ID: test_id"
    assert output =~ "Author: test_pubkey"
  end

  test "build_long_form_tags creates correct tag structure" do
    opts = %{
      title: "Test Title",
      summary: "Test Summary",
      image: "https://example.com/image.jpg",
      published_at: 1234567890,
      hashtags: ["tag1", "tag2"],
      canonical: "https://example.com/canonical",
      lang: "en"
    }

    tags = Nip23.build_long_form_tags(opts)

    expected_tags = [
      ["t", "tag1"],
      ["t", "tag2"],
      ["title", "Test Title"],
      ["summary", "Test Summary"],
      ["image", "https://example.com/image.jpg"],
      ["published_at", "1234567890"],
      ["canonical", "https://example.com/canonical"],
      ["lang", "en"]
    ]

    assert tags == expected_tags
  end

  test "build_long_form_tags handles empty options" do
    tags = Nip23.build_long_form_tags(%{})
    assert tags == []
  end

  test "build_long_form_tags handles nil hashtags" do
    opts = %{title: "Test", hashtags: nil}
    tags = Nip23.build_long_form_tags(opts)
    assert tags == [["title", "Test"]]
  end
end
