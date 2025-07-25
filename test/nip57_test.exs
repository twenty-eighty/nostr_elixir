defmodule NostrElixir.Nip57Test do
  use ExUnit.Case, async: true
  alias NostrElixir.Nip57
  alias NostrElixir.Nip57.ZapRequestData

  @alice_secret_key "5c0c523f52a5b6fad39ed2403092df8cebc36318b39383bca6c00808626fab3a"
  @bob_secret_key "4b22aa260e4acb7021e32f38a6cdf4b673c6a277755bfce287e370c924dc936d"

  describe "ZapRequestData.new/1" do
    test "builds struct with all fields" do
      data = ZapRequestData.new(public_key: "b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4", relays: ["wss://relay.damus.io"], message: "Zap!", amount: 1234, lnurl: "lnurl1...", event_id: "eventid", event_coordinate: "coord")
      assert data.public_key == "b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4"
      assert data.relays == ["wss://relay.damus.io"]
      assert data.message == "Zap!"
      assert data.amount == 1234
      assert data.lnurl == "lnurl1..."
      assert data.event_id == "eventid"
      assert data.event_coordinate == "coord"
    end
  end

  describe "private_zap_request/2 and decryption" do
    test "returns a valid event for placeholder keys" do
      data = ZapRequestData.new(public_key: "b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4", relays: ["wss://relay.damus.io"], message: "Thanks!", amount: 1000)
      result = Nip57.private_zap_request(data, @alice_secret_key)
      assert is_binary(result)
      assert String.length(result) > 0
    end
  end

  describe "anonymous_zap_request/1" do
    test "returns a valid event for placeholder keys" do
      data = ZapRequestData.new(public_key: "b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4", relays: ["wss://relay.damus.io"], message: "Anonymous!", amount: 500)
      result = Nip57.anonymous_zap_request(data)
      assert is_binary(result)
      assert String.length(result) > 0
    end
  end

  describe "decrypt_sent_private_zap_message/3 and decrypt_received_private_zap_message/2" do
    test "returns error for invalid event" do
      assert_raise ArgumentError, ~r/NIP-57 decrypt_sent_private_zap_message failed:/, fn ->
        Nip57.decrypt_sent_private_zap_message(@alice_secret_key, "b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4", "not_json")
      end
      assert_raise ArgumentError, ~r/NIP-57 decrypt_received_private_zap_message failed:/, fn ->
        Nip57.decrypt_received_private_zap_message(@bob_secret_key, "not_json")
      end
    end
  end
end
