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
ARG BASE_IMAGE="docker.io/ubuntu:kinetic-20230126"
ARG RCON_IMAGE="docker.io/outdead/rcon:0.10.2"
ARG UID=1000
ARG GID=1000
ARG USER=steam

FROM ${RCON_IMAGE} as rcon

# Download a small base image to start with
FROM ${BASE_IMAGE} as downloader

# Install Steam dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get autoremove -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates=20211016ubuntu0.22.10.1 \
        ibsdl2-2.0-0:i386=2.24.0+dfsg-1 \
        wget=1.21.3-1ubuntu1

# Set local working directory
WORKDIR /app

# Download and extract Steam
RUN wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    && tar -zxf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz

# Start again with a small base image
FROM ${BASE_IMAGE} as installer
ARG UID
ARG GID
ARG USER
ARG RCON_IMAGE

ENV USER="${USER}"
ENV STEAMDIR="/home/${USER}/.local/steamcmd"

# Add label metadata
LABEL com.renegademaster.steamcmd-minimal.authors="Renegade-Master" \
    com.renegademaster.steamcmd-minimal.source-repository="https://github.com/Renegade-Master/steamcmd-minimal" \
    com.renegademaster.steamcmd-minimal.image-repository="https://hub.docker.com/repository/docker/renegademaster/steamcmd-minimal"

COPY --from=rcon /rcon /usr/bin/rcon

# Install Steam dependencies, trim image bloat
RUN apt-get update && apt-get autoremove -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates=20211016 \
        lib32stdc++6=12.2.0-3ubuntu1 \
        musl=1.2.3-1 \
    && apt-get remove --purge --auto-remove -y \
    && rm -rf /var/lib/apt/lists/*

# Create runtime user
RUN if [ $USER != "root" ]; then \
      printf "Running as standard user"; \
      groupadd "${USER}" \
        --gid "${GID}"; \
      useradd "${USER}" --create-home \
        --uid "${UID}" \
        --gid "${GID}" \
        --home-dir /home/${USER}; \
    else \
      printf "Running as root user"; \
    fi

# Copy the Steam installation from the previous build stage
COPY --from=downloader --chown=${UID}:${GID} /app/ ${STEAMDIR}

# Copy only the essential libraries required for Steam to function
COPY --from=downloader [ \
    "/usr/lib/i386-linux-gnu/libthread_db.so.1", \
    "/usr/lib/i386-linux-gnu/libSDL2-2.0.so.0.2400.0", \
    "/usr/lib/i386-linux-gnu/" \
]

# Link the libraries and executables so that they can be found
RUN mkdir -p /home/steam/.steam/sdk64 \
    && ln -s /usr/lib/i386-linux-gnu/libSDL2-2.0.so.0.2400.0 /usr/lib/i386-linux-gnu/libSDL2-2.0.so.0 \
    && ln -s /home/steam/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so

# Set local working directory
WORKDIR /home/${USER}
USER ${USER}
