{ self }:
{ ... }:
{
  imports = [
    self.homeManagerModules.brave
    self.homeManagerModules.zen-browser
  ];

  nixpkgs.overlays = [ self.overlays.default ];
}
