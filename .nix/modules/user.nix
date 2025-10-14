{ config, pkgs, ... }:
{
  users.users.eyouga = {
    name = "eyouga";
    description = "Lucien Thany--Eynard";
    isNormalUser = true;
    shell = pkgs.zsh;
    initialPassword = "aaa";
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJICpMMXQyNXOwaYKCEBIGvtgkVIZv9teE8DbwECVz6Y"
    ];
  };
}
