#!/bin/bash
psgi=$(basename ${1:-simple} .psgi).psgi
cd $(dirname $0)
exec plackup -R lib eg/$psgi
