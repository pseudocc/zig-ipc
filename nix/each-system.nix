nixpkgs: fn: let
  lib = nixpkgs.lib;
in
  lib.foldl' (
    acc: system:
      lib.recursiveUpdate
      acc
      (lib.mapAttrs (_: value: {${system} = value;}) (
        fn system (import nixpkgs { inherit system; })
      ))
  ) {}
  lib.platforms.linux
