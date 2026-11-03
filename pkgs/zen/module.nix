{
  isHomeManager ? false,
  home-manager ? null,
}:
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

    config = lib.mkIf config.programs.zen-browser.enable {
      programs.zen-browser.package = lib.mkDefault (
        pkgs.zen-browser or (pkgs.callPackage ./default.nix { })
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
  in
  {
    options.programs.zen-browser = {
      enable = lib.mkEnableOption "Zen Browser";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.zen-browser or (pkgs.callPackage ./default.nix { });
        defaultText = lib.literalExpression "pkgs.zen-browser";
        description = "The Zen Browser package to install.";
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

      environment.etc."zen/policies/policies.json" = lib.mkIf (cfg.policies != { }) {
        text = builtins.toJSON { inherit (cfg) policies; };
      };

      environment.etc."firefox/policies/policies.json" = lib.mkIf (cfg.policies != { }) {
        text = builtins.toJSON { inherit (cfg) policies; };
      };
    };
  }
