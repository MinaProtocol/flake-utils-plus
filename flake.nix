{
  description = "Pure Nix flake utility functions";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils }:
    let
      removeSuffix = suffix: str:
        let
          sufLen = builtins.stringLength suffix;
          sLen = builtins.stringLength str;
        in
        if sufLen <= sLen && suffix == builtins.substring (sLen - sufLen) sufLen str then
          builtins.substring 0 (sLen - sufLen) str
        else
          str;

      genAttrs' = func: values: builtins.listToAttrs (map func values);
    in
    rec {

      nixosModules.saneFlakeDefaults = import ./modules/saneFlakeDefaults.nix;

      lib = flake-utils.lib // {

        repl = ./repl.nix;
        systemFlake = import ./systemFlake.nix { flake-utils-plus = self; };

        modulesFromList = paths: genAttrs'
          (path: {
            name = removeSuffix ".nix" (baseNameOf path);
            value = import path;
          })
          paths;

        patchChannel = system: channel: patches:
          if patches == [ ] then channel else
          (import channel { inherit system; }).pkgs.applyPatches {
            name = "nixpkgs-patched-${channel.shortRev}";
            src = channel;
            patches = patches;
          };

      };
    };
}


