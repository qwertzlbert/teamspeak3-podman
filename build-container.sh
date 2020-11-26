#!/usr/bin/env bash

GETOPT=/usr/bin/getopt
PROG=${0##*/}

pkgver=3.5.6
sha512sum='57c618d386023d27fcb5f6b7e5ce38fe7012680988aff914eeb6c246d855b190689bbad08d9824c864c1776af322e8df34019234128beb306a09b114673b37c9'
 
function usage ()
{
cat <<EOF
usage: $PROG [options] 
$PROG will build a podman container containing teamspeak client. Audio is passed through using 
a shared pulseaudio socket. Video is shared by sharing the X11 socket.
Please see https://gitlab.com/qwertzlbert/teamspeak3-podman for more details
 
  Options:
    -h,--help          print this help message.
    -n,--name [param]  define the image name to use (optional) (default: "ts3pod")
    -u,--uid [param]   define the uid to use (optional) (default: 1600)
EOF
}

# process and assign command line arguments
_temp=$($GETOPT -o hn::u:: --long help,name::,uid:: -n $PROG -- "$@")
if [ $? != 0 ] ; then echo "bad command line options" >&2 ; exit 1 ; fi
eval set -- "$_temp"

_OPT_NAME="ts3pod"
_OPT_UID=1600
 
while true ; do
        case "$1" in
        -h|--help)
                        usage; exit 0 ;;

        -n|--name)
                        if [[ -z "$2" ]]; then
                                _OPT_NAME="ts3pod"
                        else
                                _OPT_NAME=$2
                        fi
                        shift 2; continue ;;
        -u|--uid)
                        if [[ -z "$2" ]]; then
                                _OPT_UID=1600
                        else
                                _OPT_UID=$2
                        fi
                        shift 2; continue ;;
        *)
            break
            ;;
        esac
done


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
buildah run $crt useradd --create-home -u $_OPT_UID -d /home/ts3_user ts3_user
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

buildah commit $crt $_OPT_NAME
