# Helix config

My [Helix](https://helix-editor.com) configuration. Nix builds `hx` together
with the language servers and formatters it uses, so Nix is the only thing you
need to install.

## What's here

* `config.toml`: editor settings (theme, ruler, soft wrap, keys).
* `languages.toml`: language servers and formatters for each language.
* `flake.nix`: builds a wrapped `hx` that adds the tools below to its own PATH.
  Nothing else on the system can see them.
* `flake.lock`: pins the nixpkgs version. It is created on the first install.

Tools provided by the flake:

* [harper-ls](https://writewithharper.com): grammar checking for Markdown.
* [typescript-language-server](https://github.com/typescript-language-server/typescript-language-server):
  TypeScript and JavaScript. Helix uses it by default, so it needs no entry in
  `languages.toml`.
* `dprint-markdown`: formats Markdown on save with [dprint](https://dprint.dev).
  It hard wraps at 80 characters and uses `*` for bullets. These settings live
  in `flake.nix`.
* `prettier-stdin`: formats JavaScript, TypeScript, JSON, CSS, SCSS, HTML and
  Vue on save with [Prettier](https://prettier.io). It uses the project's own
  Prettier from `node_modules` if there is one, otherwise the one from nixpkgs.
  Prettier finds the project's config itself, including a `prettier` field in
  `package.json`, and skips files listed in `.prettierignore`.

## Setup

1. Install Nix (multi-user):

   ```sh
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Turn on flakes. Skip this if you used the Determinate Systems installer,
   which turns them on by default.

   ```sh
   mkdir -p ~/.config/nix
   echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
   ```

3. Open a new terminal and install Helix from this folder:

   ```sh
   nix profile install ~/.config/helix
   ```

4. Check it worked:

   ```sh
   which hx                 # should be ~/.nix-profile/bin/hx
   hx --health markdown     # harper-ls and dprint-markdown should be found
   ```

If another `hx` (for example, from apt) comes first on your PATH, remove it with
`sudo apt remove helix`.

## Day-to-day

* **Reload after editing `config.toml` or `languages.toml`:** run
  `:config-reload` in Helix. No rebuild is needed.
* **Apply changes to `flake.nix`** (new tools, formatter settings):

  ```sh
  nix profile upgrade --all
  ```

* **Update Helix and all tools** to the latest nixpkgs:

  ```sh
  nix flake update --flake ~/.config/helix
  nix profile upgrade --all
  ```

* **Save without formatting:** `:write --no-format`.

## Adding a language server or formatter

1. Add its nixpkgs package to the `tools` list in `flake.nix`. Use
   [search.nixos.org](https://search.nixos.org/packages) to find the package
   name.
2. Configure it in `languages.toml` by its command name.
3. Run `nix profile upgrade --all`.

If this folder is ever put under git, `git add` new files before rebuilding.
Flakes in a git repository only see tracked files.

## Troubleshooting

**The Nix installer complains about `/etc/bash.bashrc.backup-before-nix`.** A
previous Nix install was removed but left files behind. The backup is the
original `bash.bashrc`, so restore it rather than deleting it. Also remove
`/etc/zshrc` if it only contains a `# Nix` block:

```sh
sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc
sudo rm /etc/zshrc
```

Then run the installer again.
