#   SteamCMD Minimal Docker Image.
#   Copyright (C) 2021-2022 Renegade-Master [renegade.master.dev@protonmail.com]
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

#######################################################################
#   Author: Renegade-Master
#   Description: Base image for a Steam CMD minimal install.
#   License: GNU General Public License v3.0 (see LICENSE)
#######################################################################

# Base Image
ARG BASE_IMAGE="ubuntu:kinetic-20220602"

# Download a small base image to start with
FROM ${BASE_IMAGE} as downloader

# Install Steam dependencies
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
FROM ${BASE_IMAGE} as installer

# Add label metadata
LABEL com.renegademaster.steamcmd-minimal.authors="Renegade-Master" \
    com.renegademaster.steamcmd-minimal.source-repository="https://github.com/Renegade-Master/steamcmd-minimal" \
    com.renegademaster.steamcmd-minimal.image-repository="https://hub.docker.com/repository/docker/renegademaster/steamcmd-minimal"

COPY --from=outdead/rcon:0.10.2 /rcon /bin/rcon

# Set local working directory
WORKDIR /home/steam

# Install Steam dependencies, and trim image bloat
RUN apt-get update && apt-get autoremove -y \
    && apt-get install -y --no-install-recommends \
        lib32stdc++6 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the Steam installation from the previous build stage
COPY --from=downloader /app /home/steam

# Copy only the essential libraries required for Steam to function
COPY --from=downloader [ \
    "/usr/lib/i386-linux-gnu/libthread_db.so.1", \
    "/usr/lib/i386-linux-gnu/libSDL2-2.0.so.0.22.0", \
    "/usr/lib/i386-linux-gnu/" \
]

# Link the libraries and executables so that they can be found
# Make a Steam User, and change the ownership of the Steam directory
RUN mkdir -p /home/steam/.steam/sdk64 \
    && ln -s /usr/lib/i386-linux-gnu/libSDL2-2.0.so.0.22.0 /usr/lib/i386-linux-gnu/libSDL2-2.0.so.0 \
    && ln -s /home/steam/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so \
    && ln -s /home/steam/steamcmd.sh /usr/bin/steamcmd.sh
