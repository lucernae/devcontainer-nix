#!/bin/sh
# Workaround script to create FHS symlinks before starting systemd
# This is needed because NixOS doesn't have /bin/sh by default

# Create essential symlinks if they don't exist
if [ ! -f /bin/sh ]; then
    mkdir -p /bin /usr/bin /usr/sbin
    ln -sf /run/current-system/sw/bin/bash /bin/bash
    ln -sf /run/current-system/sw/bin/bash /bin/sh
    ln -sf /run/current-system/sw/bin/bash /usr/bin/bash
    ln -sf /run/current-system/sw/bin/bash /usr/bin/sh
    ln -sf /run/current-system/sw/bin/env /usr/bin/env
    ln -sf /run/current-system/sw/bin/env /bin/env
fi

# Start systemd init
exec /usr/sbin/init
