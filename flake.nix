{
  description = "Helix with its language servers and formatters";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          dprintConfig = pkgs.writeText "dprint.json" (
            builtins.toJSON {
              markdown = {
                lineWidth = 80;
                textWrap = "always";
                unorderedListKind = "asterisks";
              };
              plugins = pkgs.dprint-plugins.getPluginList (p: [ p.dprint-plugin-markdown ]);
            }
          );

          # Formats Markdown on stdin. Used as the formatter in languages.toml.
          dprint-markdown = pkgs.writeShellScriptBin "dprint-markdown" ''
            exec ${pkgs.dprint}/bin/dprint fmt --config ${dprintConfig} --stdin md
          '';

          # Language servers and formatters, visible only to hx.
          tools = [
            pkgs.harper
            dprint-markdown
          ];
        in
        {
          default = pkgs.symlinkJoin {
            name = "helix-with-tools";
            paths = [ pkgs.helix ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/hx --prefix PATH : ${pkgs.lib.makeBinPath tools}
            '';
            meta.mainProgram = "hx";
          };
        }
      );
    };
}
