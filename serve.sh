#!/bin/bash
psgi=$(basename ${1:-simple} .psgi).psgi
cd $(dirname $0)
exec plackup -o 127.0.0.1 -R lib eg/$psgi
