#!/bin/sh
# Host keys come from the old device's public key through the fixture exchange.
# Refuse unexpected prompts instead of answering yes to an unverified host key.
case "$1" in
    *passphrase*) printf 'fixture-device-passphrase\n' ;;
    *) exit 1 ;;
esac
