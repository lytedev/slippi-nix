{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.gamecube-controller-adapter;
in {
  # defaults here are true since we assume if you're importing the module, you
  # want it on ;)
  options.gamecube-controller-adapter = {
    enable = mkEnableOption "Enable the optimal gamecube controller adapter experience." // {default = true;};

    overclocking-kernel-module.enable = mkEnableOption "Turn on gamecube controller adapter overclocking kernel module." // {default = true;};

    udev-rules.enable = mkEnableOption "Turn on udev rules for your gamecube controller adapter." // {default = true;};
    udev-rules.rules = mkOption {
      default = ''
        ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="666", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device" TAG+="uaccess"
      '';
      type = types.lines;
      description = "To be appended to services.udev.extraRules if gcc.rules.enable is set.";
    };
  };

  config = {
    gamecube-controller-adapter.udev-rules.enable = mkIf cfg.enable true;
    gamecube-controller-adapter.overclocking-kernel-module.enable = mkIf cfg.enable true;

    services.udev.extraRules = mkIf cfg.udev-rules.enable cfg.udev-rules.rules;

    boot.extraModulePackages = mkIf cfg.overclocking-kernel-module.enable [
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/gcadapter-oc-kmod/default.nix
      config.boot.kernelPackages.gcadapter-oc-kmod
    ];
    boot.kernelModules = mkIf cfg.overclocking-kernel-module.enable [
      "gcadapter_oc"
    ];
  };
}
