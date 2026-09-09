{
  description = "ESP-IDF development environment for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Community repo providing pre-built ESP-IDF toolchains and environments
    esp-dev = {
      url = "github:mirrexagon/nixpkgs-esp-dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, esp-dev }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Apply the ESP-IDF overlay to nixpkgs
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ esp-dev.overlays.default ];
        };

        # Choose your ESP-IDF version here (e.g., esp-idf-full, esp-idf-esp32, etc.)
        # 'esp-idf-full' includes toolchains for esp32, esp32s2, esp32s3, esp32c3, etc.
        espIdf = pkgs.esp-idf-full;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "esp-idf-env";

          buildInputs = with pkgs; [
            espIdf

            # Essential build tools
            cmake
            ninja
            gcc
            git

            # Python environment managed by Nix
            python3
            python3Packages.pip
            python3Packages.virtualenv

            # Serial communication & flashing tools
            esptool
            minicom # or screen / picocom

            # Needed for USB serial permissions/rules
            libusb1
            pkg-config
          ];

          shellHook = ''
            # Source the ESP-IDF export script automatically when entering the shell
            # This sets up $IDF_PATH and modifies your PATH for xtensa tools
            source ${espIdf}/export.sh

            echo "========================================================="
            echo " Welcome to the ESP-IDF Development Shell (NixOS)        "
            echo " Target Toolchains: ESP32, ESP32-S, ESP32-C              "
            echo "========================================================="
            echo "Run 'idf.py build' to compile your project."
          '';
        };
      });
}
