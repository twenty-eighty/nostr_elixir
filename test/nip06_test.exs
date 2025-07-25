defmodule NostrElixir.Nip06Test do
  use ExUnit.Case, async: true
  alias NostrElixir.Nip06
  alias NostrElixir.Mnemonic

  test "derive_key/2 returns keys for valid seed and path" do
    mnemonic = Mnemonic.generate(12)
    seed = Mnemonic.to_seed(mnemonic)
    path = "m/44'/1237'/0'/0/0"
    seed_hex = Base.encode16(seed, case: :lower)
    result = Nip06.derive_key(seed_hex, path)
    assert is_map(result)
    assert String.starts_with?(result["public_key"], "02") or String.starts_with?(result["public_key"], "03")
    assert String.length(result["secret_key"]) == 64
    assert result["derivation_path"] == path
  end
end
