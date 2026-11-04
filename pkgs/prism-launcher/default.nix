{
  lib,
  fetchFromGitHub,
  prismlauncher,
  prismlauncher-unwrapped,
}:

let
  sources = lib.importJSON ./sources.json;

  src = fetchFromGitHub {
    inherit (sources)
      owner
      repo
      rev
      hash
      ;
  };

  unwrapped-modded = prismlauncher-unwrapped.overrideAttrs (old: {
    inherit src;
    postUnpack = builtins.replaceStrings [ "source/" ] [ "$sourceRoot/" ] old.postUnpack;
  });
in
prismlauncher.override {
  prismlauncher-unwrapped = unwrapped-modded;
}
