#######################################################################
#   Author: Renegade-Master
#   Description: Base image for a Steam CMD minimal install.
#   License: GNU General Public License v3.0 (see LICENSE)
#######################################################################

# Set the User and Group IDs
ARG USER_ID=1000
ARG GROUP_ID=1000

# Download a small base image to start with
FROM ubuntu:impish as downloader

# Install dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get autoremove -y \
    && apt-get install -y \
        wget libsdl2-2.0-0:i386

# Set local working directory
WORKDIR /app

# Download and extract Steam
RUN wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    && tar -zxf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz

# Start again with a small base image
FROM alpine:3.15.0 as installer

# Copy the User and Group IDs from the previous stage
ARG USER_ID
ARG GROUP_ID
ARG STEAM_DEFAULT_PATH=/home/steam/steamcmd.sh

ENV STEAM_PATH=${STEAM_DEFAULT_PATH}

# Add label metadata
LABEL com.renegademaster.steamcmd-minimal.authors="Renegade-Master" \
    com.renegademaster.steamcmd-minimal.source-repository="https://github.com/Renegade-Master/steamcmd-minimal" \
    com.renegademaster.steamcmd-minimal.image-repository="https://hub.docker.com/repository/docker/renegademaster/steamcmd-minimal"

# Set local working directory
WORKDIR /home/steam

# Copy the Steam installation from the previous build stage
COPY --from=downloader /app /home/steam

# Copy Certs
COPY --from=downloader /etc/ssl/certs /etc/ssl/certs

# Copy only the essential libraries required for Steam to function
COPY --from=downloader [ \
    "/usr/lib/i386-linux-gnu/libpthread.so.0", \
    "/usr/lib/i386-linux-gnu/libthread_db.so.1", \
    "/usr/lib/i386-linux-gnu/libSDL2-2.0.so.0.14.0", \
    "/usr/lib/i386-linux-gnu/" \
]

# Link the libraries and executables so that they can be found
# Make a Steam User, and change the ownership of the Steam directory
RUN mkdir -p /home/steam/.steam/sdk64 \
    && ln -s /usr/lib/i386-linux-gnu/libSDL2-2.0.so.0.14.0 /usr/lib/i386-linux-gnu/libSDL2-2.0.so.0 \
    && ln -s /home/steam/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so \
    && adduser --disabled-password -u ${USER_ID} -h /home/steam steam \
    && chown -R ${USER_ID}:${GROUP_ID} /home/steam

# Switch to the Steam User
USER ${USER_ID}:${GROUP_ID}
