{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    rustup
    # rust-analyzer rustup was already providing this, so commented it out to fix the conflicting paths issue
    wasm-pack
    wasm-bindgen-cli
  ];
}
