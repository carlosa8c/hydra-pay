# Modern cardano-project build configuration
# Aligned with main Hydra project: https://github.com/cardano-scaling/hydra
# 
# Key changes from old setup:
# - Removed: reflex-platform, Obelisk, GHCJS, iOS/Android support
# - Added: haskell.nix, GHC 9.6.7, CHaP (Cardano Haskell Packages)
# - Focus: Backend-only build for hydra-pay API

{ system ? builtins.currentSystem
, nixpkgs ? import <nixpkgs> {}
}:
let
  # Import haskell.nix for GHC 9.6.7 support
  # TODO: Pin to specific commit hash after testing
  haskellNixSrc = builtins.fetchTarball {
    url = "https://github.com/input-output-hk/haskell.nix/archive/refs/heads/master.tar.gz";
  };
  
  haskellNix = import haskellNixSrc {};
  
  # Use nixpkgs with haskell.nix overlays
  # Note: IOHK crypto overlays (libsodium-vrf, libblst) are now handled by haskell.nix
  nixpkgsArgs = haskellNix.nixpkgsArgs // {
    inherit system;
    overlays = haskellNix.nixpkgsArgs.overlays;
  };
  
  pkgs = import haskellNix.sources.nixpkgs nixpkgsArgs;
  
  lib = pkgs.lib;
  haskellLib = pkgs.haskell.lib;
  
  # Read dependency thunks
  deps = pkgs.thunkSet ./dep;
  cardanoPackageDeps = pkgs.thunkSet ./cardano-overlays/cardano-packages/dep;
  
  # Import Cardano package overlays
  cardanoOverlays = import ./cardano-overlays {
    inherit haskellLib pkgs lib;
  };
  
  # CHaP (Cardano Haskell Packages) repository
  # This is where modern Cardano packages are published
  # TODO: Pin to specific commit after testing
  chap = builtins.fetchTarball {
    url = "https://github.com/IntersectMBO/cardano-haskell-packages/archive/refs/heads/repo.tar.gz";
  };
  
  # Define the project function that creates a haskell.nix project
  # This replaces the old Obelisk project function
  project = rootPath: projectConfig:
    let
      # Extract user configuration
      userConfig = projectConfig { inherit pkgs; };
      
      # Create haskell.nix project with GHC 9.6.7
      # Aligned with main Hydra project configuration
      haskellProject = pkgs.haskell-nix.project {
        # Use GHC 9.6.7 - same as main Hydra project
        # (supports Cabal 3.10+ which can parse cabal-version 3.4)
        compiler-nix-name = "ghc967";
        
        # Project root
        src = pkgs.haskell-nix.haskellLib.cleanGit {
          name = "hydra-pay";
          src = rootPath;
        };
        
        # Use CHaP as additional package repository
        # This provides access to all Cardano packages
        inputMap = {
          "https://intersectmbo.github.io/cardano-haskell-packages" = chap;
        };
        
        # Configure shell tools for development
        shell.tools = {
          cabal = "latest";
          ghcid = "latest";
        };
        
        shell.buildInputs = with pkgs; [
          git
          nix-prefetch-git
          pkg-config
        ];
        
        # Apply package-specific modules/overlays
        modules = [
          # Apply Cardano package overlays from cardano-overlays/
          # The 'combined' overlay contains all Cardano package configurations
          ({config, ...}: {
            packages = lib.mapAttrs (_: v: {}) (cardanoOverlays.combined {} {});
          })
          
          # Apply user-provided package list
          {
            packages = userConfig.packages or {};
          }
          
          # Don't rebuild lib:ghc (it's complex and not needed)
          {
            reinstallableLibGhc = false;
          }
          
          # Apply user-provided overrides
          # Note: haskell.nix uses 'modules' instead of 'overrides'
          # But we'll make the old 'overrides' work via packageOverrides
        ];
      };
    in
    haskellProject;
  
  # Define cardanoProjectDef function for compatibility with existing default.nix
  # This provides the base configuration that can be extended
  cardanoProjectDef = args:
    {
      packages = {};
      overrides = cardanoOverlays.combined;
    };

in
{
  # Export what root default.nix expects
  inherit project cardanoProjectDef lib;
  
  # Export pkgs for access to system packages
  nixpkgs = pkgs;
}
