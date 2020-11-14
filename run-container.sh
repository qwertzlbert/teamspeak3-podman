#!/usr/bin/env bash

mkdir -p $HOME/.ts3client
podman unshare chown -R 1600:1600 $HOME/.ts3client
podman run -it --rm -e DISPLAY=unix$DISPLAY \
					-v /tmp/.X11-unix:/tmp/.X11-unix \
					-v $XDG_RUNTIME_DIR/pulse/pulse-socket:/tmp/pulse-socket \
					-v $HOME/.config/pulse/pulse-cookie:/tmp/pulse-cookie:ro \
					-v $HOME/.ts3client:/home/ts3_user/.ts3client:shared \
					--name ts3-container ts3pod:latest bash
