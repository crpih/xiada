#!/usr/bin/env bash

cd training/bin
make galician_xiada_escrita galician_xiada_oral spanish_eslora
cd ../..

DOCKER_BUILDKIT=1 docker build --ssh default -t xiada_tagger:latest .
