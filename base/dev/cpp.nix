{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnumake
    include-what-you-use
    cgal
  ];
}
