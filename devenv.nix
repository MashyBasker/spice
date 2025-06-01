{ pkgs, ... }:

{
  languages.zig.enable = true;

  packages = with pkgs; [
    zls
    pkg-config
    
    # X11 and graphics libraries
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXrender
    libGL
    mesa
    wayland
    libxkbcommon
    alsa-lib
    pulseaudio
    pipewire
  ];

  env = {
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.xorg.libX11
      pkgs.xorg.libXcursor
      pkgs.xorg.libXext
      pkgs.xorg.libXfixes
      pkgs.xorg.libXi
      pkgs.xorg.libXinerama
      pkgs.xorg.libXrandr
      pkgs.xorg.libXrender
      pkgs.libGL
      pkgs.mesa
      pkgs.wayland
      pkgs.libxkbcommon
      pkgs.alsa-lib
      pkgs.pulseaudio
    ];
  };
}