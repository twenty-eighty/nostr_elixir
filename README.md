# NostrElixir

A complete Elixir wrapper for the [nostr](https://github.com/rust-nostr/nostr) Rust library, built with Rustler for high performance.

## Features

### Key Management
- Generate new keypairs
- Parse keys from hex or bech32 format
- Convert between hex and bech32 representations
- Extract public and secret keys

### Text Parsing
- Parse text to extract nostr-related tokens (hashtags, URLs, mentions)
- Identify nostr entities in text content

### NIP-19 Encoding/Decoding
- Encode public keys, secret keys, and event IDs to bech32 format
- Decode bech32 strings back to their original format

### Event Management
- Create unsigned events with custom content, kind, and tags
- Event signing (requires async support - coming soon)
- Event verification
- JSON serialization/deserialization

### Filter Management
- Create filters for querying events
- Support for authors, kinds, limits, time ranges, and hashtags
- JSON serialization/deserialization

### Convenience Functions
- High-level functions for common operations
- Pre-built filters for common use cases
- Keypair management utilities

## Installation

Add `nostr_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nostr_elixir, "~> 0.1.0"}
  ]
end
```

## Prerequisites

- Elixir 1.14 or later
- Rust toolchain (for compiling the NIF)
- Cargo (Rust package manager)

### Installing Rust

If you don't have Rust installed, you can install it using rustup:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Usage

### Key Management

```elixir
# Generate a new keypair
keys = NostrElixir.generate_keypair()
# Returns: %{public_key: "...", secret_key: "...", npub: "...", nsec: "..."}

# Parse an existing secret key
keys = NostrElixir.parse_keypair("nsec1j4c6269y9w0q2er2xjw8sv2ehyrtfxq3jwgdlxj6qfn8z4gjsq5qfvfk99")

# Convert formats
bech32_pubkey = NostrElixir.public_key_to_bech32("eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619")
hex_secret = NostrElixir.secret_key_to_hex("nsec1j4c6269y9w0q2er2xjw8sv2ehyrtfxq3jwgdlxj6qfn8z4gjsq5qfvfk99")
```

### Text Parsing

```elixir
# Parse text for nostr entities
tokens = NostrElixir.parse_text_tokens("Hello #nostr https://example.com @npub1abc123")
# Returns: [
#   %{token_type: "text", value: "Hello "},
#   %{token_type: "hashtag", value: "nostr"},
#   %{token_type: "url", value: "https://example.com"},
#   %{token_type: "text", value: " @npub1abc123"}
# ]
```

### NIP-19 Encoding/Decoding

```elixir
# Encode to bech32
npub = NostrElixir.nip19_encode("npub", "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619")

# Decode from bech32
result = NostrElixir.nip19_decode_map(npub)
# Returns: %{data_type: "npub", data: "eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"}
```

### Event Management

```elixir
# Create an unsigned event
keys = NostrElixir.generate_keypair()
event_json = NostrElixir.new_event(keys.public_key, "Hello, Nostr!", 1, [])
event = Jason.decode!(event_json)

# Event signing (currently requires async support)
# This will be implemented in a future version
# signed_event = NostrElixir.sign_event(event_json, keys.secret_key)
```

### Filter Management

```elixir
# Create a filter for following a user
filter_json = NostrElixir.follow_user("eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619")
filter = Jason.decode!(filter_json)

# Create a filter for hashtag search
filter_json = NostrElixir.search_hashtag("nostr")
filter = Jason.decode!(filter_json)

# Create a custom filter
filter_json = NostrElixir.new_filter(%{
  authors: ["eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619"],
  kinds: [1, 3],
  limit: 10
})
```

## API Reference

### Key Management Functions

- `generate_keys/0` - Generate new random keypair (returns JSON string)
- `parse_keys/1` - Parse secret key from hex or bech32 (returns JSON string)
- `get_public_key/1` - Extract public key from keys JSON
- `get_secret_key/1` - Extract secret key from keys JSON
- `public_key_to_bech32/1` - Convert hex public key to bech32
- `secret_key_to_bech32/1` - Convert hex secret key to bech32
- `secret_key_to_hex/1` - Convert bech32 secret key to hex
- `generate_keypair/0` - Generate complete keypair with all formats
- `parse_keypair/1` - Parse secret key and return complete keypair

### Text Parsing Functions

- `parse_text/1` - Parse text and return tokens as JSON string
- `parse_text_tokens/1` - Parse text and return tokens as list of maps

### NIP-19 Functions

- `nip19_encode/2` - Encode data to bech32 format
- `nip19_decode/1` - Decode bech32 format to data (returns JSON string)
- `nip19_decode_map/1` - Decode bech32 format to data (returns map)

### Event Functions

- `new_event/4` - Create unsigned event
- `sign_event/2` - Sign event (requires async support)
- `verify_event/1` - Verify event signature
- `event_to_json/1` - Convert event to JSON
- `event_from_json/1` - Parse event from JSON

### Filter Functions

- `new_filter/1` - Create filter from specification
- `filter_to_json/1` - Convert filter to JSON
- `filter_from_json/1` - Parse filter from JSON
- `follow_user/1` - Create filter for following user
- `get_user_metadata/1` - Create filter for user metadata
- `search_hashtag/1` - Create filter for hashtag search
- `recent_events/0` - Create filter for recent events

## Error Handling

The library uses idiomatic Elixir error handling:

- Functions raise `ArgumentError` with descriptive messages for invalid input
- JSON parsing errors are handled gracefully
- Invalid nostr data formats are caught and reported

## Performance

This library provides high performance through:

- Rust NIFs for computationally intensive operations
- Efficient memory management
- Optimized cryptographic operations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of the excellent [nostr](https://github.com/rust-nostr/nostr) Rust library
- Uses [Rustler](https://github.com/rusterlium/rustler) for Elixir/Rust interop
- Inspired by the nostr protocol community

## Roadmap

- [ ] Async event signing support
- [ ] Full event verification implementation
- [ ] Relay connection management
- [ ] Event subscription handling
- [ ] More convenience functions for common nostr operations

