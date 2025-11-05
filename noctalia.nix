{ pkgs, inputs, ... }:
{
  # install package
  environment.systemPackages = with pkgs; [
    inputs.quickshell.packages.${system}.default
    inputs.noctalia.packages.${system}.default
    # ... maybe other stuff
  ];
}
