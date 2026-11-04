# native zen-browser derivation for zenix
{
  lib,
  stdenv,
  fetchzip,
  wrapFirefox,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeDesktopItem,
  copyDesktopItems,
  gtk3,
  alsa-lib,
  curl,
  libva,
  pciutils,
  libGL,
  pipewire,
  p11-kit,
  formats,
}:

let
  versions = lib.importJSON ./versions.json;

  basePolicies = {
    policies = {
      SecurityDevices = {
        "System Trust" = "${p11-kit}/lib/pkcs11/p11-kit-trust.so";
      };
    };
  };

  policiesJson = (formats.json { }).generate "zen-policies.json" basePolicies;

  mkZen =
    {
      variant ? "beta",
      variantName ? if variant == "twilight" then "Zen Browser (Twilight)" else "Zen Browser",
      nameSuffix ? if variant == "twilight" then "-twilight" else "",
    }:
    let
      variantData = versions.${variant};
      pname = "zen-browser${nameSuffix}";
      version = variantData.version;

      unwrapped = stdenv.mkDerivation {
        pname = "${pname}-unwrapped";
        inherit version;

        src = fetchzip {
          inherit (variantData) url hash;
        };

        nativeBuildInputs = [
          wrapGAppsHook3
          autoPatchelfHook
          copyDesktopItems
        ];

        buildInputs = [
          gtk3
          alsa-lib
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

        desktopItems = [
          (makeDesktopItem {
            name = "zen${nameSuffix}";
            desktopName = variantName;
            genericName = "Web Browser";
            comment = "Experience tranquillity while browsing the web";
            exec = "zen${nameSuffix} %u";
            icon = "zen${nameSuffix}";
            terminal = false;
            categories = [
              "Network"
              "WebBrowser"
            ];
            mimeTypes = [
              "text/html"
              "text/xml"
              "application/xhtml+xml"
              "application/vnd.mozilla.xul+xml"
              "x-scheme-handler/http"
              "x-scheme-handler/https"
              "application/pdf"
            ];
            startupWMClass = "zen${nameSuffix}";
            actions = {
              new-window = {
                name = "New Window";
                exec = "zen${nameSuffix} --new-window %u";
              };
              new-private-window = {
                name = "New Private Window";
                exec = "zen${nameSuffix} --private-window %u";
              };
            };
          })
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/zen $out/bin
          cp -r * $out/lib/zen/
          ln -s $out/lib/zen/zen $out/bin/zen${nameSuffix}

          mkdir -p $out/lib/zen/distribution
          ln -s ${policiesJson} $out/lib/zen/distribution/policies.json

          for size in 16 32 48 64 128; do
            if [ -f browser/chrome/icons/default/default$size.png ]; then
              install -Dm644 browser/chrome/icons/default/default$size.png \
                $out/share/icons/hicolor/''${size}x''${size}/apps/zen${nameSuffix}.png
            fi
          done

          runHook postInstall
        '';

        passthru = {
          inherit gtk3;
          binaryName = "zen${nameSuffix}";
          applicationName = "zen${nameSuffix}";
          libName = "zen";
        };

        meta = with lib; {
          description = "${variantName} - Experience tranquillity while browsing the web";
          homepage = "https://zen-browser.app";
          license = licenses.mpl20;
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          mainProgram = "zen${nameSuffix}";
        };
      };
    in
    wrapFirefox (unwrapped // {
      inherit gtk3;
      binaryName = "zen${nameSuffix}";
      applicationName = "zen${nameSuffix}";
      libName = "zen";
    }) {
      inherit pname;
      libName = "zen";
      extraPrefs = "";
    };

in
{
  default = mkZen { variant = "beta"; };
  beta = mkZen { variant = "beta"; };
  twilight = mkZen { variant = "twilight"; };
}
