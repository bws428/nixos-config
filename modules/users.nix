{ config, pkgs, ... }:

let
  avatar = ../assets/avatar.jpg;
in
{
  # ── User accounts ──────────────────────────────────────────────────
  users.users.bws428 = {
    isNormalUser = true;
    description = "Brian W.";
    # networkmanager: manage Wi-Fi/VPN without sudo
    # wheel: sudo access
    extraGroups = [ "networkmanager" "wheel" ];
    # Default login shell. Must also be enabled system-wide
    # (programs.zsh.enable in packages.nix).
    shell = pkgs.zsh;
  };

  # ── User avatar (shown on GDM login screen) ───────────────────────
  # AccountsService looks up /var/lib/AccountsService/icons/<user>
  # for the login-screen avatar.
  system.activationScripts.accountsServiceAvatar = ''
    mkdir -p /var/lib/AccountsService/icons
    cp ${avatar} /var/lib/AccountsService/icons/bws428
    chmod 644 /var/lib/AccountsService/icons/bws428

    # AccountsService reads this metadata file to find the icon path
    mkdir -p /var/lib/AccountsService/users
    if [ ! -f /var/lib/AccountsService/users/bws428 ]; then
      cat > /var/lib/AccountsService/users/bws428 <<USEREOF
    [User]
    Icon=/var/lib/AccountsService/icons/bws428
    USEREOF
    else
      # Ensure Icon line exists even if the file was created by the system
      if ! grep -q '^Icon=' /var/lib/AccountsService/users/bws428; then
        echo 'Icon=/var/lib/AccountsService/icons/bws428' >> /var/lib/AccountsService/users/bws428
      fi
    fi
    chmod 644 /var/lib/AccountsService/users/bws428
  '';
}
