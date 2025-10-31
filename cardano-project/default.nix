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
  
  # Fetch libblst source (required for cardano-crypto-class)
  # Version 0.3.14 as used in iohk-nix
  blstSrc = builtins.fetchTarball {
    url = "https://github.com/supranational/blst/archive/refs/tags/v0.3.14.tar.gz";
    sha256 = "1dp1bl8f6s1s41dp44dv1jmvggr0j2spa74839pzgcv3n0qcsmi2";
  };
  
  # Fetch libsodium-vrf source (required for cardano-crypto)
  sodiumSrc = builtins.fetchTarball {
    url = "https://github.com/input-output-hk/libsodium/archive/dbb48cce5429cb6585c9034f002568964f1ce567.tar.gz";
    sha256 = "1rppbdq2x29mkias9wk225wadwqv59x65m9562xh6crgk0vmrr6j";
  };
  
  # Use nixpkgs with haskell.nix and crypto overlays
  nixpkgsArgs = haskellNix.nixpkgsArgs // {
    inherit system;
    overlays = haskellNix.nixpkgsArgs.overlays ++ [
      # CRITICAL: Crypto libraries overlay for libblst and libsodium-vrf
      # Based on iohk-nix's crypto overlay but simplified for non-flake use
      # cardano-crypto-class requires libblst for BLS12_381 support
      (final: prev: {
        # Build libblst from source
        libblst = final.callPackage ({ stdenv, lib, fetchurl }:
          stdenv.mkDerivation rec {
            pname = "libblst";
            version = "0.3.14";
            
            src = blstSrc;
            
            buildPhase = ''
              ./build.sh
            '';
            
            installPhase = ''
              mkdir -p $out/lib $out/include $out/lib/pkgconfig
              cp libblst.a $out/lib/
              cp bindings/*.h $out/include/
              
              # Create pkg-config file for Cabal
              cat > $out/lib/pkgconfig/libblst.pc << EOF
prefix=$out
exec_prefix=\''${prefix}
libdir=\''${exec_prefix}/lib
includedir=\''${prefix}/include

Name: libblst
Description: BLS12-381 signature library  
Version: ${version}
Libs: -L\''${libdir} -lblst
Cflags: -I\''${includedir}
EOF
            '';
            
            meta = with lib; {
              description = "BLS12-381 signature library";
              homepage = "https://github.com/supranational/blst";
              license = licenses.asl20;
            };
          }) {};
          
        # Build libsodium-vrf from source
        libsodium-vrf = final.callPackage ({ stdenv, lib, autoreconfHook }:
          stdenv.mkDerivation rec {
            pname = "libsodium-vrf";
            version = "66f017f1";
            
            src = sodiumSrc;
            
            nativeBuildInputs = [ autoreconfHook ];
            
            configureFlags = [
              "--enable-static"
              "--disable-shared"
            ];
            
            meta = with lib; {
              description = "Libsodium fork with VRF support";
              homepage = "https://github.com/input-output-hk/libsodium";
              license = licenses.isc;
            };
          }) {};
      })
      
      # CRITICAL: haskell.nix pkg-config mappings for crypto libraries
      # This makes libblst visible to Cabal's dependency solver
      (final: prev: {
        haskell-nix = prev.haskell-nix // {
          extraPkgconfigMappings = prev.haskell-nix.extraPkgconfigMappings or {} // {
            "libblst" = [ "libblst" ];
            "libsodium" = [ "libsodium-vrf" ];
          };
        };
      })
    ];
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
          # Using latest packages from CHaP (Sep 2024) - no overrides needed for:
          # - ouroboros-network ecosystem (0.23.0.0, 0.17.0.0, 0.20.0.0, 0.16.0.0)
          # - io-sim packages (io-classes, io-sim, strict-stm, strict-mvar, si-timers)
          # - typed-protocols packages (typed-protocols, typed-protocols-cborg)
          # All work with GHC 9.6.7 and contra-tracer 0.2.0+ without patches
          
          {
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
            
            # Using latest ouroboros-network ecosystem from CHaP (all from Sep 10, 2024):
            # - ouroboros-network-0.23.0.0
            # - ouroboros-network-api-0.17.0.0  
            # - ouroboros-network-framework-0.20.0.0
            # - ouroboros-network-protocols-0.16.0.0
            # - network-mux-0.9.0.0
            # These versions are compatible with each other and with GHC 9.6.7
            # No patches needed - they already support contra-tracer 0.2.0+ API
            
            # CRITICAL: Patch network-mux-0.9.0.0 for GHC 9.6.7 + contra-tracer 0.2
            # contramapTracers' needs Monad m constraint for stricter type checking
            # GHC 9.6.7 requires explicit Monad constraint where it's used with >$<
            # Use arrow (emit go) for contra-tracer 0.2 TracerA compatibility
            packages.network-mux.patches = [ ./patches/network-mux-ghc96-monad-constraint.patch ];
            
            # CRITICAL: Patch ouroboros-network-testing for contra-tracer 0.2
            # Remove contramapM import - function no longer exists in contra-tracer 0.2
            packages.ouroboros-network-testing.patches = [ ./patches/ouroboros-network-testing-remove-contramapM.patch ];

            # CRITICAL: Patch ouroboros-network-framework for contra-tracer 0.2
            # 1. Provide local contramapM helper matching new Arrow-based Tracer API
            # 2. Add Monad m constraint to showTracing (contramap requires Monad)
            # 3. Add Monad m constraint to Data.Cache functions (traceWith requires Monad)
            # 4. Fix InboundGovernor Tracer construction for Arrow-based API (split into 2 patches)
            # 5. Import stdoutTracer for showTracing usage in Socket.hs
            packages.ouroboros-network-framework.patches = [
              ./patches/ouroboros-network-framework-contramapM.patch
              ./patches/ouroboros-network-framework-showtracing.patch
              ./patches/ouroboros-network-framework-socket-import.patch
              ./patches/ouroboros-network-framework-cache-monad.patch
              ./patches/ouroboros-network-framework-inbound-governor-tracer.patch
              ./patches/ouroboros-network-framework-inbound-governor-tracer-part2.patch
            ];
            
            # CRITICAL: Patch ouroboros-network for contra-tracer 0.2
            # 1. Fix PeerMetric Tracer constructions for Arrow-based API
            # 2. Fix Diffusion.Types nullTracers - needs Monad m (not Applicative m)
            packages.ouroboros-network.patches = [
              ./patches/ouroboros-network-peermetric-tracer.patch
              ./patches/ouroboros-network-diffusion-types-monad.patch
            ];
            
            # CRITICAL: Patch kes-agent for syntax error and Monad constraints and contra-tracer 0.2
            # 1. error function call was malformed - separate traceWith from error
            # 2. Add Monad m constraints to agentTrace and agentCRefTracer
            # 3. Fix Agent.hs Tracer construction for Arrow-based API (import emit, add emit wrapper)
            packages.kes-agent.patches = [
              ./patches/kes-agent-control-client-error.patch
              ./patches/kes-agent-common-actions-monad.patch
              ./patches/kes-agent-agent-import.patch
              ./patches/kes-agent-agent-tracer-emit.patch
            ];
            
            # CRITICAL: Patch plutus-core for nothunks-0.2
            # ThunkInfo constructor signature changed: now takes Maybe Info as second argument
            # Remove CPP conditional and use correct signature: ThunkInfo ctx Nothing
            packages.plutus-core.patches = [ ./patches/plutus-core-runtime-thunkinfo.patch ];
            
            # CRITICAL: Patch cardano-ledger-core for GHC 9.6.7 compatibility
            # 1. UniformRange Language/CertIx instances fail with GUniformRange derivation error
            # 2. Random instances depend on UniformRange, causing cascading failures  
            # 3. MemoBytes Unpack kind mismatch - needs explicit monad type parameter
            # Comment out test-only instances - not used in production
            packages.cardano-ledger-core.patches = [ 
              ./patches/cardano-ledger-core-uniformrange.patch 
              ./patches/cardano-ledger-core-random-instances.patch
              ./patches/cardano-ledger-core-memobytes-kind.patch
            ];
            
            # CRITICAL: Patch cardano-ledger-allegra for GHC 9.6.7
            # mempack Unpack type changed from `Unpack b a` to `Unpack m b a`
            # Must add explicit type signature to unpackM method in MemPack instance
            packages.cardano-ledger-allegra.patches = [
              ./patches/cardano-ledger-allegra-mempack-unpack.patch
            ];
            
            # CRITICAL: Patch ouroboros-consensus 0.28.0.0 for GHC 9.6.7
            # This version is compatible with cardano-ledger-core 1.18 (rest of ecosystem)
            # Patches fix: 1) Monad constraint  2) mempack Unpack kind signature
            packages.ouroboros-consensus.patches = [
              ./patches/ouroboros-consensus-enclose-monad.patch
              ./patches/ouroboros-consensus-indexedmempack-kind.patch
            ];
            
            # CRITICAL: Patch postgresql-lo-stream for GHC 9.6
            # Missing imports: Control.Monad (when, <=<) and Data.Function (fix)
            # GHC 9.6 removed these from Prelude
            packages.postgresql-lo-stream.patches = [ ./patches/postgresql-lo-stream-ghc96.patch ];
            
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
