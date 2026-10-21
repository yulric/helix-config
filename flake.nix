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

          # Formats stdin with Prettier. Used as the formatter in languages.toml.
          # Helix runs formatters in the file's directory and passes the file's
          # name. Prefers the project's own Prettier (run from the folder that
          # holds its node_modules, so .prettierignore is found) and falls back
          # to the nixpkgs one. Prettier itself finds the config, including the
          # "prettier" field in package.json.
          prettier-stdin = pkgs.writeShellScriptBin "prettier-stdin" ''
            file="$PWD/$(basename "$1")"
            export PATH="$PATH:${pkgs.nodejs}/bin"
            dir="$PWD"
            while :; do
              if [ -x "$dir/node_modules/.bin/prettier" ]; then
                cd "$dir"
                exec node_modules/.bin/prettier --stdin-filepath "$file"
              fi
              [ "$dir" = / ] && break
              dir="$(dirname "$dir")"
            done
            exec ${pkgs.prettier}/bin/prettier --stdin-filepath "$file"
          '';

          # Language servers and formatters, visible only to hx.
          tools = [
            pkgs.harper
            pkgs.typescript-language-server
            dprint-markdown
            prettier-stdin
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
