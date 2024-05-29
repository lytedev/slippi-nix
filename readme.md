# slippi-nix

This project is a Flake which exposes NixOS modules for ensuring your GameCube
controller adapter is performing as well is it can be and Home Manager modules
for installing and configuring the Slippi Launcher using NixOS-compatible
versions of both the playback and netplay builds of Dolphin (Ishiiruka).

**NOTE**: At this time, this Flake only supports the `x86_64-linux` `system`.

# Usage

The simplest usage is to simply run the netplay package in this Flake:

```shell
nix run github:lytedev/slippi-nix#slippi.netplay
```

However, for the optimal experience, you will want to ensure the host has the
necessary configuration to handle a GameCube controller adapter. Additionally,
you likely want to make use of the Slippi Launcher for managing and viewing
your replays.

Note that this does _not_ support auto-updates. You should be able to fork this
repo and update the versions and hashes in the derivations in `./packages` to
handle any updates very easily, though.

> **TODO**: Show an example of simply overriding the packages attributes' (using
`overrideAttrs`) to do this without forking.

In your flake, you may optionally import the NixOS module for the overclocked
adapter and you must import the Home Manager module for the Slippi Launcher.
Here is an example:

```nix
{
  inputs.slippi.url = "github:lytedev/slippi-nix";
  inputs.nixpkgs.url = "...";

  outputs = {slippi, nixpkgs, ...}: {
    nixosConfigurations = nixpkgs.lib.nixosSystem {
      system = "...";
      modules = [
        slippi.nixosModules.default
        {
          home-manager = {
            # ... snip -- see Home Manager's documentation for details
            users.YOUR_USERNAME = {
              imports = with outputs.homeManagerModules; [
                slippi.homeManagerModules.default
              ];
            };
          };
        }
      ];
    };
  };
}
```

# To Do

It would be nice if Home Manager weren't strictly necessary. At the moment,
I believe the config file _could_ be created via a NixOS module (using
`systemd.tmpfiles.rules` or something?), but the ideal scenario would be to
instead either be to specify to the launcher where the netplay and playback
binaries are without the configuration file -- perhaps via command line
arguments or environment variables.

If this were true, you could simply `nix run 
