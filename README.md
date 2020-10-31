# Overview

This repository contains a bash script leveraging [buildah](https://buildah.io/) to 
create a podman container running a TeamSpeak3 Client. 

If subuid and subgid is configured correctly, this will also work with non privileged containers.

This is only tested for X11 environments and might not run with Wayland!

# Files

`build-container.sh`: Builds and commits Podman container via buildah

`pulse-client.conf`: Pulseaudio client configuration to use host audio device as audio source

`run-container.sh`: Example script to run previously build ts3 container as `ts3pod`. Persistent files will be shared on
`$HOME/.ts3client` on host. 

 
## Comment

Thanks to @fadams for giving examples sharing audio and display ressources with containers. Especially:
	- https://github.com/TheBiggerGuy/docker-pulseaudio-example/issues/1
	- https://github.com/fadams/docker-gui
	
