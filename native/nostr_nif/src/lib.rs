use rustler::NifResult;
use nostr::prelude::*;
use nostr::{Event, EventBuilder, EventId, Filter, Kind, Tag, Timestamp};
use nostr::secp256k1::Message;
use serde_json;
use std::str::FromStr;

rustler::init!("Elixir.NostrElixir", [
    keys_generate_nif,
    keys_parse_nif,
    keys_public_key_nif,
    keys_secret_key_nif,
    keys_public_key_bech32_nif,
    keys_secret_key_bech32_nif,
    keys_secret_key_hex_nif,
    parser_parse_nif,
    nip19_encode_nif,
    nip19_decode_nif,
    event_new_nif,
    event_sign_nif,
    event_verify_nif,
    event_to_json_nif,
    event_from_json_nif,
    filter_new_nif,
    filter_to_json_nif,
    filter_from_json_nif,
]);

// Helper function to convert nostr errors to rustler errors
fn to_rustler_error<T>(result: Result<T, impl std::fmt::Display>) -> NifResult<T> {
    result.map_err(|e| rustler::Error::Term(Box::new(e.to_string())))
}

#[rustler::nif]
fn keys_generate_nif() -> NifResult<String> {
    let keys = Keys::generate();
    let public_key = keys.public_key();
    let secret_key = keys.secret_key();
    
    let result = serde_json::json!({
        "public_key": public_key.to_string(),
        "secret_key": secret_key.to_secret_hex()
    });
    
    Ok(result.to_string())
}

#[rustler::nif]
fn keys_parse_nif(secret_key_str: String) -> NifResult<String> {
    let keys = to_rustler_error(Keys::parse(&secret_key_str))?;
    let public_key = keys.public_key();
    let secret_key = keys.secret_key();
    
    let result = serde_json::json!({
        "public_key": public_key.to_string(),
        "secret_key": secret_key.to_secret_hex()
    });
    
    Ok(result.to_string())
}

#[rustler::nif]
fn keys_public_key_nif(keys_json: String) -> NifResult<String> {
    let keys: serde_json::Value = to_rustler_error(serde_json::from_str(&keys_json))?;
    Ok(keys["public_key"].as_str().unwrap_or("").to_string())
}

#[rustler::nif]
fn keys_secret_key_nif(keys_json: String) -> NifResult<String> {
    let keys: serde_json::Value = to_rustler_error(serde_json::from_str(&keys_json))?;
    Ok(keys["secret_key"].as_str().unwrap_or("").to_string())
}

#[rustler::nif]
fn keys_public_key_bech32_nif(public_key_str: String) -> NifResult<String> {
    let public_key = to_rustler_error(PublicKey::from_hex(&public_key_str))?;
    to_rustler_error(public_key.to_bech32())
}

#[rustler::nif]
fn keys_secret_key_bech32_nif(secret_key_str: String) -> NifResult<String> {
    let secret_key = to_rustler_error(SecretKey::from_hex(&secret_key_str))?;
    to_rustler_error(secret_key.to_bech32())
}

#[rustler::nif]
fn keys_secret_key_hex_nif(secret_key_str: String) -> NifResult<String> {
    let secret_key = to_rustler_error(SecretKey::from_bech32(&secret_key_str))?;
    Ok(secret_key.to_secret_hex())
}

#[rustler::nif]
fn parser_parse_nif(text: String) -> NifResult<String> {
    let parser = NostrParser::new();
    let tokens = parser.parse(&text);
    
    let mut result = Vec::new();
    for token in tokens {
        match token {
            nostr::parser::Token::Text(text) => {
                result.push(serde_json::json!({
                    "token_type": "text",
                    "value": text.to_string()
                }));
            }
            nostr::parser::Token::Url(url) => {
                result.push(serde_json::json!({
                    "token_type": "url",
                    "value": url.to_string()
                }));
            }
            nostr::parser::Token::Hashtag(tag) => {
                result.push(serde_json::json!({
                    "token_type": "hashtag",
                    "value": tag.to_string()
                }));
            }
            _ => {
                // Handle other token types as text for now
                result.push(serde_json::json!({
                    "token_type": "text",
                    "value": format!("{:?}", token)
                }));
            }
        }
    }
    
    Ok(serde_json::to_string(&result).unwrap())
}

#[rustler::nif]
fn nip19_encode_nif(data_type: String, data: String) -> NifResult<String> {
    match data_type.as_str() {
        "npub" => {
            let pubkey = to_rustler_error(PublicKey::from_hex(&data))?;
            to_rustler_error(pubkey.to_bech32())
        }
        "nsec" => {
            let secret_key = to_rustler_error(SecretKey::from_hex(&data))?;
            to_rustler_error(secret_key.to_bech32())
        }
        "note" => {
            let event_id = to_rustler_error(EventId::from_hex(&data))?;
            to_rustler_error(event_id.to_bech32())
        }
        _ => Err(rustler::Error::BadArg),
    }
}

#[rustler::nif]
fn nip19_decode_nif(bech32_string: String) -> NifResult<String> {
    let result = if bech32_string.starts_with("npub") {
        let pubkey = to_rustler_error(PublicKey::from_bech32(&bech32_string))?;
        serde_json::json!({
            "data_type": "npub",
            "data": pubkey.to_string()
        })
    } else if bech32_string.starts_with("nsec") {
        let secret_key = to_rustler_error(SecretKey::from_bech32(&bech32_string))?;
        serde_json::json!({
            "data_type": "nsec",
            "data": secret_key.to_secret_hex()
        })
    } else if bech32_string.starts_with("note") {
        let event_id = to_rustler_error(EventId::from_bech32(&bech32_string))?;
        serde_json::json!({
            "data_type": "note",
            "data": event_id.to_string()
        })
    } else {
        return Err(rustler::Error::Term(Box::new("Unknown bech32 prefix".to_string())));
    };
    
    Ok(result.to_string())
}

#[rustler::nif]
fn event_new_nif(pubkey: String, content: String, kind: u16, tags_json: String) -> NifResult<String> {
    let public_key = to_rustler_error(PublicKey::from_hex(&pubkey))?;
    let kind = Kind::from(kind);
    
    let tags: Vec<Vec<String>> = to_rustler_error(serde_json::from_str(&tags_json))?;
    let tags: Vec<Tag> = tags.into_iter()
        .map(|tag_vec| {
            to_rustler_error(Tag::parse(tag_vec)).unwrap_or_else(|_| Tag::parse(vec!["t", "unknown"]).unwrap())
        })
        .collect();
    
    let event = EventBuilder::new(kind, content)
        .tags(tags)
        .build(public_key);
    
    let result = serde_json::json!({
        "id": event.id.expect("Event ID should be present").to_string(),
        "pubkey": event.pubkey.to_string(),
        "created_at": event.created_at.as_u64(),
        "kind": event.kind.as_u16(),
        "tags": event.tags.to_vec().into_iter().map(|tag| tag.to_vec()).collect::<Vec<Vec<String>>>(),
        "content": event.content,
        "sig": ""
    });
    
    Ok(result.to_string())
}

#[rustler::nif]
fn event_sign_nif(event_json: String, secret_key: String) -> NifResult<String> {
    let event_data: serde_json::Value = to_rustler_error(serde_json::from_str(&event_json))?;
    let keys = to_rustler_error(Keys::parse(&secret_key))?;
    
    let pubkey = to_rustler_error(PublicKey::from_hex(event_data["pubkey"].as_str().unwrap_or("")))?;
    let kind = Kind::from(event_data["kind"].as_u64().unwrap_or(0) as u16);
    let content = event_data["content"].as_str().unwrap_or("").to_string();
    
    let tags: Vec<Vec<String>> = event_data["tags"].as_array()
        .unwrap_or(&Vec::new())
        .iter()
        .map(|tag| tag.as_array().unwrap_or(&Vec::new()).iter().map(|v| v.as_str().unwrap_or("").to_string()).collect())
        .collect();
    
    let tags: Vec<Tag> = tags.into_iter()
        .map(|tag_vec| {
            to_rustler_error(Tag::parse(tag_vec)).unwrap_or_else(|_| Tag::parse(vec!["t", "unknown"]).unwrap())
        })
        .collect();
    
    let unsigned_event = EventBuilder::new(kind, content)
        .tags(tags)
        .build(pubkey);
    
    // For now, we'll use a simplified approach since async signing is complex in NIFs
    // We'll create a signed event manually by computing the signature
    let event_id = unsigned_event.id.expect("Event ID should be present");
    let message = Message::from_slice(event_id.as_bytes()).unwrap();
    let signature = keys.sign_schnorr(&message);
    
    let result = serde_json::json!({
        "id": event_id.to_string(),
        "pubkey": unsigned_event.pubkey.to_string(),
        "created_at": unsigned_event.created_at.as_u64(),
        "kind": unsigned_event.kind.as_u16(),
        "tags": unsigned_event.tags.to_vec().into_iter().map(|tag| tag.to_vec()).collect::<Vec<Vec<String>>>(),
        "content": unsigned_event.content,
        "sig": signature.to_string()
    });
    
    Ok(result.to_string())
}

#[rustler::nif]
fn event_verify_nif(event_json: String) -> NifResult<bool> {
    let event_data: serde_json::Value = to_rustler_error(serde_json::from_str(&event_json))?;
    
    let id = to_rustler_error(EventId::from_hex(event_data["id"].as_str().unwrap_or("")))?;
    let pubkey = to_rustler_error(PublicKey::from_hex(event_data["pubkey"].as_str().unwrap_or("")))?;
    let created_at = Timestamp::from(event_data["created_at"].as_u64().unwrap_or(0));
    let kind = Kind::from(event_data["kind"].as_u64().unwrap_or(0) as u16);
    let content = event_data["content"].as_str().unwrap_or("").to_string();
    let sig = to_rustler_error(Signature::from_str(event_data["sig"].as_str().unwrap_or("")))?;
    
    let tags: Vec<Vec<String>> = event_data["tags"].as_array()
        .unwrap_or(&Vec::new())
        .iter()
        .map(|tag| tag.as_array().unwrap_or(&Vec::new()).iter().map(|v| v.as_str().unwrap_or("").to_string()).collect())
        .collect();
    
    let tags: Vec<Tag> = tags.into_iter()
        .map(|tag_vec| {
            to_rustler_error(Tag::parse(tag_vec)).unwrap_or_else(|_| Tag::parse(vec!["t", "unknown"]).unwrap())
        })
        .collect();
    
    // Create the event and verify the signature
    let event = Event::new(
        id,
        pubkey,
        created_at,
        kind,
        tags,
        content,
        sig
    );
    
    // Verify the signature
    match event.verify() {
        Ok(_) => Ok(true),
        Err(_) => Ok(false)
    }
}

#[rustler::nif]
fn event_to_json_nif(event_json: String) -> NifResult<String> {
    // The event is already in JSON format, just return it
    Ok(event_json)
}

#[rustler::nif]
fn event_from_json_nif(json_string: String) -> NifResult<String> {
    // Validate that it's valid JSON and has required fields
    let event_data: serde_json::Value = to_rustler_error(serde_json::from_str(&json_string))?;
    
    // Check required fields
    if !event_data["id"].is_string() || !event_data["pubkey"].is_string() || 
       !event_data["created_at"].is_number() || !event_data["kind"].is_number() ||
       !event_data["content"].is_string() || !event_data["sig"].is_string() {
        return Err(rustler::Error::Term(Box::new("Invalid event JSON: missing required fields".to_string())));
    }
    
    Ok(json_string)
}

#[rustler::nif]
fn filter_new_nif(filter_spec: String) -> NifResult<String> {
    let filter_data: serde_json::Value = to_rustler_error(serde_json::from_str(&filter_spec))?;
    let mut filter = Filter::new();
    
    // Add authors
    if let Some(authors) = filter_data["authors"].as_array() {
        let pubkeys: Result<Vec<PublicKey>, _> = authors.iter()
            .map(|a| PublicKey::from_hex(a.as_str().unwrap_or("")))
            .collect();
        if let Ok(pubkeys) = pubkeys {
            filter = filter.authors(pubkeys);
        }
    }
    
    // Add kinds
    if let Some(kinds) = filter_data["kinds"].as_array() {
        let kinds: Vec<Kind> = kinds.iter()
            .map(|k| Kind::from(k.as_u64().unwrap_or(0) as u16))
            .collect();
        filter = filter.kinds(kinds);
    }
    
    // Add limit
    if let Some(limit) = filter_data["limit"].as_u64() {
        filter = filter.limit(limit as usize);
    }
    
    // Add since
    if let Some(since) = filter_data["since"].as_u64() {
        filter = filter.since(Timestamp::from(since));
    }
    
    // Add until
    if let Some(until) = filter_data["until"].as_u64() {
        filter = filter.until(Timestamp::from(until));
    }
    
    // Add search
    if let Some(search) = filter_data["search"].as_str() {
        filter = filter.search(search);
    }
    
    // Add hashtags
    if let Some(hashtags) = filter_data["hashtags"].as_array() {
        for hashtag in hashtags {
            if let Some(tag) = hashtag.as_str() {
                filter = filter.hashtag(tag);
            }
        }
    }
    
    let result = serde_json::json!({
        "authors": filter.authors.map(|a| a.iter().map(|pk| pk.to_string()).collect::<Vec<String>>()),
        "kinds": filter.kinds.map(|k| k.iter().map(|kind| kind.as_u16()).collect::<Vec<u16>>()),
        "limit": filter.limit,
        "since": filter.since.map(|t| t.as_u64()),
        "until": filter.until.map(|t| t.as_u64()),
        "search": filter.search,
        "hashtags": filter_data["hashtags"]
    });
    
    Ok(result.to_string())
}

#[rustler::nif]
fn filter_to_json_nif(filter_json: String) -> NifResult<String> {
    // The filter is already in JSON format, just return it
    Ok(filter_json)
}

#[rustler::nif]
fn filter_from_json_nif(json_string: String) -> NifResult<String> {
    // Validate that it's valid JSON
    let _filter_data: serde_json::Value = to_rustler_error(serde_json::from_str(&json_string))?;
    Ok(json_string)
} 