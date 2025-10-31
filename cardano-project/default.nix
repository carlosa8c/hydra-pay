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
  
  # Define thunkSet function to load git thunks (replaces reflex-platform thunkSet)
  # Each thunk directory should contain a github.json with rev and sha256
  thunkSet = dir: lib.mapAttrs (name: _:
    let thunkData = builtins.fromJSON (builtins.readFile (dir + "/${name}/github.json"));
    in pkgs.fetchFromGitHub {
      owner = thunkData.owner or (throw "thunk ${name} missing owner");
      repo = thunkData.repo or (throw "thunk ${name} missing repo");
      rev = thunkData.rev;
      sha256 = thunkData.sha256;
    }
  ) (builtins.readDir dir);
  
  # Read dependency thunks
  deps = thunkSet ./dep;
  cardanoPackageDeps = thunkSet ./cardano-overlays/cardano-packages/dep;
  topLevelDeps = thunkSet ../dep;  # For packages in workspace root /dep/
  
  # Import Cardano package overlays
  cardanoOverlays = import ./cardano-overlays {
    inherit haskellLib pkgs lib deps cardanoPackageDeps topLevelDeps;
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
          # Note: io-sim packages (io-classes, io-sim, strict-stm, strict-mvar, si-timers)
          # and typed-protocols packages (typed-protocols, typed-protocols-cborg)
          # are now defined in cabal.project as source-repository-package.
          # This overrides CHaP without conflicting with haskell.nix modules.
          
          # Disable tests for io-sim packages (they require extra test dependencies)
          {
            packages.io-classes.doCheck = false;
            packages.io-sim.doCheck = false;
            packages.strict-stm.doCheck = false;
            packages.strict-mvar.doCheck = false;
            packages.si-timers.doCheck = false;
            
            # Disable tests for typed-protocols packages
            packages.typed-protocols.doCheck = false;
            packages.typed-protocols-cborg.doCheck = false;
            
            # Skip quickcheck-instances - it will fail due to duplicate instances with QuickCheck 2.17.1.0
            # But packages should work without it (allow-newer in cabal.project)
            packages.quickcheck-instances.doHaddock = false;
            packages.quickcheck-instances.doCheck = false;
            packages.quickcheck-instances.ghcOptions = ["-Wwarn" "-Wno-error"];
            
            # CRITICAL: Override hexstring to use our thunk with base16-bytestring >1 support
            # This must be done here because CHaP provides hexstring-0.11.1 which is incompatible
            packages.hexstring.src = pkgs.haskell-nix.haskellLib.cleanGit {
              name = "hexstring";
              src = deps.haskell-hexstring;
            };
            packages.hexstring.doCheck = false;
            
            # CRITICAL: Override reflex to use v0.9.4.0 for GHC 9.6 compatibility
            # reflex 0.8.x has missing Data.Witherable imports and Data.Semigroup.Option issues
            # reflex 0.9.0.1+ adds GHC 9.6 support, 0.9.4.0 is latest stable
            # Use lib.mkForce because reflex is already in the plan from cabal.project
            packages.reflex.src = pkgs.lib.mkForce (pkgs.haskell-nix.haskellLib.cleanGit {
              name = "reflex";
              src = topLevelDeps.reflex;
            });
            packages.reflex.doCheck = false;
            
            # CRITICAL: Constrain microlens to < 0.5
            # cardano-prelude-0.2.1.0 requires microlens < 0.5 because Field3/Field4/Field5
            # were moved to microlens-th in 0.5.0
            # But haskell.nix is picking 0.5.0.0 which breaks the build
            packages.cardano-prelude.components.library.doExactConfig = true;
            
            # CRITICAL: Patch postgresql-lo-stream for GHC 9.6
            # Missing imports: Control.Monad (when, <=<) and Data.Function (fix)
            # GHC 9.6 removed these from Prelude
            packages.postgresql-lo-stream.patches = [ ./patches/postgresql-lo-stream-ghc96.patch ];
            
            # CRITICAL: Patch network-mux for GHC 9.6
            # Missing Monad m constraint in traceBearerState function
            # contra-tracer 0.2.0 API change: use arrow/emit instead of Tracer constructor
            packages.network-mux.patches = [ ./patches/network-mux-ghc96.patch ];
            
            # CRITICAL: Patch ouroboros-network-testing for GHC 9.6
            # contra-tracer 0.2.0 removed contramapM function
            # Define it locally using arrow API
            packages.ouroboros-network-testing.patches = [ ./patches/ouroboros-network-testing-ghc96.patch ];
            
                        # CRITICAL: Patch ouroboros-network-framework for GHC 9.6
            # contra-tracer 0.2.0 removed showTracing and nullTracer/stdoutTracer
            packages.ouroboros-network-framework.patches = [
              ./patches/ouroboros-network-framework-contramapM-ghc96.patch
              ./patches/ouroboros-network-framework-connect-null-ghc96.patch
              ./patches/ouroboros-network-framework-connect-debug-ghc96.patch
              ./patches/ouroboros-network-framework-server-null-ghc96.patch
              ./patches/ouroboros-network-framework-server-debug-ghc96.patch
            ];
            
            # CRITICAL: Patch rhyolite-beam-task-worker-backend for GHC 9.6
            # void needs explicit import from Control.Monad
            packages.rhyolite-beam-task-worker-backend.patches = [ ./patches/rhyolite-beam-task-worker-backend-ghc96.patch ];
            
            # CRITICAL: Patch beam-automigrate for GHC 9.6
            # guard and lift need explicit imports
            packages.beam-automigrate.patches = [ ./patches/beam-automigrate-ghc96.patch ];
          }
          
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
