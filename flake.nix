{
  description = "hydra-pay modernized build";

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, haskellNix }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ] (system:
      let
        overlays = [ haskellNix.overlay ];
        pkgs = import nixpkgs {
          inherit system overlays;
          inherit (haskellNix) config;
        };
        rootDeps = {
          "bytestring-aeson-orphans" = import ./dep/bytestring-aeson-orphans/thunk.nix;
        };
        cardanoDeps = {
          "aeson-gadt-th" = import ./cardano-project/dep/aeson-gadt-th/thunk.nix;
          "constraints-extras" = import ./cardano-project/dep/constraints-extras/thunk.nix;
          "entropy" = import ./cardano-project/dep/entropy/thunk.nix;
          "haskell-hexstring" = import ./cardano-project/dep/haskell-hexstring/thunk.nix;
          "logging-effect-colors" = import ./cardano-project/dep/logging-effect-colors/thunk.nix;
          "logging-effect-syslog" = import ./cardano-project/dep/logging-effect-syslog/thunk.nix;
          "reflex-gadt-api" = import ./cardano-project/dep/reflex-gadt-api/thunk.nix;
          "vessel" = import ./cardano-project/dep/vessel/thunk.nix;
        };
        rhyoliteSrc = import ./cardano-project/dep/rhyolite/thunk.nix;
        obeliskSrc = import ./dep/obelisk/thunk.nix;
        obeliskProject = import (obeliskSrc + "/default.nix") {
          system = pkgs.stdenv.hostPlatform.system;
        };
        processedStatic = obeliskProject.processAssets { src = ./static; };
        rhyolitePackages = {
          "rhyolite-backend" = rhyoliteSrc + "/backend";
          "rhyolite-beam-db" = rhyoliteSrc + "/beam/db";
          "rhyolite-beam-orphans" = rhyoliteSrc + "/beam/orphans";
          "rhyolite-beam-task-worker-backend" = rhyoliteSrc + "/beam/task/backend";
          "rhyolite-beam-task-worker-types" = rhyoliteSrc + "/beam/task/types";
          "rhyolite-common" = rhyoliteSrc + "/common";
          "rhyolite-email" = rhyoliteSrc + "/email";
          "rhyolite-frontend" = rhyoliteSrc + "/frontend";
          "rhyolite-notify-listen" = rhyoliteSrc + "/notify-listen/notify-listen";
          "rhyolite-notify-listen-beam" = rhyoliteSrc + "/notify-listen/notify-listen-beam";
          "rhyolite-widgets" = rhyoliteSrc + "/widgets";
          "semimap" = rhyoliteSrc + "/semimap";
          "signed-data" = rhyoliteSrc + "/signed-data/signed-data";
          "signed-data-clientsession" = rhyoliteSrc + "/signed-data/signed-data-clientsession";
          "psql-simple-class" = rhyoliteSrc + "/psql-extras/psql-simple-class";
          "psql-simple-beam" = rhyoliteSrc + "/psql-extras/psql-simple-beam";
          "psql-serializable" = rhyoliteSrc + "/psql-extras/psql-serializable";
        };
        obeliskPackages = {
          "obelisk-backend" = obeliskSrc + "/lib/backend";
          "obelisk-frontend" = obeliskSrc + "/lib/frontend";
          "obelisk-route" = obeliskSrc + "/lib/route";
          "obelisk-executable-config-lookup" = obeliskSrc + "/lib/executable-config/lookup";
        };
        sourceOverridePaths =
          {
            "bytestring-aeson-orphans" = rootDeps."bytestring-aeson-orphans";
            "aeson-gadt-th" = cardanoDeps."aeson-gadt-th";
            "constraints-extras" = cardanoDeps."constraints-extras";
            "entropy" = cardanoDeps."entropy";
            "hexstring" = cardanoDeps."haskell-hexstring";
            "logging-effect-colors" = cardanoDeps."logging-effect-colors";
            "logging-effect-syslog" = cardanoDeps."logging-effect-syslog";
            "reflex-gadt-api" = cardanoDeps."reflex-gadt-api";
            "vessel" = cardanoDeps."vessel";
          }
          // rhyolitePackages
          // obeliskPackages;
        cleanedOverrides = pkgs.lib.mapAttrs (_: path: pkgs.lib.cleanSource path) sourceOverridePaths;
        extraPackagesText = let
          overrideLines = pkgs.lib.concatMapStringsSep "" (attr:
            "  -- ${attr.name}\n  ${builtins.toString attr.value}\n"
          ) (pkgs.lib.mapAttrsToList (name: path: { inherit name; value = path; }) cleanedOverrides);
          staticLine = "  -- obelisk-generated-static\n  ${builtins.toString processedStatic.haskellManifest}\n";
        in "packages:\n" + overrideLines + staticLine;
        baseCabalProject = builtins.readFile ./cabal.project;
        moduleConfig = _: {
          source-overrides = cleanedOverrides // {
            "obelisk-generated-static" = processedStatic.haskellManifest;
          };
        };
        project = pkgs.haskell-nix.cabalProject' {
          src = ./.;
          compiler-nix-name = "ghc964";
          pkg-def-extras = [];
          cabalProject = builtins.trace ''generated cabal.project:\n${baseCabalProject}\n${extraPackagesText}\n(package count ${builtins.toString ((builtins.length (pkgs.lib.attrNames cleanedOverrides)) + 1)})'' (baseCabalProject + "\n" + extraPackagesText);
          modules = [ moduleConfig ];
        };
      in {
        packages = {
          default = project.hsPkgs."hydra-pay".components.exes."hydra-pay";
          debug-cabal-project = pkgs.writeText "cabal-project" moduleConfig.cabalProject;
          debug-package-paths = pkgs.writeText "package-paths.json" (
            builtins.toJSON (pkgs.lib.mapAttrs (name: path: builtins.toString path) cleanedOverrides // {
              "obelisk-generated-static" = builtins.toString processedStatic.haskellManifest;
            })
          );
        };
        devShells.default = project.shellFor {
          tools = {
            cabal = "3.12.1.0";
            ghcid.enable = true;
            hlint.enable = true;
          };
        };
      });
}
