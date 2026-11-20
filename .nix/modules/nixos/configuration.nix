{
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../configuration.nix
    ./locale.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  services.fwupd.enable = true;

  hardware.graphics.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    # Key or nothing. PasswordAuthentication alone leaves keyboard-interactive
    # (another way to type a password, through PAM) on, as NixOS defaults it;
    # AuthenticationMethods makes sshd itself refuse anything else.
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      AllowUsers = [ "eyouga" ];
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "no";
    };
  };

  users.users.eyouga = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

}
