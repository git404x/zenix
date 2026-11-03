# native zen-browser derivation for zenix
{
  lib,
  stdenv,
  fetchzip,
  wrapFirefox,
  autoPatchelfHook,
  wrapGAppsHook3,
  gtk3,
  adwaita-icon-theme,
  alsa-lib,
  dbus-glib,
  libXtst,
  ffmpeg_8,
  curl,
  libva,
  pciutils,
  libGL,
  pipewire,
  p11-kit,
  writeText,
}:

let
  versions = lib.importJSON ./versions.json;
  pname = "zen-browser";
  version = versions.version;

  basePolicies = {
    SecurityDevices = {
      "System Trust" = "${p11-kit}/lib/pkcs11/p11-kit-trust.so";
    };
  };
  policiesJson = writeText "firefox-policies.json" (builtins.toJSON { policies = basePolicies; });

  unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    src = fetchzip {
      inherit (versions) url hash;
    };

    nativeBuildInputs = [
      wrapGAppsHook3
      autoPatchelfHook
    ];

    buildInputs = [
      gtk3
      adwaita-icon-theme
      alsa-lib
      dbus-glib
      libXtst
      ffmpeg_8
    ];

    runtimeDependencies = [
      curl
      libva.out
      pciutils
      libGL
      pipewire
    ];

    appendRunpaths = [
      "${libGL}/lib"
      "${pipewire}/lib"
    ];

    patchelfFlags = [ "--no-clobber-old-sections" ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/zen $out/bin $out/share/applications $out/share/icons/hicolor/128x128/apps
      cp -r * $out/lib/zen/
      ln -s $out/lib/zen/zen $out/bin/zen

      mkdir -p $out/lib/zen/distribution
      ln -s ${policiesJson} $out/lib/zen/distribution/policies.json

      if [ -f $out/lib/zen/browser/chrome/icons/default/default128.png ]; then
        ln -s $out/lib/zen/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
      fi

      cat > $out/share/applications/zen.desktop <<EOF
[Desktop Entry]
Version=1.0
Name=Zen Browser
Comment=Experience tranquillity while browsing the web
Exec=$out/bin/zen %u
Terminal=false
Type=Application
Icon=zen
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;application/pdf;
StartupWMClass=zen
EOF

      runHook postInstall
    '';

    passthru = {
      inherit gtk3;
      binaryName = "zen";
      applicationName = "zen";
      libName = "zen";
    };

    meta = with lib; {
      description = "Zen Browser - Experience tranquillity while browsing the web";
      homepage = "https://zen-browser.app";
      license = licenses.mpl20;
      platforms = [ "x86_64-linux" "aarch64-linux" ];
      mainProgram = "zen";
    };
  };

in
wrapFirefox (unwrapped // { inherit gtk3; binaryName = "zen"; applicationName = "zen"; libName = "zen"; }) {
  pname = "zen-browser";
  libName = "zen";
  extraPrefs = "";
}
