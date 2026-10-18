# Prebuilt static uv from the GitHub release, since nixpkgs lags behind (0.11.x stable, 0.13.0 unstable)
# Bump: change `version`, then `nix-prefetch-url <url>` (or the release's .sha256 file) for `sha256`
{ stdenvNoCC, fetchurl }:
stdenvNoCC.mkDerivation rec {
  pname = "uv";
  version = "0.13.1";
  src = fetchurl {
    url = "https://github.com/astral-sh/uv/releases/download/${version}/uv-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "6c86040a8f045ab9adc9e3ec4cdafa03fd00e9a988ed2bf28971c7fc2d0debd0";
  };
  installPhase = ''
    install -Dm755 -t $out/bin uv uvx
  '';
}
