{
  description = "Zig code example to use shared memory among processes";

  inputs.nixpkgs.url = "github:pseudocc/nixpkgs/zig-0.15.1";

  outputs = { self, nixpkgs }: import ./nix/each-system.nix nixpkgs (
    system: pkgs: {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          zig
          zls
        ];
      };
    }
  );
}
