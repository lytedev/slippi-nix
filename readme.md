# slippi-nix

[![build status](https://github.com/lytedev/slippi-nix/actions/workflows/build-and-cache.yaml/badge.svg)](https://github.com/lytedev/slippi-nix/actions/workflows/build-and-cache.yaml)

This project is a Flake which exposes NixOS modules for ensuring your GameCube
controller adapter is performing as well is it can be and Home Manager modules
for installing and configuring the Slippi Launcher using NixOS-compatible
versions of both the playback and netplay builds of Dolphin (Ishiiruka).

**NOTE**: At this time, this Flake only supports the `x86_64-linux` `system`
(since it consumes AppImages that support the same). If you are using Linux on
another CPU architecture, please reach out! If you are using macOS, install the
launcher from https://slippi.gg/downloads directly; I don't recommend using Nix
to manage your Slippi installation in that case.

# Usage

The simplest usage is to simply run the netplay package in this Flake:

```shell
nix run github:lytedev/slippi-nix#slippi-netplay
```

However, for the optimal experience, you will want to ensure the host has the
necessary configuration to handle a GameCube controller adapter. Additionally,
you likely want to make use of the Slippi Launcher for managing and viewing
your replays.

In your flake, you may optionally import the NixOS module for the overclocked
adapter and you must import the Home Manager module for the Slippi Launcher. You
will also need to specify where your Melee ISO is. Here is an example:

```nix
{
  inputs.nixpkgs.url = "...";
  inputs.slippi.url = "github:lytedev/slippi-nix";
  inputs.slippi.inputs.nixpkgs.follows = "nixpkgs";

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
                {
                  # use your path
                  slippi-launcher.isoPath = "/home/user/Downloads/melee.iso";
                }
              ];
            };
          };
        }
      ];
    };
  };
}
```

There are other configuration options if you take a look at the flake's source.
Most useful to me is:

```nix
slippi-launcher.launchMeleeOnPlay = false;
```

As I prefer to be able to tweak Dolphin's settings before diving right in.

# Updates

Note that this does _not_ support the auto-updates performed by Slippi Launcher.
Instead, when updates are pushed here, you must update your input reference to
this flake and then your system.

```shell_session
nix flake lock --update-input slippi-nix # use whatever name you gave this flake as input!
sudo nixos-rebuild switch --flake .
```

In the event that this repo is out-of-date and an update was newly pushed out
and you do not want to wait, or you prefer to be in control, this Flake exposes
extra configuration fields for specifying the version of the AppImage you want
along with the hash like so:

```nix
{
  home-manager.users.YOUR_USERNAME = {
    slippi-launcher.netplayVersion = "3.4.0";
    slippi-launcher.netplayHash = "sha256-d1iawMsMwFElUqFmwWAD9rNsDdQr2LKscU8xuJPvxYg=";
    slippi-launcher.netplayBetaVersion = "4.0.0-mainline-beta.6";
    slippi-launcher.netplayBetaHash = "sha256-CicAZ28+yiagG3bjosu02azV6XzP7+JnLhUJ3hdeQbI=";
    slippi-launcher.playbackVersion = "3.4.0";
    slippi-launcher.playbackHash = "sha256-d1iawMsMwFElUqFmwWAD9rNsDdQr2LKscU8xuJPvxYg=";
  };
}
```

So when a Slippi update is released, you can usually bump the version to match
and update the hash with whatever `nix` says it is.

# Beta
You can enable the beta netplay client by adding this to the configuration:
```nix
{
  home-manager.users.YOUR_USERNAME = {
    slippi-launcher.useNetplayBeta = true;
  };
}
```
The beta netplay client is *not* downloaded unless it is enabled. When enabled it is set as the default as well.

# Settings and Login

The Home Manager module creates a mutable settings file at
`~/.config/Slippi Launcher/Settings`. Nix-managed settings (ISO path,
Dolphin paths, etc.) are merged into this file on each Home Manager
activation, but the launcher is free to write to it as well — so login
credentials and any other launcher-managed settings are preserved across
rebuilds.

If you are upgrading from an older version of this module that used a
read-only symlink, the stale symlink will be cleaned up automatically on
the next activation.

# Cache

You may also want to leverage our Cachix binary cache. There isn't _much_
purpose to it since the "build" steps are just unpacking the AppImages and
repacking them in a format that works with Nix, but they graciously provide one
to us freely.

```nix
nixConfig = {
  extra-substituters = ["https://slippi-nix.cachix.org"];
  extra-trusted-public-keys = ["slippi-nix.cachix.org-1:2qnPHiOxTRpzgLEtx6K4kXq/ySDg7zHEJ58J6xNDvBo="];
};
```

# To Do

It would be nice if Home Manager weren't strictly necessary. At the moment,
I believe the config file _could_ be created via a NixOS module (using
`systemd.tmpfiles.rules` or something?), but the ideal scenario would be to
instead either be to specify to the launcher where the netplay and playback
binaries are without the configuration file -- perhaps via command line
arguments or environment variables.

If this were true, you could simply `nix run github:lytedev/slippi-nix#netplay`
and start playing right away, which is ideal!

# License

This project is licensed under the [MIT](./license) license.
