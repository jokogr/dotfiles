{ config, pkgs, ... }:

let

  sysconfig = config.lib.myConfig;

  cliTools = with pkgs; [
    direnv
    exa
    gitAndTools.hub
    gitAndTools.tig
    jq
    neovim
    httpie
    fd
    bat
  ];

  devopsTools = with pkgs; [
    ansible
    ansible-lint
    docker-compose
    google-cloud-sdk
    kubectl
    kubernetes-helm
    packer
    sops
    vault
  ];

  desktopEnvironmentApps = with pkgs; [
    copyq
    dunst
    gnome3.zenity
    i3lock-fancy
    kdeApplications.spectacle
    kitty
    libnotify
    mattermost-desktop
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
        vscodevim.vim
      ];
    })
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

  nixpkgs.config = import ./nixpkgs-config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;

  nixpkgs.overlays = import ./nixpkgs-overlays.nix;
  xdg.configFile."nixpkgs/overlays.nix".source = ./nixpkgs-overlays.nix;

  home.sessionVariables = {
    GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules";
  };

  programs.home-manager.enable = true;
  programs.home-manager.path =
    https://github.com/rycee/home-manager/archive/master.tar.gz;

  home.packages = with pkgs; [
    git-crypt
    sshfs
    mpd
    ncmpcpp
    ncdu
    nixops
    neomutt
    offlineimap
    pgcli
    (python37.withPackages (ps: with ps; [ pylint python-language-server rope yapf ]))
    ranger
    youtube-dl
    wol
  ] ++ cliTools ++ debuggingTools ++ devopsTools ++
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

  home.stateVersion = "18.09";
}
