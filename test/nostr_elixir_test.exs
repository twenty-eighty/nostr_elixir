defmodule NostrElixirTest do
  use ExUnit.Case
  doctest NostrElixir

  test "parse_text returns a JSON string with tokens" do
    text = "Hello @npub1abc123 #nostr https://example.com"
    tokens_json = NostrElixir.parser_parse_nif(text)
    tokens = Jason.decode!(tokens_json)
    assert is_list(tokens)
    assert Enum.any?(tokens, fn token -> token["token_type"] == "text" end)
    assert Enum.any?(tokens, fn token -> token["token_type"] == "hashtag" end)
    assert Enum.any?(tokens, fn token -> token["token_type"] == "url" end)
  end

  test "parse_text_tokens returns a list of maps" do
    text = "Hello #nostr https://example.com"
    tokens = NostrElixir.parse_text_tokens(text)
    assert is_list(tokens)
    assert Enum.any?(tokens, fn token -> token.token_type == "hashtag" end)
    assert Enum.any?(tokens, fn token -> token.token_type == "url" end)
  end
end
