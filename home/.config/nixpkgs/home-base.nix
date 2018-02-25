{ config, pkgs, ... }:

let

  sysconfig = config.lib.myConfig;

  desktopEnvironmentApps = with pkgs; [
    copyq
    dunst
    i3lock-fancy
    nitrogen
    rxvt_unicode-with-plugins
    polybar
    wmname
    xcape
    xclip
    xmonad-log
  ];

  desktopApps = with pkgs; [
    calibre
    gwenview
    font-awesome-ttf
    iosevka
    roboto
    siji
    filezilla
    skrooge
    vlc
    (wine.override { wineBuild = "wineWow"; })
    gnome3.dconf
    gnome3.vinagre
    jetbrains.idea-ultimate
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
  ] ++
    pkgs.lib.optionals sysconfig.services.xserver.enable desktopApps ++
    pkgs.lib.optionals sysconfig.services.xserver.enable
       desktopEnvironmentApps;

}
