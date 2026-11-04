{
  isHomeManager ? false,
  home-manager ? null,
}:
let
  extensionOpts =
    { lib }:
    lib.types.submodule {
      options = {
        id = lib.mkOption {
          type = lib.types.str;
          description = "Extension ID or GUID (e.g. uBlock0@raymondhill.net).";
        };
        slug = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Mozilla Add-ons (AMO) slug (e.g. ublock-origin). When set, installUrl is generated automatically.";
        };
        installUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Direct download URL for the extension XPI.";
        };
        installationMode = lib.mkOption {
          type = lib.types.enum [
            "allowed"
            "blocked"
            "force_installed"
            "normal_installed"
          ];
          default = "normal_installed";
          description = "Installation mode.";
        };
        privateBrowsing = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to allow extension in private browsing windows.";
        };
      };
    };

  extensionListToSettings =
    lib: exts:
    lib.listToAttrs (
      map (ext: {
        name = ext.id;
        value = {
          installation_mode = ext.installationMode;
          install_url =
            if ext.installUrl != null then
              ext.installUrl
            else if ext.slug != null then
              "https://addons.mozilla.org/firefox/downloads/latest/${ext.slug}/latest.xpi"
            else
              throw "Extension '${ext.id}' must specify either 'slug' or 'installUrl'.";
          private_browsing = ext.privateBrowsing;
        };
      }) exts
    );
in
if isHomeManager then
  let
    mkFirefoxModule =
      if home-manager != null then
        import "${home-manager}/modules/programs/firefox/mkFirefoxModule.nix"
      else
        throw "pkgs/zen/module.nix: home-manager input must be provided when isHomeManager is true";
  in
  {
    config,
    lib,
    pkgs,
    ...
  }:
  let
    cfg = config.programs.zen-browser;
  in
  {
    imports = [
      (mkFirefoxModule {
        modulePath = [
          "programs"
          "zen-browser"
        ];
        name = "Zen";
        description = "Zen Browser";
        wrappedPackageName = "zen-browser";
        unwrappedPackageName = "zen-browser-unwrapped";
        platforms = {
          linux.configPath = ".config/zen";
          darwin.configPath = "Library/Application Support/Zen";
        };
      })
    ];

    options.programs.zen-browser = {
      extensions = lib.mkOption {
        type = lib.types.listOf (extensionOpts { inherit lib; });
        default = [ ];
        description = "Declarative list of extensions to install via Mozilla policies.";
      };
    };

    config = lib.mkIf cfg.enable {
      programs.zen-browser.package = lib.mkDefault (
        pkgs.zen-browser or (pkgs.callPackage ./default.nix { }).default
      );

      programs.zen-browser.policies.ExtensionSettings = lib.mkIf (cfg.extensions != [ ]) (
        extensionListToSettings lib cfg.extensions
      );
    };
  }
else
  {
    config,
    lib,
    pkgs,
    ...
  }:
  let
    cfg = config.programs.zen-browser;
    allPolicies = (lib.optionalAttrs (cfg.extensions != [ ]) {
      ExtensionSettings = extensionListToSettings lib cfg.extensions;
    }) // cfg.policies;
  in
  {
    options.programs.zen-browser = {
      enable = lib.mkEnableOption "Zen Browser";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.zen-browser or (pkgs.callPackage ./default.nix { }).default;
        defaultText = lib.literalExpression "pkgs.zen-browser";
        description = "The Zen Browser package to install.";
      };

      extensions = lib.mkOption {
        type = lib.types.listOf (extensionOpts { inherit lib; });
        default = [ ];
        description = "Declarative list of extensions to install via Mozilla policies.";
      };

      policies = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = "System-wide policies for Zen Browser.";
      };

      nativeMessagingHosts.packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "List of packages providing native messaging hosts.";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [ cfg.package ];

      environment.etc = lib.mkIf (allPolicies != { }) {
        "zen/policies/policies.json".text = builtins.toJSON { policies = allPolicies; };
        "firefox/policies/policies.json".text = builtins.toJSON { policies = allPolicies; };
      };
    };
  }
