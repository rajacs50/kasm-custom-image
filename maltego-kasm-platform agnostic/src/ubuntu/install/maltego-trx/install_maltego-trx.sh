#!/usr/bin/env bash
set -ex

# Install Maltego-TRX
apt-get update
mkdir -p $HOME/maltego
cd $HOME/maltego
apt-get update
apt-get install -y python3-setuptools \
                   python3-venv \
                   python3-virtualenv
python3 -m venv env
. env/bin/activate
pip install --upgrade pip
pip install maltego-trx