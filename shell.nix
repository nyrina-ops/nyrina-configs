{ pkgs }:

with pkgs; mkShell {
  name = "deploy-env";
  buildInputs = [
    colmena
    sops
  ];
}