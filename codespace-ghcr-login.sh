#!/usr/bin/env bash

echo $GHCR_PASSWORD | docker login ghcr.io -u $GHCR_USERNAME --password-stdin