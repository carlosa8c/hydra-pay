# DO NOT HAND-EDIT THIS FILE
let fetch = { private ? false, fetchSubmodules ? false, owner, repo, rev, sha256, ... }:
  if !fetchSubmodules && !private then builtins.fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz"; inherit sha256;
  } else (import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/47585496bcb13fb72e4a90daeea2f434e2501998.tar.gz";
  sha256 = "sha256-b/ScqkWZ+0ItQ5c4QFDbYW+DwjKQxR8KVi+gVOlNf1c=";
}) {}).fetchFromGitHub {
    inherit owner repo rev sha256 fetchSubmodules private;
  };
  json = builtins.fromJSON (builtins.readFile ./github.json);
in fetch json