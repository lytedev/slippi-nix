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

The simplest usage is to run the launcher directly:

```shell
nix run github:lytedev/slippi-nix
```

To avoid potential graphics driver mismatches between the flake's pinned nixpkgs
and your system, override the nixpkgs input to use your own:

```shell
nix run github:lytedev/slippi-nix --override-input nixpkgs nixpkgs
```

This uses the `slippi-launcher-desktop` package, which is a standalone wrapper
that automatically configures Dolphin paths and sets up AppImage symlinks on
each launch. No Home Manager module is required — you can configure your ISO
path and other settings through the launcher UI. Login and other
launcher-managed settings are preserved across rebuilds.

You can also add it to your system packages without Home Manager:

```nix
{
  inputs.slippi.url = "github:lytedev/slippi-nix";
  inputs.slippi.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {slippi, nixpkgs, ...}: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        slippi.nixosModules.default # optional: GameCube adapter support
        {
          environment.systemPackages = [
            slippi.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

## Home Manager Module

For more declarative control over settings, you can use the Home Manager module
instead. This lets you configure the ISO path, replay directories, and other
options via Nix. You will need to specify where your Melee ISO is. Here is an
example:

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

# Packages

| Package | Description |
|---------|-------------|
| `slippi-launcher-desktop` (default) | Standalone launcher with automatic Dolphin/AppImage setup |
| `slippi-launcher` | Base launcher AppImage (no config management, used by the HM module) |
| `slippi-netplay` | Stable netplay Dolphin |
| `slippi-netplay-beta` | Mainline (beta) netplay Dolphin |
| `slippi-playback` | Playback Dolphin |

# License

This project is licensed under the [MIT](./license) license.
