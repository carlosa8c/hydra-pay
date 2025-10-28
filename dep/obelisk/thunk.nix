# DO NOT HAND-EDIT THIS FILE
let fetch = { private ? false, fetchSubmodules ? false, owner, repo, rev, sha256, ... }:
  if !fetchSubmodules && !private then builtins.fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz"; inherit sha256;
  } else (import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/47585496bcb13fb72e4a90daeea2f434e2501998.tar.gz";
  sha256 = "1fpbqk3byh8zk2h2r4kckqpzqk34s46n6fq5fxwh4fm6x7p55vwv";
}) {}).fetchFromGitHub {
    inherit owner repo rev sha256 fetchSubmodules private;
  };
  json = builtins.fromJSON (builtins.readFile ./github.json);
in fetch json
