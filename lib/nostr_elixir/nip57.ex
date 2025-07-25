defmodule NostrElixir.Nip57 do
  @moduledoc """
  NIP-57: Lightning Zaps (public, private, anonymous zap requests and decryption)

  ## Examples

      iex> alias NostrElixir.Nip57
      iex> data = Nip57.ZapRequestData.new(
      ...>   public_key: "npub...",
      ...>   relays: ["wss://relay.damus.io"],
      ...>   message: "Thanks!",
      ...>   amount: 1000
      ...> )
      iex> keys = ... # JSON-encoded NostrElixir.Keys
      iex> event_json = Nip57.private_zap_request(data, keys)
      iex> event = Jason.decode!(event_json)
      ...
      iex> decrypted = Nip57.decrypt_sent_private_zap_message(secret_key, public_key, event_json)
      ...
  """

  defmodule ZapRequestData do
    @moduledoc """
    Struct for NIP-57 Zap Request Data.
    """
    defstruct [
      :public_key,
      :relays,
      :message,
      :amount,
      :lnurl,
      :event_id,
      :event_coordinate
    ]

    @type t :: %__MODULE__{
            public_key: String.t(),
            relays: [String.t()],
            message: String.t(),
            amount: integer() | nil,
            lnurl: String.t() | nil,
            event_id: String.t() | nil,
            event_coordinate: String.t() | nil
          }

    @doc """
    Build a new ZapRequestData struct.
    """
    def new(opts) when is_list(opts) do
      struct(__MODULE__, opts)
    end
  end

  @doc """
  Create a private zap request event (returns JSON string).
  """
  def private_zap_request(%ZapRequestData{} = data, secret_key_hex) do
    case NostrElixir.nip57_private_zap_request_nif(
      data.public_key,
      data.relays,
      data.message || "",
      data.amount,
      data.lnurl,
      data.event_id,
      data.event_coordinate,
      secret_key_hex
    ) do
      {:error, reason} -> raise ArgumentError, "NIP-57 private_zap_request failed: #{reason}"
      result -> result
    end
  end

  @doc """
  Create an anonymous zap request event (returns JSON string).
  """
  def anonymous_zap_request(%ZapRequestData{} = data) do
    case NostrElixir.nip57_anonymous_zap_request_nif(
      data.public_key,
      data.relays,
      data.message || "",
      data.amount,
      data.lnurl,
      data.event_id,
      data.event_coordinate
    ) do
      {:error, reason} -> raise ArgumentError, "NIP-57 anonymous_zap_request failed: #{reason}"
      result -> result
    end
  end

  @doc """
  Decrypt a sent private zap message (returns decrypted event JSON).
  """
  def decrypt_sent_private_zap_message(secret_key, public_key, event_json) do
    case NostrElixir.nip57_decrypt_sent_private_zap_message_nif(secret_key, public_key, event_json) do
      {:error, reason} -> raise ArgumentError, "NIP-57 decrypt_sent_private_zap_message failed: #{reason}"
      result -> result
    end
  end

  @doc """
  Decrypt a received private zap message (returns decrypted event JSON).
  """
  def decrypt_received_private_zap_message(secret_key, event_json) do
    case NostrElixir.nip57_decrypt_received_private_zap_message_nif(secret_key, event_json) do
      {:error, reason} -> raise ArgumentError, "NIP-57 decrypt_received_private_zap_message failed: #{reason}"
      result -> result
    end
  end
end
