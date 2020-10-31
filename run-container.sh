#!/usr/bin/env bash

mkdir $HOME/.ts3client
podman run -it --rm -e PULSE_SERVER=unix:$XDG_RUNTIME_DIR/pulse/native \
					-e DISPLAY=unix$DISPLAY \
					-v /tmp/.X11-unix:/tmp/.X11-unix \
					-v $XDG_RUNTIME_DIR/pulse:$XDG_RUNTIME_DIR/pulse:ro \
					-v $HOME/.config/pulse/cookie:$HOME/.config/pulse/cookie:ro \
					-v $HOME/.ts3client:/root/.ts3client:shared \
					--name test-ts3 ts3pod bash
