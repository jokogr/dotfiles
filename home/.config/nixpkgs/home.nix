{ pkgs, ... }:

let

  sysconfig = (import <nixpkgs/nixos> {}).config;

  desktopApps = with pkgs; [
    calibre
    copyq
    gwenview
    iosevka
    roboto
    filezilla
    skrooge
    vlc
  ];

in {

  programs.home-manager.enable = true;
  programs.home-manager.path = https://github.com/rycee/home-manager/archive/master.tar.gz;

  home.packages = with pkgs; [
    exa
    httpie
    sshfs
    mpd
    ncmpcpp
    ncdu
    ranger
    youtube-dl
  ] ++ pkgs.lib.optionals sysconfig.services.xserver.enable desktopApps;

}
