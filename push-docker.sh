#!/usr/bin/env bash

# Uses carlosa8c/hydra-pay:REVISION by default:
VERSION=${1:-$(git rev-parse HEAD)}
NAME="carlosa8c/hydra-pay"

docker load < $(nix-build release.nix -A dockerImage --no-out-link --argstr version $VERSION --argstr name $NAME)
docker push $NAME:$VERSION
