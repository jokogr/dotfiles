{ config, pkgs, ... }:

let

  sysconfig = config.lib.myConfig;

  desktopEnvironmentApps = with pkgs; [
    copyq
    dunst
    i3lock-fancy
    nitrogen
    rxvt_unicode-with-plugins
    pavucontrol
    polybar
    wmname
    xcape
    xclip
    xmonad-log
    # Fonts
    font-awesome-ttf
    iosevka
    roboto
  ];

  desktopApps = with pkgs; [
    calibre
    gwenview
    siji
    filezilla
    skrooge
    vlc
    (wine.override { wineBuild = "wineWow"; })
    # FIXME add overlays and support them in jobs.nix
    (winetricks.override { wine = wine.override { wineBuild = "wineWow"; }; })
    gnome3.dconf
    gnome3.vinagre
    jetbrains.idea-ultimate
    kdiff3
  ];

in {

  nixpkgs.config = {
    allowUnfree = true;
  };

  programs.home-manager.enable = true;
  programs.home-manager.path =
    https://github.com/rycee/home-manager/archive/master.tar.gz;

  home.packages = with pkgs; [
    direnv
    exa
    httpie
    sshfs
    mpd
    ncmpcpp
    ncdu
    neomutt
    offlineimap
    pgcli
    python3Packages.yapf
    ranger
    youtube-dl
    wol
  ] ++
    pkgs.lib.optionals sysconfig.services.xserver.enable desktopApps ++
    pkgs.lib.optionals sysconfig.services.xserver.enable
       desktopEnvironmentApps;

}
