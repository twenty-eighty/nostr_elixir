defmodule NostrElixir.FilterTest do
  use ExUnit.Case, async: true
  alias NostrElixir.Filter

  test "new_filter creates a filter" do
    filter_json =
      Filter.new(%{
        authors: ["eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"],
        kinds: [1, 3],
        limit: 10
      })

    filter = Jason.decode!(filter_json)

    assert filter["authors"] == [
             "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"
           ]

    assert filter["kinds"] == [1, 3]
    assert filter["limit"] == 10
  end

  test "filter_to_json and filter_from_json work" do
    filter_json =
      Filter.new(%{
        authors: ["eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"],
        kinds: [1]
      })

    assert Filter.to_json(filter_json) == filter_json
    assert Filter.from_json(filter_json) == filter_json
  end

  test "user_notes_filter creates a filter for user notes" do
    test_pubkey = "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"
    filter_json = Filter.user_notes_filter(test_pubkey)
    filter = Jason.decode!(filter_json)
    assert filter["authors"] == [test_pubkey]
    assert filter["kinds"] == [1]
    assert filter["limit"] == 100
  end

  test "user_follow_list_filter creates a filter for user follow list (kind 3)" do
    test_pubkey = "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"
    filter_json = Filter.user_follow_list_filter(test_pubkey)
    filter = Jason.decode!(filter_json)
    assert filter["authors"] == [test_pubkey]
    assert filter["kinds"] == [3]
    assert filter["limit"] == 1
  end

  test "get_user_metadata creates a filter for metadata" do
    test_pubkey = "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"
    filter_json = Filter.get_user_metadata(test_pubkey)
    filter = Jason.decode!(filter_json)
    assert filter["authors"] == [test_pubkey]
    assert filter["kinds"] == [0]
  end

  test "search_hashtag creates a filter for hashtag search" do
    filter_json = Filter.search_hashtag("nostr")
    filter = Jason.decode!(filter_json)
    assert filter["hashtags"] == ["nostr"]
    assert filter["kinds"] == [1]
    assert filter["limit"] == 50
  end

  test "recent_events creates a filter for recent events" do
    filter_json = Filter.recent_events()
    filter = Jason.decode!(filter_json)
    assert filter["kinds"] == [1]
    assert filter["limit"] == 20
  end
end
