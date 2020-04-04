{ config, pkgs, lib, ... }:

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
    openssl
    parallel
    pass
  ];

  devopsTools = with pkgs; [
    ansible
    ansible-lint
    cntr
    docker-compose
    google-cloud-sdk
    kubectl
    kubectx
    kubernetes-helm
    packer
    sops
    vault
  ];

  desktopApps = with pkgs; [
    calibre
    chromium
    cura
    filezilla
    firefox
    gnome3.dconf
    gnome3.vinagre
    gwenview
    gvfs
    jetbrains.idea-community
    kdeApplications.spectacle
    kdiff3
    keepassx2-http
    libreoffice-fresh
    okular
    pavucontrol
    pcmanfm
    signal-desktop
    siji
    skrooge
    virtmanager
    vlc
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        ms-vscode.cpptools
        ms-python.python
        vscodevim.vim
      ];
    })
    (wine.override { wineBuild = "wineWow"; netapiSupport = true; })
    # FIXME add overlays and support them in jobs.nix
    (winetricks.override { wine = wine.override { wineBuild = "wineWow"; netapiSupport = true;}; })
    xorg.xhost
    yubioath-desktop
    zathura
  ];

  fontPackages = with pkgs; [
    font-awesome-ttf
    (iosevka.override { privateBuildPlan = { family = "Iosevka Term"; design = [ "term" "ss08" ]; }; set = "term-ss08"; })
    roboto
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

  imports = let
    modulePath = "/home/joko/.config/nixpkgs/modules";
    moduleDirContents = if builtins.pathExists modulePath
    then builtins.readDir modulePath else {};
    filteredModuleDirContents =
      lib.filterAttrs (n: v: v == "file" ||  v == "symlink") moduleDirContents;
    nixFiles = builtins.attrNames filteredModuleDirContents;
  in if builtins.pathExists modulePath
     then map (nixFile: "${modulePath}/${nixFile}") nixFiles
     else [
       <dotfiles/home/.config/nixpkgs/modules/lorri.nix>
       <dotfiles-sway/home/.config/nixpkgs/modules/sway.nix>
       <dotfiles-x11/home/.config/nixpkgs/modules/x11.nix>
     ];

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
    pkgs.lib.optionals sysconfig.custom.gui.enable desktopApps ++
    pkgs.lib.optionals sysconfig.custom.gui.enable fontPackages;

  gtk = pkgs.lib.mkIf sysconfig.custom.gui.enable {
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

  xdg.mimeApps = pkgs.lib.mkIf sysconfig.custom.gui.enable {
    enable = true;
    associations.added = {
      "inode/directory" = [ "org.kde.gwenview.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/chrome" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
    defaultApplications = {
      "application/pdf" = [ "org.kde.okular.desktop" ];
      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "inode/directory" = [ "pcmanfm.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/chrome" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
  };

  home.extraProfileCommands = ''
    if [[ -d "$out/share/applications" ]] ; then
      ${pkgs.desktop-file-utils}/bin/update-desktop-database $out/share/applications
    fi
  '';

  home.stateVersion = "18.09";

}
