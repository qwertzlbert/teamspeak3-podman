#!/usr/bin/env bash

#podman run -it --rm -e PULSE_SERVER=unix:$XDG_RUNTIME_DIR/pulse/native -e DISPLAY=unix$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $XDG_RUNTIME_DIR/pulse:$XDG_RUNTIME_DIR/pulse:ro -v $HOME/.config/pulse/cookie:$HOME/.config/pulse/cookie:ro  $HOME/.ts3client:/root/.ts3client:shared --name test-ts3 ts3pod bash

pkgver=3.5.3
sha512sum='8b0ea835b179596ec16c092790383691650f6cb92b97d4ab2012872edc2f4d82e0b3a3ea4551651c4824703b9ef01ba9c95a50ee262d5f279151d780dc3faef6'
crt=$(buildah from ubuntu)

buildah run $crt apt-get update

# ad flag to allow silent install as it is asking for location
buildah run $crt env DEBIAN_FRONTEND=noninteractive apt-get install -y \
					curl \
					sudo \
					pulseaudio-utils \
					software-properties-common \
					libgl1-mesa-glx \
					libnss3 \
					libfreetype6 \
					libfontconfig1 \
					libxcomposite1 \
					libxcursor1 \
					libxi6 \
					libxtst6 \
					libxss1 \
					libpci3 \
					libasound2 \
					libxslt1.1 \
					xcb \
					qt5-default \
					x11-xserver-utils \
					--no-install-recommends \
					&& rm -rf /var/lib/apt/lists/*
buildah copy $crt pulse-client.conf /etc/pulse/client.conf

# setup spotify user and pulseaudio
buildah run $crt useradd --create-home -u 1600 -d /home/ts3_user ts3_user
buildah run $crt gpasswd -a ts3_user audio 
buildah run $crt chown -R ts3_user:ts3_user /home/ts3_user

# setup teamspeak
buildah run $crt mkdir -p /opt/bin/ts3
buildah run $crt curl "https://files.teamspeak-services.com/releases/client/${pkgver}/TeamSpeak3-Client-linux_amd64-${pkgver}.run" --output /opt/bin/ts3/teamspeak3.run
buildah run $crt env sha512sum=$sha512sum bash -c 'echo "$sha512sum /opt/bin/ts3/teamspeak3.run" | sha512sum --check --status'
buildah run $crt chmod +x /opt/bin/ts3/teamspeak3.run
buildah run $crt bash -c 'yes | /opt/bin/ts3/teamspeak3.run'

buildah config --entrypoint "cp -a /tmp/pulse-cookie /tmp/pulse-ts3-cookie && \
							chown ts3_user:ts3_user /tmp/pulse-ts3-cookie && \
							xhost local:root && \
							sudo -u ts3_user \
							PULSE_COOKIE=/tmp/pulse-ts3-cookie \
							PULSE_SERVER=unix:/tmp/pulse-socket /TeamSpeak3-Client-linux_amd64/ts3client_runscript.sh" \
							$crt

buildah commit $crt ts3pod
