{ self }:
{ ... }:
{
  imports = [
    self.nixosModules.brave
    self.nixosModules.zen-browser
  ];

  nixpkgs.overlays = [ self.overlays.default ];
}
