{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.plex;
  plex = pkgs.plex;
in
{
  options = {
    services.plex = {
      enable = mkEnableOption "Plex Media Server";

      # FIXME: In order for this config option to work, symlinks in the Plex
      # package in the Nix store have to be changed to point to this directory.
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/plex";
        description = "The directory where Plex stores its data files.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Open ports in the firewall for the media server
        '';
      };

      user = mkOption {
        type = types.str;
        default = "plex";
        description = "User account under which Plex runs.";
      };

      group = mkOption {
        type = types.str;
        default = "plex";
        description = "Group under which Plex runs.";
      };


      managePlugins = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If set to true, this option will cause all of the symlinks in Plex's
          plugin directory to be removed and symlinks for paths specified in
          <option>extraPlugins</option> to be added.
        '';
      };

      extraPlugins = mkOption {
        type = types.listOf types.path;
        default = [];
        description = ''
          A list of paths to extra plugin bundles to install in Plex's plugin
          directory. Every time the systemd unit for Plex starts up, all of the
          symlinks in Plex's plugin directory will be cleared and this module
          will symlink all of the paths specified here to that directory. If
          this behavior is undesired, set <option>managePlugins</option> to
          false.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.plex;
        defaultText = "pkgs.plex";
        description = ''
          The Plex package to use. Plex subscribers may wish to use their own
          package here, pointing to subscriber-only server versions.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Most of this is just copied from the RPM package's systemd service file.
    systemd.services.plex = {
      description = "Plex Media Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/plexmediaserver";
        KillSignal = "SIGQUIT";
        Restart = "on-failure";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 32400 3005 8324 32469 ];
      allowedUDPPorts = [ 1900 5353 32410 32412 32413 32414 ];
    };

    users.extraUsers = mkIf (cfg.user == "plex") {
      plex = {
        group = cfg.group;
        uid = config.ids.uids.plex;
      };
    };

    users.extraGroups = mkIf (cfg.group == "plex") {
      plex = {
        gid = config.ids.gids.plex;
      };
    };
  };
}
