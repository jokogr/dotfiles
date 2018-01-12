{ config, pkgs, ... }:

{
  imports = [ ./home-base.nix ];
  lib.myConfig = (import <nixpkgs/nixos> { system = config.nixpkgs.system; }).config;
}
