{ config, pkgs, ... }:

let

  sysconfig = config.lib.myConfig;

  desktopApps = with pkgs; [
    calibre
    copyq
    polybar
    gwenview
    font-awesome-ttf
    iosevka
    roboto
    siji
    filezilla
    skrooge
    vlc
    gnome3.dconf
    gnome3.vinagre
    jetbrains.idea-ultimate
  ];

in {

  programs.home-manager.enable = true;
  programs.home-manager.path = https://github.com/rycee/home-manager/archive/master.tar.gz;

  home.packages = with pkgs; [
    direnv
    exa
    httpie
    sshfs
    mpd
    ncmpcpp
    ncdu
    neomutt
    pgcli
    python3Packages.yapf
    ranger
    youtube-dl
  ] ++ pkgs.lib.optionals sysconfig.services.xserver.enable desktopApps;

}
