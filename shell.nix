{pkgs ? import <nixpkgs-unstable>{}}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    wrangler
    elmPackages.elm
    nodePackages.tailwindcss
    go_1_17
    rustc
  ];
}
