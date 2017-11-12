{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  programs.home-manager.path = https://github.com/rycee/home-manager/archive/master.tar.gz;

  home.packages = with pkgs; [
    exa
    copyq
    sshfs
    iosevka
    ubuntu_font_family
    mpd
    ncmpcpp
    youtube-dl
    gwenview
    skrooge
  ];
}
