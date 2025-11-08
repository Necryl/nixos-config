{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    rustup
    rust-analyzer
    wasm-pack
    wasm-bindgen-cli
    # add other tools you want available globally
  ];
}
