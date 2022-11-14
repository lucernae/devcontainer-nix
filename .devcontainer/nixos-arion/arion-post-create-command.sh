#!/usr/bin/env bash
docker-compose exec -T devcontainer bash -c "systemctl start nix-daemon && systemctl start dbus && nix-channel --update"