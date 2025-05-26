#!/usr/bin/env bash
set -ex

# Copy the qTDS Files
mkdir -p $HOME/maltego/qtds
qtds.zip $HOME/maltego/qtds
apt-get update && apt-get install -y unzip
unzip $HOME/maltego/qtds/qtds.zip -d $HOME/maltego/qtds/
rm $HOME/maltego/qtds/qtds.zip
