#!/usr/bin/env bash

echo

# Confirm policy.json exits
if [ ! -f ~/.config/containers/policy.json ]; then
    if gum confirm "Create podman policy file?" --default=true --affirmative "Yes" --negative "No"; then
        printf '%s\n' '{"default": [{"type": "insecureAcceptAnything"}]}' > ~/.config/containers/policy.json
        echo "✅ Podman policy created at ~/.config/containers/policy.json"
    fi
fi

# Ensure podman can run
if [ "$(uname -s)" = 'Linux' ] || [ "$(podman machine ssh -- uname -s)" = "Linux" ]; then
    echo "🍟 Podman is available."
    return 0
fi

# We need a virtual machine
autostart="$HOME/.config/podman-env/autostart"
choice=
if [ ! -f "$autostart" ]; then
    echo "Would you like to create and start the Podman virtual machine?"
    choice=$(gum choose "Always - start now & on future activations" "Yes - start now only" "No - do not start")
    if [ "${choice:0:1}" = "A" ]; then
        mkdir -p "$HOME"/.config/podman-env
        echo "1" > "$autostart"
        echo
        echo "Machine will start automatically on next activation. To disable this, run:"
        echo "  rm $autostart"
    fi
fi

if [ -f "$autostart" ] || [ "${choice:0:1}" = "A" ] || [ "${choice:0:1}" = "Y" ] ; then
    gum spin --spinner dot --show-output --title "Initializing machine..." -- podman machine init 2>&1 || true
    gum spin --spinner dot --show-output --title "Starting machine..." -- podman machine start 2>&1
    if [ "$(podman machine ssh -- uname -s)" = "Linux" ]; then
        trap 'podman machine stop' EXIT
        echo "✅ Podman virtual machine started - stop it with 'podman machine stop' or exit this shell."
        return 0
    fi
fi

echo "🚨 Podman is not available."
