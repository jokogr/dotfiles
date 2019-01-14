{ config, pkgs, ... }:

let

  sysconfig = config.lib.myConfig;

  cliTools = with pkgs; [
    direnv
    exa
    jq
    httpie
    fd
    bat
  ];

  desktopEnvironmentApps = with pkgs; [
    copyq
    dunst
    gnome3.zenity
    i3lock-fancy
    kitty
    libnotify
    nitrogen
    rxvt_unicode-with-plugins
    pavucontrol
    polybar
    wmname
    xcape
    xclip
    xmonad-log
    xdotool
    # Fonts
    font-awesome-ttf
    (iosevka.override { design = [ "term" "ss08" ]; set = "term-ss08"; })
    roboto
    signal-desktop
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        ms-vscode.cpptools
        ms-python.python
      ];
    })
    (python37.withPackages (ps: with ps; [ pylint rope ]))
  ] ++ [ # KDE themes
    libsForQt5.qtstyleplugin-kvantum
    adapta-kde-theme
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
    (wine.override { wineBuild = "wineWow"; netapiSupport = true; })
    # FIXME add overlays and support them in jobs.nix
    (winetricks.override { wine = wine.override { wineBuild = "wineWow"; netapiSupport = true;}; })
    gnome3.dconf
    gnome3.vinagre
    jetbrains.idea-ultimate
    kdiff3
    pcmanfm
    gvfs
    virtmanager
    cura
    xorg.xhost
  ];

  latexPackages = with pkgs; [
    (texlive.combine { inherit (texlive) scheme-basic collection-bibtexextra
    collection-binextra collection-fontsextra collection-fontsrecommended
    collection-langgreek collection-latex collection-latexextra
    collection-latexrecommended collection-metapost collection-publishers
    collection-xetex xindy glossaries;
    })
    python3Packages.pygments
  ];

  debuggingTools = with pkgs; [
    gdb
    pwndbg
    radare2
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
    ansible
    ansible-lint
    docker-compose
    kubectl
    kubernetes-helm
    git-crypt
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
  ] ++ cliTools ++ debuggingTools ++
    pkgs.lib.optionals sysconfig.custom.hasLaTeX latexPackages ++
    pkgs.lib.optionals sysconfig.services.xserver.enable desktopApps ++
    pkgs.lib.optionals sysconfig.services.xserver.enable
      desktopEnvironmentApps;

  gtk = pkgs.lib.mkIf sysconfig.services.xserver.enable {
    enable = true;
    font.name = "Roboto 11";
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    theme = {
      package = pkgs.adapta-gtk-theme;
      name = "Adapta-Nokto-Eta";
    };
    gtk2.extraConfig = ''
      gtk-cursor-theme-name = breeze_cursors
    '';
    gtk3.extraConfig = {
      gtk-cursor-theme-name = "breeze_cursors";
    };
  };

  home.extraProfileCommands = ''
    if [[ -d "$out/share/applications" ]] ; then
      ${pkgs.desktop-file-utils}/bin/update-desktop-database $out/share/applications
    fi
  '';
}
