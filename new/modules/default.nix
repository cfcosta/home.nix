{ config, ... }:
let
  type = config.dusk-os.type;
  optionalModule = path: if builtins.pathExists path then import path else { };

  importModule =
    module:
    let
      moduleDir = ./${module};
    in
    [
      (optionalModule (moduleDir + (if type == "nixos" then "/nixos.nix" else "/darwin.nix")))
      (optionalModule (moduleDir + "/home.nix"))
      (optionalModule (moduleDir + "/default.nix"))
    ];

  modules = [
    "ai"
    "messaging"
  ];
in
{
  imports = builtins.concatMap importModule modules;
}
