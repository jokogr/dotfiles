{ config, pkgs, ... }:

let

  sysconfig = config.lib.myConfig;

  desktopEnvironmentApps = with pkgs; [
    copyq
    dunst
    gnome3.zenity
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
    firefox chromium
    keepassx2-http
    libreoffice-fresh
    zathura
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
    pcmanfm
    gvfs
    virtmanager
  ];

  latexPackages = with pkgs; [
    (texlive.combine { inherit (texlive) scheme-basic collection-bibtexextra
    collection-binextra collection-fontsextra collection-fontsrecommended
    collection-langgreek collection-latex collection-latexextra
    collection-latexrecommended collection-metapost collection-publishers
    collection-xetex xindy glossaries;
    })
    biber python3Packages.pygments
  ];

in {

  nixpkgs.config = {
    allowUnfree = true;
  };

  home.sessionVariables = {
    GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules";
  };

  programs.home-manager.enable = true;
  programs.home-manager.path =
    https://github.com/rycee/home-manager/archive/master.tar.gz;

  home.packages = with pkgs; [
    direnv
    exa
    git-crypt
    httpie
    sshfs
    mpd
    ncmpcpp
    ncdu
    nixops
    neomutt
    offlineimap
    pgcli
    python3Packages.yapf
    ranger
    youtube-dl
    wol
  ] ++
    pkgs.lib.optionals sysconfig.custom.hasLaTeX latexPackages ++
    pkgs.lib.optionals sysconfig.services.xserver.enable desktopApps ++
    pkgs.lib.optionals sysconfig.services.xserver.enable
      desktopEnvironmentApps;

}
