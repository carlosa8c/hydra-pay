{ haskellLib, lib, pkgs, deps, cardanoPackageDeps, topLevelDeps
, ...
}:

let
  # Thunks are now passed from parent context:
  # - deps: cardano-project/dep/ (contains haskell-hexstring, etc.)
  # - cardanoPackageDeps: cardano-overlays/cardano-packages/dep/ (contains io-sim, typed-protocols, etc.)
  # - topLevelDeps: workspace root /dep/ (contains aeson, cardano-node, hydra, etc.)
  
  cardanoBaseSrc = cardanoPackageDeps.cardano-base;
in self: super: {
  # Fix broken libpq: use postgresql-libpq instead
  # Old libpq-0.4.1 is marked as broken in nixpkgs
  libpq = super.postgresql-libpq;
  
  # Fix broken bytestring-trie: use newer version that supports base-4.14+
  # bytestring-trie-0.2.5.0 in nixpkgs is outdated and marked broken
  # Version 0.2.7.6 supports base >=4.9 && <4.22 (works with GHC 8.10.7)
  # Using fetchzip because it's too new for all-cabal-hashes (released Feb 2025)
  # COMMENTED OUT: haskell.nix module system doesn't know about this package yet
  # bytestring-trie = self.callCabal2nix "bytestring-trie" (pkgs.fetchzip {
  #   url = "https://hackage.haskell.org/package/bytestring-trie-0.2.7.6/bytestring-trie-0.2.7.6.tar.gz";
  #   sha256 = "0wdf718dkf97mgdf37rihy4hgpy07ifqzsnxf83bbv2smisafmj6";
  # }) {};
  
  # Fix broken latex-svg-image: unmark as broken
  # latex-svg-image-0.2 is marked as broken in nixpkgs but needed for build
  latex-svg-image = haskellLib.markUnbroken super.latex-svg-image;
  
  # cardano-prelude
  # cardano-prelude = self.callCabal2nix "cardano-prelude" (deps.cardano-prelude + "/cardano-prelude") {};
  # cardano-prelude-test - handled inline where needed

  # cardano-base subpackages from cardanoBaseSrc (same commit as thunk)
  heapwords = self.callCabal2nix "heapwords" (cardanoBaseSrc + "/heapwords") {};
  cardano-strict-containers = haskellLib.dontCheck (self.callCabal2nix "cardano-strict-containers" (cardanoBaseSrc + "/cardano-strict-containers") {});
  cardano-crypto-class = self.callCabal2nix "cardano-crypto-class" (cardanoBaseSrc + "/cardano-crypto-class") {};
  
  # cardano-base
  cardano-binary = haskellLib.dontCheck (haskellLib.doJailbreak (haskellLib.enableCabalFlag (
    haskellLib.overrideCabal (self.callPackage ./generated/cardano-binary.nix {}) (drv: {
      src = cardanoBaseSrc + "/cardano-binary";
    })
  ) "development"));
  cardano-binary-test = haskellLib.enableCabalFlag (
    self.callCabal2nixWithOptions "cardano-binary-test" cardanoBaseSrc "--subpath cardano-binary/test" {}
  ) "development";
  cardano-slotting = self.callCabal2nix "cardano-slotting" (cardanoBaseSrc + "/cardano-slotting") {};
  base-deriving-via = self.callCabal2nix "base-deriving-via" (cardanoBaseSrc + "/base-deriving-via") {};
  orphans-deriving-via = self.callCabal2nix "orphans-deriving-via" (cardanoBaseSrc + "/orphans-deriving-via") {};
  measures = self.callCabal2nix "measures" (cardanoBaseSrc + "/measures") {};

  # cardano-ledger
  # tests fail on some env var not being set
  cardano-ledger-babbage = haskellLib.dontCheck (haskellLib.enableCabalFlag (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-babbage" (deps.cardano-ledger + "/eras/babbage/impl") {})) "development");
  cardano-ledger-babbage-test = haskellLib.dontCheck (haskellLib.enableCabalFlag (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-babbage-test" (deps.cardano-ledger + "/eras/babbage/test-suite") {})) "development");
  cardano-ledger-byron = haskellLib.dontCheck (haskellLib.enableCabalFlag (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-byron" (deps.cardano-ledger + "/eras/byron/ledger/impl") {})) "development");
  cardano-ledger-byron-test = null;  # Path doesn't exist in thunk: /eras/byron/ledger/impl/test
  cardano-ledger-shelley = haskellLib.dontCheck (self.callCabal2nix "cardano-ledger-shelley" (deps.cardano-ledger + "/eras/shelley/impl") {});
  cardano-ledger-shelley-test = haskellLib.dontCheck (self.callCabal2nix "cardano-ledger-shelley-test" (deps.cardano-ledger + "/eras/shelley/test-suite") {});
  cardano-ledger-shelley-ma = null;  # Path doesn't exist in thunk: /eras/shelley-ma/impl
  cardano-ledger-allegra = haskellLib.dontCheck (haskellLib.enableCabalFlag (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-allegra" (deps.cardano-ledger + "/eras/allegra/impl") {})) "development");
  cardano-ledger-mary = haskellLib.dontCheck (haskellLib.enableCabalFlag (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-mary" (deps.cardano-ledger + "/eras/mary/impl") {})) "development");
  cardano-ledger-alonzo = haskellLib.dontCheck (haskellLib.enableCabalFlag (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-alonzo" (deps.cardano-ledger + "/eras/alonzo/impl") {})) "development");
  cardano-ledger-alonzo-test = haskellLib.dontCheck (self.callCabal2nix "cardano-ledger-alonzo-test" (deps.cardano-ledger + "/eras/alonzo/test-suite") {});
  cardano-ledger-shelley-ma-test = haskellLib.dontCheck (self.callCabal2nix "cardano-ledger-shelley-ma-test" (deps.cardano-ledger + "/eras/shelley-ma/test-suite") {});
  cardano-ledger-core = haskellLib.dontCheck (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-core" (deps.cardano-ledger + "/libs/cardano-ledger-core") {}));
  cardano-ledger-api = haskellLib.dontCheck (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-api" (deps.cardano-ledger + "/libs/cardano-ledger-api") {}));
  cardano-protocol-tpraos = haskellLib.dontCheck (self.callCabal2nix "cardano-protocol-tpraos" (deps.cardano-ledger + "/libs/cardano-protocol-tpraos") {});
  # cardano-ledger libs
  cardano-ledger-dijkstra = null;  # Doesn't exist in cardano-ledger thunk /libs/
  cardano-ledger-pretty = haskellLib.dontCheck (self.callCabal2nix "cardano-ledger-pretty" (deps.cardano-ledger + "/libs/cardano-ledger-pretty") {});
  cardano-data = self.callCabal2nix "cardano-data" (deps.cardano-ledger + "/libs/cardano-data") {};
  vector-map = self.callCabal2nix "vector-map" (deps.cardano-ledger + "/libs/vector-map") {};
  set-algebra = self.callCabal2nix "set-algebra" (deps.cardano-ledger + "/libs/set-algebra") {};
  # non-integral: RESTORED for GHC 9.6.7 (base-4.18)
  # Now compatible with GHC 9.6+ which provides base >=4.18
  non-integral = self.callCabal2nix "non-integral" (deps.cardano-ledger + "/libs/non-integral") {};
  small-steps = haskellLib.dontCheck (self.callCabal2nix "small-steps" (deps.cardano-ledger + "/libs/small-steps") {});
  small-steps-test = haskellLib.dontCheck (haskellLib.doJailbreak (self.callCabal2nix "small-steps-test" (deps.cardano-ledger + "/libs/small-steps-test") {}));
  byron-spec-chain = haskellLib.dontCheck (haskellLib.doJailbreak (self.callCabal2nix "byron-spec-chain" (deps.cardano-ledger + "/eras/byron/chain/executable-spec") {}));
  byron-spec-ledger = haskellLib.dontCheck (haskellLib.doJailbreak (self.callCabal2nix "byron-spec-ledger" (deps.cardano-ledger + "/eras/byron/ledger/executable-spec") {}));
  # cuddle - Manual derivation (cabal2nix doesn't support cabal-version 3.4)
  # Using tagged release cuddle-0.5.0.0 (tag d0dad49, June 3, 2025)
  cuddle = haskellLib.dontCheck (self.callPackage ({ mkDerivation, base, base16-bytestring, boxes, bytestring
    , capability, cborg, containers, data-default-class
    , foldable1-classes-compat, generic-optics, hashable, megaparsec
    , mtl, mutable-containers, optics-core, optparse-applicative
    , ordered-containers, parser-combinators, prettyprinter, random
    , regex-tdfa, scientific, stdenv, text, tree-diff
    }:
    mkDerivation {
      pname = "cuddle";
      version = "0.5.0.0";
      src = pkgs.fetchFromGitHub {
        owner = "input-output-hk";
        repo = "cuddle";
        rev = "d0dad49a83389220c8ee8265dbcdd5641cd218e6";
        sha256 = "1r4c70b2fn0dlki1j0gjjlgbdb9cl9dbnkzwbc54k1q0a8vvv9nk";
      };
      libraryHaskellDepends = [
        base base16-bytestring boxes bytestring capability cborg
        containers data-default-class foldable1-classes-compat
        generic-optics hashable megaparsec mtl mutable-containers
        optics-core ordered-containers parser-combinators prettyprinter
        random regex-tdfa scientific text tree-diff
      ];
      executableHaskellDepends = [
        base base16-bytestring bytestring cborg megaparsec mtl
        optparse-applicative prettyprinter random text
      ];
      description = "CDDL Generator and test utilities";
      license = stdenv.lib.licenses.asl20;
    }) {});
  compact-map = haskellLib.dontCheck (self.callCabal2nix "compact-map" (deps.cardano-ledger + "/libs/compact-map") {});
  # These packages are not in all-cabal-hashes, so we fetch from GitHub
  # bifunctor-classes-compat = haskellLib.dontCheck (self.callCabal2nix "bifunctor-classes-compat" (pkgs.fetchFromGitHub {
  #   owner = "haskell-compat";
  #   repo = "bifunctor-classes-compat";
  #   rev = "68f12f4f85efa62e5e782237acebb96bdfb44f7c";  # tag 0.1
  #   sha256 = "14v5nn78jrrk3awzyfh1k3dc2p15rgyrlyc6j0fdffwmwk7lbxzg";
  # }) {});
  foldable1-classes-compat = haskellLib.dontCheck (self.callCabal2nix "foldable1-classes-compat" (pkgs.fetchFromGitHub {
    owner = "haskell-compat";
    repo = "foldable1-classes-compat";
    rev = "6e2c97435d537267f9845b4bd33c1b26c52e46e1";  # tag v0.1.1
    sha256 = "07wzlwk36dizqpc3qrsb7pyhh79wy56yz1f9dl9bvyyml533sa3r";
  }) {});
  cardano-ledger-conway = haskellLib.dontCheck (haskellLib.enableCabalFlag (haskellLib.doJailbreak (self.callCabal2nix "cardano-ledger-conway" (deps.cardano-ledger + "/eras/conway/impl") {})) "development");
  # Dummy packages to satisfy dependencies
  cardano-prelude-test = haskellLib.dontCheck (
    self.callCabal2nix "cardano-prelude-test" (deps.cardano-prelude + "/cardano-prelude-test") {}
  );
  cardano-crypto-wrapper = haskellLib.dontCheck (
    self.callCabal2nix "cardano-crypto-wrapper" (deps.cardano-ledger + "/eras/byron/crypto") {}
  );
  cardano-crypto-test = null;  # Missing cabal file, disabled
  cardano-ledger-binary = self.cardano-binary;  # Alias to cardano-binary from cardano-base

  # iohk-monitoring
  contra-tracer = haskellLib.dontCheck (self.callCabal2nix "contra-tracer" (deps.iohk-monitoring-framework + "/contra-tracer") {});
  iohk-monitoring = haskellLib.dontCheck (self.callCabal2nix "iohk-monitoring" (deps.iohk-monitoring-framework + "/iohk-monitoring") {});
  tracer-transformers = haskellLib.dontCheck (self.callCabal2nix "tracer-transformers" (deps.iohk-monitoring-framework + "/tracer-transformers") {});
  lobemo-backend-trace-forwarder = self.callCabal2nix "lobemo-backend-trace-forwarder" (deps.iohk-monitoring-framework + "/plugins/backend-trace-forwarder") {};
  lobemo-backend-monitoring = self.callCabal2nix "lobemo-backend-monitoring" (deps.iohk-monitoring-framework + "/plugins/backend-monitoring") {};
  lobemo-backend-aggregation = self.callCabal2nix "lobemo-backend-aggregation" (deps.iohk-monitoring-framework + "/plugins/backend-aggregation") {};
  lobemo-backend-ekg = self.callCabal2nix "lobemo-backend-ekg" (deps.iohk-monitoring-framework + "/plugins/backend-ekg") {};
  lobemo-scribe-systemd = self.callCabal2nix "lobemo-scribe-systemd" (deps.iohk-monitoring-framework + "/plugins/scribe-systemd") {};

  # ouroboros-network
  # Note: ouroboros-network uses cabal-version 3.4, so we use pre-generated .nix file
  # Many ouroboros-network-* subpackages don't exist in thunk at commit 4eb9750
  # They were likely moved to a different repo or restructured
  ouroboros-network = haskellLib.dontCheck (haskellLib.doJailbreak (self.callPackage ../generated-nix-expressions/ouroboros-network.nix {
    src = deps.ouroboros-network;
  }));
  ouroboros-network-framework = haskellLib.dontCheck (haskellLib.doJailbreak (self.callCabal2nix "ouroboros-network-framework" (deps.ouroboros-network + "/ouroboros-network-framework") {}));
  ouroboros-network-testing = null;  # Path doesn't exist in thunk at commit 4eb9750
  ouroboros-network-mock = null;  # Path doesn't exist in thunk at commit 4eb9750
  # ouroboros-network-api and ouroboros-network-protocols are public sublibraries of ouroboros-network package
  # (defined in ouroboros-network.cabal as "library api" and "library protocols")
  # Make them aliases to the main ouroboros-network package so dependencies can reference them
  ouroboros-network-api = self.ouroboros-network;
  ouroboros-network-protocols = self.ouroboros-network;
  ouroboros-consensus = haskellLib.doJailbreak (self.callCabal2nix "ouroboros-consensus" (deps.ouroboros-consensus + "/ouroboros-consensus") {});
  ouroboros-consensus-byron = haskellLib.doJailbreak (self.callCabal2nix "ouroboros-consensus-byron" (deps.ouroboros-consensus + "/ouroboros-consensus-byron") {});
  ouroboros-consensus-shelley = haskellLib.doJailbreak (self.callCabal2nix "ouroboros-consensus-shelley" (deps.ouroboros-consensus + "/ouroboros-consensus-shelley") {});
  ouroboros-consensus-cardano = haskellLib.doJailbreak (self.callCabal2nix "ouroboros-consensus-cardano" (deps.ouroboros-consensus + "/ouroboros-consensus-cardano") {});
  ouroboros-consensus-diffusion = haskellLib.doJailbreak (self.callCabal2nix "ouroboros-consensus-diffusion" (deps.ouroboros-consensus + "/ouroboros-consensus-diffusion") {});
  ouroboros-consensus-protocol = haskellLib.doJailbreak (self.callCabal2nix "ouroboros-consensus-protocol" (deps.ouroboros-consensus + "/ouroboros-consensus-protocol") {});
  sop-extras = self.callCabal2nix "sop-extras" (deps.ouroboros-consensus + "/sop-extras") {};
  strict-sop-core = self.callCabal2nix "strict-sop-core" (deps.ouroboros-consensus + "/strict-sop-core") {};
  monoidal-synchronisation = self.callCabal2nix "monoidal-synchronisation" (deps.ouroboros-network + "/monoidal-synchronisation") {};
  network-mux = haskellLib.dontCheck (haskellLib.doJailbreak (self.callCabal2nix "network-mux" (deps.ouroboros-network + "/network-mux") {}));
  ntp-client = haskellLib.dontCheck (haskellLib.doJailbreak (self.callCabal2nix "ntp-client" (deps.ouroboros-network + "/ntp-client") {}));

  # cardano-node
  # cardano-api = haskellLib.dontCheck (self.callCabal2nix "cardano-api" (deps.cardano-node + "/cardano-api") {});
  cardano-node = ((self.callCabal2nix "cardano-node" (deps.cardano-node + "/cardano-node") {}));
  cardano-cli = haskellLib.overrideCabal (self.callCabal2nix "cardano-cli" (deps.cardano-node + "/cardano-cli") {}) (drv: {
    doCheck = false;
    preCheck = ''
      export CARDANO_CLI=$PWD/dist/build/cardano-cli
      export CARDANO_NODE_SRC=$PWD
    '';
    buildTools = (drv.buildTools or []) ++ [ pkgs.jq pkgs.shellcheck pkgs.coreutils ];
    # NOTE: see link for details
    # https://3.basecamp.com/4757487/buckets/24531883/messages/5274529248
    configureFlags = [ "--dependency=cardano-api:gen=cardano-api-1.32.1-Fx8Wd6R8QrDmKMaXBLt3v-gen" ]; # gross, but it works
  });
  cardano-config = ((self.callCabal2nix "cardano-config" (deps.cardano-node + "/cardano-config") {}));
  hedgehog-extras = self.callCabal2nix "hedgehog-extras" deps.hedgehog-extras {};

  # plutus (uh oh!)
  plutus-core = self.callCabal2nix "plutus-core" (deps.plutus + "/plutus-core") {};
  plutus-ledger = haskellLib.overrideCabal (self.callCabal2nix "plutus-ledger" (deps.plutus + "/plutus-ledger") {}) (drv: {
    doHaddock = false; # to avoid plutus-tx-plugin errors
    # NOTE: see link for details
    # https://3.basecamp.com/4757487/buckets/24531883/messages/5274529248
    configureFlags = [ "--dependency=cardano-api:gen=cardano-api-1.32.1-Fx8Wd6R8QrDmKMaXBLt3v-gen" ]; # gross, but it works
  });
  freer-extras = self.callCabal2nix "freer-extras" (deps.plutus + "/freer-extras") {};
  playground-common = self.callCabal2nix "playground-common" (deps.plutus + "/playground-common") {};
  plutus-chain-index = self.callCabal2nix "plutus-chain-index" (deps.plutus + "/plutus-chain-index") {};
  plutus-contract = haskellLib.dontHaddock (self.callCabal2nix "plutus-contract" (deps.plutus + "/plutus-contract") {}); # FIXME fix tests
  plutus-pab = haskellLib.dontHaddock (self.callCabal2nix "plutus-pab" (deps.plutus + "/plutus-pab") {});
  plutus-tx-plugin = self.callCabal2nix "plutus-tx-plugin" (deps.plutus + "/plutus-tx-plugin") {};
  # plutus-ledger-api = self.callCabal2nix "plutus-ledger-api" (deps.plutus + "/plutus-ledger-api") {};
  # only nix-build of test seems broken, but running cabal test on pkg works :/
  plutus-use-cases = haskellLib.dontHaddock (haskellLib.dontCheck (self.callCabal2nix "plutus-use-cases" (deps.plutus + "/plutus-use-cases") {}));
  # prettyprinter-configurable from GitHub (not in all-cabal-hashes, plutus thunk version fails)
  prettyprinter-configurable = haskellLib.dontCheck (self.callCabal2nix "prettyprinter-configurable" (pkgs.fetchFromGitHub {
    owner = "effectfully";
    repo = "prettyprinter-configurable";
    rev = "432ea90445d3dd84c73facabc92d3f90a82142f6";  # initial commit for version 1.0.0.0
    sha256 = "1bbbbwlv3xiv7zkpk25m7v0j6pdxs890qfvap7jdl44nickzrbsz";
  }) {});
  # quickcheck-dynamic moved to line 341 (from GitHub, not plutus thunk)
  word-array = self.callCabal2nix "word-array" (deps.plutus + "/word-array") {};
  # plutus misc
  # flat = self.callCabal2nix "flat" deps.flat {};
  size-based = haskellLib.doJailbreak super.size-based;
  row-types = self.callCabal2nix "row-types" deps.row-types {}; # "1.0.1.1"
  pcg-random = self.callHackage "pcg-random" "0.1.3.7" {};

  # cardano-addresses
  cardano-addresses = haskellLib.doJailbreak (self.callCabal2nixWithOptions "cardano-addresses" (deps.cardano-addresses + "/core") "--no-hpack" {});
  cardano-addresses-cli = haskellLib.dontCheck (self.callCabal2nixWithOptions "cardano-addresses-cli" (deps.cardano-addresses + "/command-line") "--no-hpack" { cardano-address = null; });

  # io-sim monorepo contains io-classes, io-sim, and standalone strict-stm/strict-mvar
  # Using commit b61e23a (Nov 8, 2023) - strict-stm 1.3.0.0 / strict-mvar 1.3.0.0
  # This version has standalone packages with InspectMonad API (before rename to InspectMonadSTM)
  io-classes = haskellLib.dontCheck (self.callCabal2nixWithOptions "io-classes" (deps.io-sim + "/io-classes") "" {});
  io-sim = haskellLib.dontCheck (self.callCabal2nixWithOptions "io-sim" (deps.io-sim + "/io-sim") "" {});
  
  # Build strict-stm and strict-mvar from the io-sim thunk's standalone directories
  # These use the old InspectMonad API and are compatible with this io-classes version
  strict-stm = haskellLib.dontCheck (self.callCabal2nixWithOptions "strict-stm" (deps.io-sim + "/strict-stm") "" {});
  strict-mvar = haskellLib.dontCheck (self.callCabal2nixWithOptions "strict-mvar" (deps.io-sim + "/strict-mvar") "" {});
  # strict-checked-vars from cardano-base monorepo (newer commit than cardanoBaseSrc)
  strict-checked-vars = self.callCabal2nixWithOptions "strict-checked-vars" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "cardano-base";
    rev = "e545ee648cb7ef9d2715286dbc38987ffc3b5e4d";  # commit from strict-checked-vars thunk
    sha256 = "1wg8v38nfm98jdaxkswsb0qfpkdisc5a4gxmzidg248w5pf5fa0k";
  }) "--subpath strict-checked-vars" {};

  # typed-protocols
  # All typed-protocols packages use cabal-version 3.4, so we use pre-generated .nix files
  typed-protocols = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/typed-protocols.nix {
    src = deps.typed-protocols;
  });
  typed-protocols-cborg = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/typed-protocols-cborg.nix {
    src = deps.typed-protocols;
  });
  typed-protocols-examples = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/typed-protocols-examples.nix {
    src = deps.typed-protocols;
  });

  # ekg-json
  ekg-json = self.callCabal2nix "ekg-json" deps.ekg-json {};

  # other iohk
  Win32-network = self.callCabal2nix "Win32-network" deps.Win32-network {};
  cardano-sl-x509 = self.callCabal2nix "cardano-sl-x509" deps.cardano-sl-x509 {};
  goblins = haskellLib.dontCheck (self.callCabal2nix "goblins" deps.goblins {});
  # cardano-crypto = self.callCabal2nix "cardano-crypto" deps.cardano-crypto {};
  bech32 = haskellLib.dontCheck (self.callCabal2nix "bech32" (deps.bech32 + "/bech32") {}); # 1.1.1 ; tests rely on bech32 executable
  bech32-th = self.callCabal2nix "bech32-th" (deps.bech32 + "/bech32-th") {}; #1.1.1
  optparse-applicative-fork = haskellLib.dontCheck (self.callCabal2nix "optparse-applicative-fork" deps.optparse-applicative {});
  servant-purescript = self.callCabal2nix "servant-purescript" deps.servant-purescript {};
  purescript-bridge = self.callCabal2nix "purescript-bridge" deps.purescript-bridge {};

  scrypt = haskellLib.overrideCabal super.scrypt (drv: { platforms = (drv.platforms or []) ++ [ "js-ghcjs" "aarch64-linux" ]; });

  # other misc
  # hw-aeson removed re-exports Data.Aeson.KeyMap which cardano-addresses expects (unintentional?)
  hw-aeson = haskellLib.overrideCabal (self.callCabal2nix "hw-aeson" deps.hw-aeson {}) { # 0.1.6.0
    preConfigure = ''
      substituteInPlace src/HaskellWorks/Data/Aeson/Compat/Map.hs \
        --replace "import qualified Data.Aeson.KeyMap as JM" "import Data.Aeson.KeyMap as JM" \
        --replace ", fromHashMapText" "" \
        --replace ", toHashMapText" ""
    '';
  };
  # character-ps 0.1 (from Hackage tarball directly, not in all-cabal-hashes archive)
  character-ps = haskellLib.dontCheck (self.callCabal2nix "character-ps" (pkgs.fetchzip {
    url = "https://hackage.haskell.org/package/character-ps-0.1/character-ps-0.1.tar.gz";
    sha256 = "13yvm3ifpk6kfqba49r1xz0xyxcn0jw7xdkkblzsb5v0nf64g4dx";
    stripRoot = true;
  }) {});
  # integer-conversion 0.1.1 (from Hackage tarball directly, not in all-cabal-hashes archive)
  integer-conversion = haskellLib.dontCheck (self.callCabal2nix "integer-conversion" (pkgs.fetchzip {
    url = "https://hackage.haskell.org/package/integer-conversion-0.1.1/integer-conversion-0.1.1.tar.gz";
    sha256 = "0jrch63xc80fq6s14zwi5wcmbrj8zr7anl420sq98aglx3df9yr3";
    stripRoot = true;
  }) {});
  # attoparsec-aeson 2.2.2.0 (from Hackage tarball directly, not in all-cabal-hashes archive)
  attoparsec-aeson = haskellLib.dontCheck (self.callCabal2nix "attoparsec-aeson" (pkgs.fetchzip {
    url = "https://hackage.haskell.org/package/attoparsec-aeson-2.2.2.0/attoparsec-aeson-2.2.2.0.tar.gz";
    sha256 = "0c1axkc1mdhhpnw2240c0nmd25ydcixdcip5v4cbkp9zbig97i07";
    stripRoot = true;
  }) {});
  # crypton-connection 0.4.1 (from Hackage)
  crypton-connection = haskellLib.dontCheck (self.callHackage "crypton-connection" "0.4.1" {});
  # data-elevator: RESTORED for GHC 9.6.7 (required by lsm-tree when impl(ghc >=9.4))
  # Now available since GHC 9.6+ provides base >=4.16
  data-elevator = haskellLib.dontCheck (self.callHackage "data-elevator" "0.1.0.1" {});
  # cardano-git-rev 0.1.3.0 (from CHaP, in cardano-node monorepo)
  # Using older version because 0.2.2.1 requires base >=4.18 (GHC 9.6+)
  # Version 0.1.3.0 supports base >=4.14 which works with GHC 8.10.7
  cardano-git-rev = haskellLib.dontCheck (self.callCabal2nixWithOptions "cardano-git-rev" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "cardano-node";
    rev = "9a0898636a4ea13f720dc3c6c8789b27beeb37c9";  # from CHaP cardano-git-rev/0.1.3.0
    sha256 = "06qklfk8akqpb62iciafc27r5b3frj806bnkz8mg5vrnfr29vrv8";
  }) "--subpath cardano-git-rev" {});
  # kes-agent 0.2.0.1 (from CHaP, in kes-agent monorepo)
  kes-agent = haskellLib.dontCheck (self.callCabal2nixWithOptions "kes-agent" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "kes-agent";
    rev = "d7c27bfbf8e216920c40ed84b276d2d789c3c5ef";  # from CHaP kes-agent/0.2.0.1
    sha256 = "1lilf9l4dr1df9kdpm134pvfx6wpg0zbbzh2vwgbxwkn2vw2sb0l";
  }) "--subpath kes-agent" {});
  # kes-agent-crypto 0.1.0.0 (from CHaP, in kes-agent monorepo)
  kes-agent-crypto = haskellLib.dontCheck (self.callCabal2nixWithOptions "kes-agent-crypto" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "kes-agent";
    rev = "abe5aafc90fc837b0941504a89f7a207b589fd83";  # from CHaP kes-agent-crypto/0.1.0.0
    sha256 = "0pf2nzgiy925pyzp88ykiqnasm446k47rfrqi094fgkqk2ghh3jh";
  }) "--subpath kes-agent-crypto" {});
  # serdoc-core 0.1.0.0 (from Hackage tarball directly, not in all-cabal-hashes archive)
  serdoc-core = haskellLib.dontCheck (self.callCabal2nix "serdoc-core" (pkgs.fetchzip {
    url = "https://hackage.haskell.org/package/serdoc-core-0.1.0.0/serdoc-core-0.1.0.0.tar.gz";
    sha256 = "18acsigs1ynqnszhpy6gg25h2i58qscgqy4jzgx7krpqwfp3b1vd";
    stripRoot = true;
  }) {});
  # bloomfilter-blocked 0.1.0.0 (from GitHub IntersectMBO/lsm-tree monorepo)
  # RESTORED for GHC 9.6.7: Uses pre-generated .nix due to cabal-version 3.4 requirement
  # COMMENTED OUT: haskell.nix module system doesn't know about this package yet
  # bloomfilter-blocked = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/bloomfilter-blocked.nix {
  #   src = pkgs.fetchFromGitHub {
  #     owner = "IntersectMBO";
  #     repo = "lsm-tree";
  #     rev = "645329036a2bf59cde9faa455eb4f8931bd0d121";  # tag blockio-0.1.0.1 (same monorepo)
  #     sha256 = "1b4z5m536ll8al1xm84qc5wiwqmfsagx81dqymqcffsjlbi3hxwv";
  #   };
  # });
  FailT = haskellLib.dontCheck (self.callCabal2nix "FailT" (pkgs.fetchFromGitHub {
    owner = "lehins";
    repo = "FailT";
    rev = "bfc058095f65442d7d0403c1c3597ce48eccc3ad";  # tag FailT-0.1.2.0
    sha256 = "0d1fvzcs89dwicy1hza9fkrjvsms67705pamv1rnwv64zkcwr9iv";
  }) {});
  transformers-except = haskellLib.doJailbreak super.transformers-except;
  # safe-wild-cards 1.0.0.2 (from GitHub amesgen/safe-wild-cards)
  safe-wild-cards = haskellLib.dontCheck (self.callCabal2nix "safe-wild-cards" (pkgs.fetchFromGitHub {
    owner = "amesgen";
    repo = "safe-wild-cards";
    rev = "3edf5a370595e0d1743ad30e216530ffe039483e";  # master with version 1.0.0.2
    sha256 = "031j704x8fj6x8gz6rlwif0hhnib9pjhxyxmv03ckk19vwgdcxbx";
  }) {});
  # fs-api 0.3.0.1 (not in all-cabal-hashes, from GitHub monorepo fs-sim)
  fs-api = haskellLib.dontCheck (self.callCabal2nixWithOptions "fs-api" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "fs-sim";
    rev = "efd70ad35e1a5df50d9f5b80d278ae3bc12306c9";  # tag fs-api-0.3.0.1
    sha256 = "0zdvj28micvdqncyznq0sc2bwin6daj1pssx94q8spknspcivc4i";
  }) "--subpath fs-api" {});
  # fs-sim 0.3.0.1 (not in all-cabal-hashes, from GitHub monorepo fs-sim)
  fs-sim = haskellLib.dontCheck (self.callCabal2nixWithOptions "fs-sim" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "fs-sim";
    rev = "efd70ad35e1a5df50d9f5b80d278ae3bc12306c9";  # tag fs-sim-0.3.0.1
    sha256 = "0zdvj28micvdqncyznq0sc2bwin6daj1pssx94q8spknspcivc4i";
  }) "--subpath fs-sim" {});
  # fingertree-rm 1.0.0.4 (from GitHub input-output-hk/anti-diffs monorepo)
  fingertree-rm = haskellLib.dontCheck (self.callCabal2nixWithOptions "fingertree-rm" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "anti-diffs";
    rev = "bf3dd52b3a85fb075194e92b7851e5ccb3025290";  # tag fingertree-rm-1.0.0.4 & diff-containers-1.3.0.0
    sha256 = "17cnnnisxpfj9kq409szk0rhs42qxnd6cb7cr0lrqpdgkl00rf7p";
  }) "--subpath fingertree-rm" {});
  # diff-containers 1.3.0.0 (from GitHub input-output-hk/anti-diffs monorepo, same commit as fingertree-rm)
  diff-containers = haskellLib.dontCheck (self.callCabal2nixWithOptions "diff-containers" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "anti-diffs";
    rev = "bf3dd52b3a85fb075194e92b7851e5ccb3025290";  # tag diff-containers-1.3.0.0
    sha256 = "17cnnnisxpfj9kq409szk0rhs42qxnd6cb7cr0lrqpdgkl00rf7p";
  }) "--subpath diff-containers" {});
  # rawlock 0.1.2.0 (from GitHub IntersectMBO/io-classes-extra monorepo)
  rawlock = haskellLib.dontCheck (self.callCabal2nixWithOptions "rawlock" (pkgs.fetchFromGitHub {
    owner = "IntersectMBO";
    repo = "io-classes-extra";
    rev = "ba56feadc779517f9b9357753080b7ccfb9dbc56";  # tag rawlock-0.1.2.0
    sha256 = "1jlqa8z0ypmzzsy4rw3wcc58zgi8xdzfsi1n68yyq2mhay8zrwg1";
  }) "--subpath rawlock" {});
  # quickcheck-dynamic 4.0.0 (from GitHub input-output-hk/quickcheck-dynamic monorepo, not in all-cabal-hashes)
  quickcheck-dynamic = haskellLib.dontCheck (self.callCabal2nixWithOptions "quickcheck-dynamic" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "quickcheck-dynamic";
    rev = "7bb43882e7ef7f48b522709ee9e33fad1abdf1df";  # tag 4.0.0
    sha256 = "1rbyaxzp367397rkab0mxlcbvhjwvyj34by5382h8slwyga7zc59";
  }) "--subpath quickcheck-dynamic" {});
  # quickcheck-lockstep 0.8.1 (cabal-version 3.4, pre-generated)
  quickcheck-lockstep = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/quickcheck-lockstep.nix {
    src = pkgs.fetchFromGitHub {
      owner = "well-typed";
      repo = "quickcheck-lockstep";
      rev = "a43ed5bcd72e9afb64436be66940af08b4cb33eb";  # tag quickcheck-lockstep-0.8.1
      sha256 = "0xhilpiybg33zjkj8gja7jbjcgarrd1vd8yan1qygjqyhr2df9pm";
    };
  });
  # quickcheck-monoid-subclasses 0.3.0.6 (from GitHub jonathanknowles/quickcheck-monoid-subclasses)
  quickcheck-monoid-subclasses = haskellLib.dontCheck (self.callCabal2nix "quickcheck-monoid-subclasses" (pkgs.fetchFromGitHub {
    owner = "jonathanknowles";
    repo = "quickcheck-monoid-subclasses";
    rev = "a2000470a6befd4d1e0e311e96804e353684b18e";  # tag 0.3.0.6
    sha256 = "03j9bkb1yf5l3z7v0mz776k3gmganwxldpp3ns89qc9s1j63fa99";
  }) {});
  # cardano-lmdb 0.4.0.3 (from GitHub input-output-hk/haskell-lmdb)
  # RESTORED for GHC 9.6.7: GHC 9.6.7 includes Cabal 3.10+ which properly handles internal libraries
  # The package has both a main library and an internal "library ffi" which Cabal 3.2 could not resolve.
  cardano-lmdb = haskellLib.dontCheck (self.callCabal2nix "cardano-lmdb" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "haskell-lmdb";
    rev = "f8ad4d9ccafdb9c315b3c66e78917c561d812244";  # tag cardano-lmdb-0.4.0.3
    sha256 = "0nmial9i86l23m8bb7j56vqykqx8fbmlxd0r21fci98gsay0j2l7";
  }) {});
  # cardano-lmdb-simple 0.8.1.0 (from GitHub input-output-hk/lmdb-simple)
  cardano-lmdb-simple = haskellLib.dontCheck (self.callCabal2nix "cardano-lmdb-simple" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "lmdb-simple";
    rev = "fb732fdc81e45667b948d0b56427076e81bf8604";  # tag cardano-lmdb-simple-0.8.1.0
    sha256 = "1mh2z39h3m8fflylkn5b3pph5wra4npla96531p0dr0a9rlaiv75";
  }) {});
  # blockio 0.1.0.1 (from GitHub IntersectMBO/lsm-tree monorepo)
  # Uses pre-generated .nix due to cabal-version 3.4 requirement
  # COMMENTED OUT: haskell.nix module system doesn't know about this package yet
  # blockio = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/blockio.nix {
  #   src = pkgs.fetchFromGitHub {
  #     owner = "IntersectMBO";
  #     repo = "lsm-tree";
  #     rev = "645329036a2bf59cde9faa455eb4f8931bd0d121";  # tag blockio-0.1.0.1
  #     sha256 = "1b4z5m536ll8al1xm84qc5wiwqmfsagx81dqymqcffsjlbi3hxwv";
  #   };
  # });
  # lsm-tree 1.0.0.0 (from GitHub IntersectMBO/lsm-tree monorepo)
  # Uses pre-generated .nix due to cabal-version 3.4 requirement
  lsm-tree = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/lsm-tree.nix {
    src = pkgs.fetchFromGitHub {
      owner = "IntersectMBO";
      repo = "lsm-tree";
      rev = "9354ba49c336a42328499c9c7b598dbec9558c06";  # tag lsm-tree-1.0.0.0
      sha256 = "0vakbphcppc77mv430q9dvqgf09xqayz1sd6frjhyiyyna9c1vp5";
    };
  });
  # resource-registry 0.2.0.0 (not in all-cabal-hashes, from GitHub monorepo io-classes-extra)
  resource-registry = haskellLib.dontCheck (self.callCabal2nixWithOptions "resource-registry" (pkgs.fetchFromGitHub {
    owner = "IntersectMBO";
    repo = "io-classes-extra";
    rev = "356cd1185a9afc625eb7cff2c1669326cf31d5b1";  # tag release-resource-registry-0.2.0.0
    sha256 = "0fvvw0qzw2hsaw4435gwckrph9lhahi4p8k6qg3065cww0qzhry5";
  }) "--subpath resource-registry" {});
  # data-array-byte 0.1.0.1 (not in all-cabal-hashes, from GitHub)
  data-array-byte = haskellLib.dontCheck (self.callCabal2nix "data-array-byte" (pkgs.fetchFromGitHub {
    owner = "Bodigrim";
    repo = "data-array-byte";
    rev = "f7d9cb10571721ed83c3640778b6ed9751304d9b";  # commit for version 0.1.0.1
    sha256 = "0bsjpza7zc6w8xnqx4xfckj385cf7rrdw7ja9a4mnrpixvfdrdsy";
  }) {});
  mempack = haskellLib.dontCheck (self.callCabal2nix "mempack" (pkgs.fetchFromGitHub {
    owner = "lehins";
    repo = "mempack";
    rev = "62ac57b7887850628687a56753929534f7ea5542";  # tag mempack-0.1.1.0
    sha256 = "0117ifaxsifn38mklw7d6hdh381lj5dv2xv0j8nd6jl9mxpsx1j1";
  }) {});
  ImpSpec = haskellLib.dontCheck (self.callCabal2nix "ImpSpec" (pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "ImpSpec";
    rev = "e5ff0f14687e63337c728092b76ec44dc8875673";  # tag ImpSpec-0.1.0.0
    sha256 = "1jv8iihw4q5cv3lbd60a9qbs14bz4xy69g4524d0hl6kpb3309vh";
  }) {});
  ekg = haskellLib.doJailbreak (self.callHackage "ekg" "0.4.0.15" {});
  yaml = self.callHackage "yaml" "0.11.7.0" {};
  trifecta = haskellLib.doJailbreak super.trifecta;
  Unique = haskellLib.dontCheck (self.callHackage "Unique" "0.4.7.9" {});
  foldl = self.callHackage "foldl" "1.4.12" {};
  rebase = haskellLib.doJailbreak super.rebase;
  profunctors = self.callHackage "profunctors" "5.6.2" {};
  contravariant = self.callHackage "contravariant" "1.5.5" {};
  semigroupoids = self.callHackage "semigroupoids" "5.3.7" {};
  StateVar = self.callHackage "StateVar" "1.2.2" {};
  criterion = self.callCabal2nix "criterion" deps.criterion {};
  js-chart = self.callHackage "js-chart" "2.9.4.1" {};
  these-lens = haskellLib.doJailbreak super.these-lens;
  lens = self.callHackage "lens" "5.1" {};
  lens-aeson = self.callHackage "lens-aeson" "1.1.3" {};
  free = self.callHackage "free" "5.1.7" {};
  microstache = self.callHackage "microstache" "1.0.2" {};
  aeson = self.callHackage "aeson" "2.0.2.0" {};
  # aeson-qq = haskellLib.dontCheck super.aeson-qq;  # Not available in GHC 9.6.7
  aeson-pretty = self.callHackage "aeson-pretty" "0.8.9" {};
  ghcjs-base-stub = self.callCabal2nix "ghcjs-base-stub" deps.ghcjs-base-stub {};
  hpack = self.callHackage "hpack" "0.34.5" {};
  dependent-sum-aeson-orphans = haskellLib.doJailbreak super.dependent-sum-aeson-orphans;
  deriving-aeson = self.callHackage "deriving-aeson" "0.2.8" {};
  semialign = self.callHackage "semialign" "1.2.0.1" {};
  openapi3 = haskellLib.doJailbreak (self.callHackage "openapi3" "3.1.0" {});
  servant-openapi3 = haskellLib.doJailbreak (self.callHackage "servant-openapi3" "2.0.1.2" {});
  servant = self.callHackage "servant" "0.18.3" {};
  servant-client = self.callHackage "servant-client" "0.18.3" {};
  servant-client-core = self.callHackage "servant-client-core" "0.18.3" {};
  servant-foreign = self.callHackage "servant-foreign" "0.15.4" {};
  servant-options = self.callHackage "servant-options" "0.1.0.0" {};
  servant-server = self.callHackage "servant-server" "0.18.3" {};
  servant-subscriber = self.callHackage "servant-subscriber" "0.7.0.0" {};
  servant-websockets = self.callHackage "servant-websockets" "2.0.0" {};
  http2 = builtins.trace "overriding http2" (haskellLib.dontCheck super.http2);
  http-media = haskellLib.doJailbreak super.http-media;
  tasty-bench = self.callHackage "tasty-bench" "0.2.5" {};
  # async-timer = haskellLib.doJailbreak (haskellLib.dontCheck (haskellLib.markUnbroken super.async-timer));  # Not available in GHC 9.6.7
  # OddWord = haskellLib.dontCheck (haskellLib.markUnbroken super.OddWord);  # Not available in GHC 9.6.7
  quickcheck-state-machine = haskellLib.dontCheck (haskellLib.markUnbroken super.quickcheck-state-machine);
  # tests are not compatible with base16-bytestring 1.x
  cryptohash-md5 = haskellLib.dontCheck super.cryptohash-md5;
  # tests are not compatible with base16-bytestring 1.x
  cryptohash-sha1 = haskellLib.dontCheck super.cryptohash-sha1;
  # tests are not compatible with base16-bytestring 1.x
  monoidal-containers = self.callHackage "monoidal-containers" "0.6.2.0" {};
  witherable = self.callHackage "witherable" "0.4.2" {};
  indexed-traversable = self.callHackage "indexed-traversable" "0.1.1" {};
  # QuickCheck constraints
  indexed-traversable-instances = haskellLib.dontCheck (self.callHackage "indexed-traversable-instances" "0.1" {});
  hs-rqlite = haskellLib.doJailbreak super.hs-rqlite;
  tls = self.callHackage "tls" "1.5.5" {};
  libsystemd-journal = haskellLib.overrideCabal (self.callHackage "libsystemd-journal" "1.4.5" {}) (drv: {
    librarySystemDepends = drv.librarySystemDepends or [] ++ [ pkgs.systemd ];
  });
  # beam-sqlite = haskellLib.doJailbreak (self.callHackage "beam-sqlite" "0.5.5.0" {});  # Not in all-cabal-hashes
  scientific = haskellLib.dontCheck (self.callHackage "scientific" "0.3.7.0" {}); # min version compat with plutus-contract tests
  integer-logarithms = haskellLib.doJailbreak (self.callHackage "integer-logarithms" "1.0.3.1" {});
  smallcheck = self.callHackage "smallcheck" "1.2.1" {};
  memory = self.callCabal2nix "memory" deps.hs-memory {}; # 0.16
  katip = haskellLib.dontCheck (self.callHackage "katip" "0.8.7.0" {}); # tests also disabled in iohk-monitoring
  hspec-golden-aeson = haskellLib.dontCheck (self.callHackage "hspec-golden-aeson" "0.9.0.0" {}); # tests fail :/
  tasty-golden = self.callHackage "tasty-golden" "2.3.4" {};
  tasty = self.callHackage "tasty" "1.4.1" {};
  tasty-wai = self.callHackage "tasty-wai" "0.1.1.1" {};
  # tasty 1.4.1
  # blaze-markup = haskellLib.doJailbreak super.blaze-markup;  # Not in GHC 9.6.7 package set
  natural-transformation = haskellLib.doJailbreak super.natural-transformation;
  tdigest = haskellLib.doJailbreak super.tdigest;
  binary-orphans = haskellLib.doJailbreak super.binary-orphans;
  text-short = self.callHackage "text-short" "0.1.5" {};
  bytestring-type = haskellLib.doJailbreak super.bytestring-type;
  base64-bytestring-type = haskellLib.doJailbreak super.base64-bytestring-type;
  tree-diff = haskellLib.dontCheck (self.callHackage "tree-diff" "0.2.1.1" {});
  lattices = haskellLib.doJailbreak super.lattices;
  insert-ordered-containers = haskellLib.doJailbreak super.insert-ordered-containers;
  swagger2 = haskellLib.dontCheck (self.callHackage "swagger2" "2.6" {});
  lzma = haskellLib.dontCheck super.lzma;
  # aeson-casing = haskellLib.dontCheck super.aeson-casing;  # Not available in GHC 9.6.7
  servant-swagger-ui-core = self.callHackage "servant-swagger-ui-core" "0.3.5" {};
  servant-swagger-ui = self.callHackage "servant-swagger-ui" "0.3.5.3.47.1" {};
  recursion-schemes = self.callHackage "recursion-schemes" "5.2.2.2" {};

  persistent = self.callCabal2nix "persistent" (deps.persistent + "/persistent") {}; # 2.13.1.2
  persistent-test = self.callHackage "persistent-test" "2.13.0.0" {};
  persistent-sqlite = haskellLib.addPkgconfigDepend (haskellLib.enableCabalFlag (haskellLib.enableCabalFlag (self.callHackage "persistent-sqlite" "2.13.0.2" {}) "systemlib") "use-pkgconfig") pkgs.sqlite;
  persistent-postgresql = haskellLib.dontCheck (self.callHackage "persistent-postgresql" "2.13.0.3" {}); # tests use network
  persistent-template = self.callHackage "persistent-template" "2.12.0.0" {};
  persistent-qq = haskellLib.dontCheck super.persistent-qq;
  lift-type = self.callHackage "lift-type" "0.1.0.0" {};
  sqlite = null; #haskellLib.markUnbroken super.sqlite;

  generics-sop = self.callHackage "generics-sop" "0.5.1.2" {};
  nothunks = haskellLib.dontCheck (self.callHackage "nothunks" "0.1.3" {});
  moo = haskellLib.dontCheck (haskellLib.markUnbroken super.moo); # tests are failing :/
  gray-code = haskellLib.overrideCabal (haskellLib.markUnbroken super.gray-code) {
    preCompileBuildDriver = "rm Setup.hs";
  };
  # primitive = haskellLib.dontCheck (self.callHackage "primitive" "0.7.1.0" {});
  streaming-bytestring = self.callHackage "streaming-bytestring" "0.2.1" {}; # cardano-crypto-class min bound
  canonical-json = haskellLib.dontCheck (haskellLib.doJailbreak (haskellLib.markUnbroken super.canonical-json));
  cborg = haskellLib.dontCheck super.cborg; # tests don't build for base16-bytestring >=1
  text-conversions = self.callHackage "text-conversions" "0.3.1" {}; # compatible with base16-bytestring 1.x
  base16-bytestring = self.callHackage "base16-bytestring" "1.0.2.0" {}; # for cardano-prelude
  base64-bytestring = self.callCabal2nix "base64-bytestring" deps.base64-bytestring {}; # 1.2.1.0
  unordered-containers = self.callHackage "unordered-containers" "0.2.16.0" {}; # for cardano-addresses
  # protolude = self.callHackage "protolude" "0.3.0" {}; # for cardano-prelude
  # formatting = self.callHackage "formatting" "7.1.0" {};
  # fmt = self.callCabal2nix "fmt" deps.fmt {};
  fgl = haskellLib.doJailbreak super.fgl;
  fgl-arbitrary = haskellLib.doJailbreak super.fgl-arbitrary;
  string-interpolate = self.callHackage "string-interpolate" "0.3.1.1" {};
  wide-word = haskellLib.dontCheck (self.callHackage "wide-word" "0.1.1.2" {});
  graphviz = haskellLib.dontCheck super.graphviz;
  # misc expensive. 21.05 should have more recent versions.
  hspec = self.callHackage "hspec" "2.8.2" {};
  hspec-core = self.callHackage "hspec-core" "2.8.2" {};
  hspec-discover = self.callHackage "hspec-discover" "2.8.2" {};
  hspec-expectations = self.callHackage "hspec-expectations" "0.8.2" {};
  hspec-meta = self.callHackage "hspec-meta" "2.7.8" {};
  # quickcheck-instances is DEPRECATED - all instances now in QuickCheck 2.17.1.0 (GHC 9.6.7)
  quickcheck-instances = null;
  hedgehog = self.callCabal2nix "hedgehog" (deps.haskell-hedgehog + "/hedgehog") {}; # self.callHackage "hedgehog" "1.1" {};
  hedgehog-fn = haskellLib.doJailbreak super.hedgehog-fn; # allow newer hedgehog
  hedgehog-quickcheck = haskellLib.doJailbreak (self.callHackage "hedgehog-quickcheck" "0.1.1" {});
  # allow newer QuickCheck/hspec
  time-compat = self.callHackage "time-compat" "1.9.6" {};
  strict = self.callHackage "strict" "0.4.0.1" {};
  vector = haskellLib.dontCheck (haskellLib.dontHaddock (haskellLib.dontBenchmark (self.callHackage "vector" "0.12.3.1" {})));
  attoparsec = haskellLib.doJailbreak super.attoparsec;
  random = haskellLib.dontCheck (self.callHackage "random" "1.2.0" {});
  generic-random = haskellLib.dontCheck (self.callHackage "generic-random" "1.4.0.0" {});
  # TODO: fix rp version about unkwon pkg
  splitmix = haskellLib.dontCheck (self.callHackage "splitmix" "0.1.0.3" {}); # dontCheck to avoid cycle with random
  http-api-data = haskellLib.doJailbreak super.http-api-data;
  algebraic-graphs = haskellLib.doJailbreak (haskellLib.dontCheck super.algebraic-graphs);
  cassava = haskellLib.doJailbreak super.cassava;
  psqueues = haskellLib.doJailbreak super.psqueues;
  tasty-hedgehog = haskellLib.doJailbreak super.tasty-hedgehog;
  tasty-hspec = self.callHackage "tasty-hspec" "1.2" {};
  tasty-discover = haskellLib.dontCheck super.tasty-discover;
  test-framework = haskellLib.doJailbreak super.test-framework;
  test-framework-quickcheck2 = haskellLib.doJailbreak super.test-framework-quickcheck2;
  base-orphans = self.callHackage "base-orphans" "0.8.6" {};
  dom-lt = haskellLib.markUnbroken super.dom-lt;
  # # Bump to fix build with ghcjs
  # network = self.callHackage "network" "3.1.2.1" {};
  # network-bsd = self.callHackage "network-bsd" "2.8.1.0" {};
  jsaddle = haskellLib.doJailbreak super.jsaddle; # allow newer base64-bytestring
  webdriver = haskellLib.overrideCabal super.webdriver (drv: {
    jailbreak = true;
    editedCabalFile = null;
    patches = [
      # aeson 2 support
      (pkgs.fetchpatch {
        url = "https://github.com/kallisti-dev/hs-webdriver/pull/183.patch";
        sha256 = "0wb6ynr13kbxqk9wpzw76q8fffs0kv1ddi7vlmwpnxxjsax98z89";
      })
    ];
  });
  th-compat = self.callHackage "th-compat" "0.1.3" {};
  OneTuple = self.callHackage "OneTuple" "0.3.1" {};
  validation = haskellLib.doJailbreak super.validation;
  validation-selective = haskellLib.dontCheck super.validation-selective;
  # base16 = self.callHackage "base16" "0.3.1.0" {};  # Not in all-cabal-hashes for GHC 9.6.7

  # ===========================================================================
  # Missing packages identified by comprehensive dependency analysis
  # Added: 2025-01-27
  # Source: docs/DEPENDENCY-ANALYSIS.md
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # From existing thunks (top-level /dep/)
  # ---------------------------------------------------------------------------
  aeson-gadt-th = haskellLib.dontCheck (
    self.callPackage ../generated-nix-expressions/aeson-gadt-th.nix {
      src = topLevelDeps.aeson-gadt-th;
    }
  );
  bytestring-aeson-orphans = self.callCabal2nix "bytestring-aeson-orphans" topLevelDeps.bytestring-aeson-orphans {};
  constraints-extras = self.callCabal2nix "constraints-extras" topLevelDeps.constraints-extras {};
  reflex = haskellLib.dontCheck (self.callCabal2nix "reflex" topLevelDeps.reflex {});
  reflex-gadt-api = self.callCabal2nix "reflex-gadt-api" topLevelDeps.reflex-gadt-api {};
  snap-core = self.callCabal2nix "snap-core" topLevelDeps.snap-core {};

  # ---------------------------------------------------------------------------
  # From obelisk monorepo (top-level dep/obelisk)
  # ---------------------------------------------------------------------------
  obelisk-backend = self.callCabal2nixWithOptions "obelisk-backend" topLevelDeps.obelisk "--subpath lib/backend" {};
  obelisk-frontend = self.callCabal2nixWithOptions "obelisk-frontend" topLevelDeps.obelisk "--subpath lib/frontend" {};
  obelisk-route = self.callCabal2nixWithOptions "obelisk-route" topLevelDeps.obelisk "--subpath lib/route" {};
  obelisk-executable-config-lookup = self.callCabal2nixWithOptions "obelisk-executable-config-lookup" topLevelDeps.obelisk "--subpath lib/executable-config/lookup" {};

  # ---------------------------------------------------------------------------
  # From rhyolite monorepo (cardano-project/dep/rhyolite)
  # ---------------------------------------------------------------------------
  rhyolite-beam-db = self.callCabal2nixWithOptions "rhyolite-beam-db" parentDeps.rhyolite "--subpath beam/db" {};
  rhyolite-beam-task-worker-backend = self.callCabal2nixWithOptions "rhyolite-beam-task-worker-backend" parentDeps.rhyolite "--subpath beam/task/backend" {};
  rhyolite-beam-task-worker-types = self.callCabal2nixWithOptions "rhyolite-beam-task-worker-types" parentDeps.rhyolite "--subpath beam/task/types" {};

  # ---------------------------------------------------------------------------
  # From new cardano-api thunk (dep/cardano-api)
  # CRITICAL: cardano-api doesn't exist in old cardano-node thunk
  # It's a separate repo: IntersectMBO/cardano-api
  # NOTE: This is a monorepo - package is in cardano-api/ subdirectory
  # NOTE: Using pre-generated .nix file because cardano-api requires cabal-version 3.8
  #       which is not supported by the cabal2nix available in nixpkgs.
  #       The .nix file was generated with modern cabal2nix (2.20.1) outside the build.
  # ---------------------------------------------------------------------------
  cardano-api = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/cardano-api.nix {
    # Pass src to point to the actual thunk instead of ./. from generated file
    src = topLevelDeps.cardano-api;
  });

  # ---------------------------------------------------------------------------
  # From Hackage - Core Dependencies
  # NOTE: All versions verified on Hackage 2025-01-27
  # NOTE: async 2.2.5 not in all-cabal-hashes, using fetchFromGitHub
  # ---------------------------------------------------------------------------
  reflex-dom = haskellLib.dontCheck (self.callHackage "reflex-dom" "0.6.3.4" {});
  reflex-dom-core = haskellLib.dontCheck (self.callCabal2nix "reflex-dom-core" (pkgs.fetchFromGitHub {
    owner = "reflex-frp";
    repo = "reflex-dom";
    rev = "56dcb9b1fac39f6624fe29b88d9a59af38e04956";  # tag reflex-dom-core-0.8.1.4
    sha256 = "09f3nk00vqk09h1l2gzalmm4dhhd2r7479xx2wvv9ng39d2yqhjr";
  }) {});
  async = haskellLib.dontCheck (self.callCabal2nix "async" (pkgs.fetchFromGitHub {
    owner = "simonmar";
    repo = "async";
    rev = "4a70b53c1ba90d8a59d6ec41a89337645c55b4cd";  # tag 2.2.5
    sha256 = "08f1k9bvjlsl0kkicmd2ixpnmkd3hqkbzb3iyhf2z2a8xxf820rs";
  }) {});
  dependent-sum = self.callCabal2nixWithOptions "dependent-sum" (pkgs.fetchFromGitHub {
    owner = "obsidiansystems";
    repo = "dependent-sum";
    rev = "43c633312b1d706a81a01c61cc3a33bdbe5530a3";  # tag v0.7.2.0
    sha256 = "1ndfllw7iqv9xayswfpw4qxx4b9920rmakyjnrdhrhjp576wkq1n";
  }) "--subpath dependent-sum" {};
  some = self.callCabal2nix "some" (pkgs.fetchFromGitHub {
    owner = "haskellari";
    repo = "some";
    rev = "7c7fd6a4e7cebc56394c51d02e5d4155edfcc52a";  # tag v1.0.6
    sha256 = "0i6qg6q5n04in2w5hqg70zycfzyfcc2mzb8bw7xrginrk1kb7l2m";
  }) {};

  # ---------------------------------------------------------------------------
  # From Hackage - Database (Beam + PostgreSQL)
  # NOTE: All versions verified on Hackage 2025-01-27
  # NOTE: beam-sqlite already defined earlier at line 332 (updated to 0.5.5.0)
  # ---------------------------------------------------------------------------
  postgresql-simple = haskellLib.dontCheck (self.callHackage "postgresql-simple" "0.7.0.1" {});
  resource-pool = self.callCabal2nix "resource-pool" (pkgs.fetchFromGitHub {
    owner = "scrive";
    repo = "pool";
    rev = "589954fcf7ffc2ff8e819cfdf0252f1173a99095";  # tag 0.5.0.0
    sha256 = "0isdmsi4mf2r03m4vi6baxxqqc3yac8wf06kahvnf1n68vpjswxi";
  }) {};
  beam-core = haskellLib.dontCheck (self.callHackage "beam-core" "0.10.4.0" {});
  beam-postgres = haskellLib.dontCheck (self.callCabal2nix "beam-postgres" (pkgs.fetchFromGitHub {
    owner = "haskell-beam";
    repo = "beam";
    rev = "bab3a2f952a880c14e79860b222a7536c83f686c";  # tag v0.10.3.1 (monorepo)
    sha256 = "18z3ygd40jdf7r29nqszcddhhqzg89gq0f6hz92n5y9jdgk3yyh4";
  }) {});
  beam-automigrate = haskellLib.dontCheck super.beam-automigrate;

  # ---------------------------------------------------------------------------
  # From Hackage - HTTP/Web
  # NOTE: All versions verified on Hackage 2025-01-27
  # ---------------------------------------------------------------------------
  http-client = self.callCabal2nixWithOptions "http-client" (pkgs.fetchFromGitHub {
    owner = "snoyberg";
    repo = "http-client";
    rev = "a0b418c12ff3c9878f21bff92bb174c239a9cfe3";  # tag http-client-0.7.19
    sha256 = "16wwy8l6bmwwpbblvaly7y6srxyjzbs3qa1rgdcpsyk3bj75alkl";
  }) "--subpath http-client" {};
  http-conduit = haskellLib.dontCheck (self.callCabal2nixWithOptions "http-conduit" (pkgs.fetchFromGitHub {
    owner = "snoyberg";
    repo = "http-client";
    rev = "a0b418c12ff3c9878f21bff92bb174c239a9cfe3";  # tag http-client-0.7.19 (monorepo)
    sha256 = "16wwy8l6bmwwpbblvaly7y6srxyjzbs3qa1rgdcpsyk3bj75alkl";
  }) "--subpath http-conduit" {});
  websockets = haskellLib.dontCheck (self.callCabal2nix "websockets" (pkgs.fetchFromGitHub {
    owner = "jaspervdj";
    repo = "websockets";
    rev = "cbba20b9e073e15e767052fc08b9e35cf8afb985";  # tag v0.13.0.0
    sha256 = "0bdkgc4ra5fbwhjhik28w4972mj0wdrp6ryb59a2gg5m0msr9jx4";
  }) {});
  websockets-snap = haskellLib.dontCheck (self.callHackage "websockets-snap" "0.10.3.1" {});
  snap-server = haskellLib.dontCheck (self.callCabal2nix "snap-server" (pkgs.fetchzip {
    url = "https://hackage.haskell.org/package/snap-server-1.1.2.1/snap-server-1.1.2.1.tar.gz";
    sha256 = "09v38gwn5h1d733r3dk4dbsh6gcl4bmx9d5p18pn9i7mvwyi8ycs";
  }) {});

  # ---------------------------------------------------------------------------
  # From Hackage - Utilities
  # NOTE: All versions verified on Hackage 2025-01-27
  # ---------------------------------------------------------------------------
  case-insensitive = self.callHackage "case-insensitive" "1.2.1.0" {};
  cryptonite = haskellLib.dontCheck (self.callHackage "cryptonite" "0.30" {});
  fsnotify = haskellLib.dontCheck (self.callCabal2nix "fsnotify" (pkgs.fetchFromGitHub {
    owner = "haskell-fswatch";
    repo = "hfsnotify";
    rev = "f780a2c9c8665402408683ac2c541c073fb76060";  # tag v0.4.4.0
    sha256 = "1w1cka6s04ma0510v1j9iwmcrfhiykfhfb2w3ygkfh7d14jffj1d";
  }) {});
  hexstring = haskellLib.dontCheck (self.callCabal2nix "hexstring" deps.haskell-hexstring {});
  io-streams = haskellLib.dontCheck (self.callHackage "io-streams" "1.5.2.2" {});
  logging-effect = self.callHackage "logging-effect" "1.4.1" {};
  # managed 1.0.10 (from Hackage tarball directly, not in all-cabal-hashes archive)
  managed = self.callCabal2nix "managed" (pkgs.fetchzip {
    url = "https://hackage.haskell.org/package/managed-1.0.10/managed-1.0.10.tar.gz";
    sha256 = "15mcc8n3hyia029vd8b4gaa3g3kk4v9zdp8fbj1mq86gdl2yynzz";
    stripRoot = true;
  }) {};
  monad-logger = haskellLib.dontCheck (self.callCabal2nix "monad-logger" (pkgs.fetchFromGitHub {
    owner = "snoyberg";
    repo = "monad-logger";
    rev = "04a87e9838ee5a4e8555249d665440a408ca4635";  # tag monad-logger-0.3.40 (closest to 0.3.42)
    sha256 = "1zbnikf5f5zl9fgzn1x54yzv0aq2gmxa3715sq4b7fibp8pxgdfm";
  }) {});
  monad-loops = self.callHackage "monad-loops" "0.4.3" {};
  network = self.callCabal2nix "network" (pkgs.fetchFromGitHub {
    owner = "haskell";
    repo = "network";
    rev = "86f33ca2d31221c18afc787da4d6ea718616d261";  # tag v3.2.8.0
    sha256 = "02kw61v5l9ngrpjylzx6yqpivv97phqjdzl4nrhgjjdckxa3l021";
  }) {};
  prettyprinter = self.callHackage "prettyprinter" "1.7.1" {};
  temporary = self.callHackage "temporary" "1.3" {};
  typed-process = haskellLib.dontCheck (self.callCabal2nix "typed-process" (pkgs.fetchFromGitHub {
    owner = "fpco";
    repo = "typed-process";
    rev = "d5e9fb30b203721c62974bae6bc1d2be474caae8";  # tag typed-process-0.2.11.1 (closest to 0.2.13.0)
    sha256 = "03p0si8k059hf2mvczxz6525gsb34jbis4y4n9x7khqprz5cmzi5";
  }) {});
  utf8-string = self.callHackage "utf8-string" "1.0.2" {};
  uuid = self.callCabal2nixWithOptions "uuid" (pkgs.fetchFromGitHub {
    owner = "haskell-hvr";
    repo = "uuid";
    rev = "45e9e5df24b05dccc2b89729d75e4c96d668fc59";  # tag uuid-1.3.16
    sha256 = "1pmkrz9bs67hw2z4b68q85a9mrq3ycrgl5n8dnvnrvvzv2d39yk1";
  }) "--subpath uuid" {};
  which = haskellLib.dontCheck (self.callCabal2nix "which" (pkgs.fetchFromGitHub {
    owner = "obsidiansystems";
    repo = "which";
    rev = "e2a87735fb5af72f9ef28ec9c39bb54f3cd318f7";  # tag v0.2.0.3
    sha256 = "05kf7qx7jfx7b9s4k6wy4h3bp1498bilxnywjy4nsrxlwczz5vca";
  }) {});

  # ---------------------------------------------------------------------------
  # From Hackage - Gargoyle (may also be in rhyolite/obelisk)
  # Note: Check if these exist in monorepos; if yes, use those versions
  # NOTE: All versions verified on Hackage 2025-01-27
  # ---------------------------------------------------------------------------
  gargoyle = haskellLib.dontCheck (self.callCabal2nixWithOptions "gargoyle" (pkgs.fetchFromGitHub {
    owner = "obsidiansystems";
    repo = "gargoyle";
    rev = "66324bf0cd71567fc7264ed68887d22e9862340a";  # tag gargoyle-0.1.2.2
    sha256 = "1pypnciq6zwvm0zg8svxqk4daf86y19pz751n6n54z4zvm29gxzl";
  }) "--subpath gargoyle" {});
  gargoyle-postgresql = haskellLib.dontCheck (self.callCabal2nixWithOptions "gargoyle-postgresql" (pkgs.fetchFromGitHub {
    owner = "obsidiansystems";
    repo = "gargoyle";
    rev = "24feb5a687703dcd006e39a33259356f7314338a";  # tag gargoyle-postgresql-0.2.0.4
    sha256 = "17khmz4nc9hxk15wx0ag4i6qmc8jim768cczd1h6y76nfm07i9nc";
  }) "--subpath gargoyle-postgresql" {});
  gargoyle-postgresql-connect = haskellLib.dontCheck (self.callCabal2nixWithOptions "gargoyle-postgresql-connect" (pkgs.fetchFromGitHub {
    owner = "obsidiansystems";
    repo = "gargoyle";
    rev = "00ba66f3b0e9876e44cf1b7f02c856e808bd5c13";  # tag gargoyle-postgresql-connect-0.1.0.4
    sha256 = "0sbayyw51382nvqm521r985ha7jqkm09zpjz50kd74dq11gbfizl";
  }) "--subpath gargoyle-postgresql-connect" {});
  gargoyle-postgresql-nix = haskellLib.dontCheck (self.callCabal2nixWithOptions "gargoyle-postgresql-nix" (pkgs.fetchFromGitHub {
    owner = "obsidiansystems";
    repo = "gargoyle";
    rev = "7b196a9bd0e77997abcce2e2d90fb1a1fc9c3065";  # tag gargoyle-postgresql-nix-0.3.0.4
    sha256 = "0dz4adslpp3q71s11igcsxk00d0dmnh435y06pxp1zz736qaxx8k";
  }) "--subpath gargoyle-postgresql-nix" {});
}
