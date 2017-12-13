{ config, pkgs, ... }:

let

  sysconfig = config.lib.myConfig;

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

  lib = let nixos = import <nixpkgs/nixos> { system = config.nixpkgs.system; };
  in { myConfig = nixos.config; };

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
