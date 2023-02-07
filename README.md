# Steam CMD - Minimal

## Disclaimer

**Note:** This image is not officially supported by Valve.

If issues are encountered, please report them on
the [GitHub repository](https://github.com/Renegade-Master/steamcmd-minimal/issues/new/choose)

## Badges

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/renegademaster/steamcmd-minimal?label=Latest%20Version)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/renegademaster/steamcmd-minimal?label=Image%20Size)
![Docker Pulls](https://img.shields.io/docker/pulls/renegademaster/steamcmd-minimal?label=Docker%20Pull%20Count)

## Description

Docker image containing the latest Steam CMD Linux Binary. Use as a base for other images.  
Built from scratch to be the smallest Steam CMD Docker image around!

## Links

Source:

- [GitHub](https://github.com/Renegade-Master/steamcmd-minimal)
- [GitHub Packages](https://github.com/users/Renegade-Master/packages/container/package/steamcmd-minimal)
- [DockerHub](https://hub.docker.com/r/renegademaster/steamcmd-minimal)
- [Red Hat Quay](https://quay.io/repository/renegade_master/steamcmd-minimal)

Resource links:

- [Steam CMD Wiki](https://developer.valvesoftware.com/wiki/SteamCMD)

## Instructions

### Docker

The following are instructions for including this image as the base image for the Steam Dedicated Server that you can
create based on this image.

**Note:** To make calling Steam CMD easier, the `steamcmd.sh` script has been added to the environment's `PATH`
variable. If you need to access the files anyway, the location Steam was installed to is in the `STEAMDIR` Environment
variable.

1. Create a Dockerfile with the following contents:

   ```dockerfile
   FROM docker.io/renegademaster/steamcmd-minimal:<tag>
   
   # Add your own instructions here
   ```

2. You can then install a game server in one of several ways:

    * Install the game by adding additional Docker `RUN` instructions to the Dockerfile:

        ```dockerfile
        FROM docker.io/renegademaster/steamcmd-minimal:<tag>
        
        # Download the Satisfactory Dedicated Server
        RUN steamcmd.sh +login anonymous +app_update 1690800 validate +quit
        ```

    * Alternatively, you can create a Steam CMD script and copy it into the `/home/steam` directory. This script can
      then be run when the container is started:

        ```dockerfile
        FROM docker.io/renegademaster/steamcmd-minimal:<tag>
        
        # Copy the steamcmd script into the container
        COPY install.scmd /home/steam/install.scmd
      
        # Run the steamcmd script
        ENTRYPOINT steamcmd.sh +runscript install.scmd
        ```

    * Lastly, you can always create a Shell Script and copy it into the container to handle running more complex
      commands:

        ```dockerfile
        FROM docker.io/renegademaster/steamcmd-minimal:<tag>
       
        # Copy the steamcmd script into the container
        COPY setup_script.sh /home/steam/setup_script.sh
     
        # Run the steamcmd script
        ENTRYPOINT ["/bin/bash", "/home/steam/setup_script.sh"]
        ```

## Versions (root?)

Two versions of this image exist (alongside `latest`). The difference between the two are the access rights granted to
the end image User. Images ending in `*-root` retain the `root` user and can install packages, or do other admin
activities. Images without this suffix contain a `steam` user instead. This user cannot install packages, but is safer
to use.

### Standard

#### Build command

```shell
docker build \
  --tag docker.io/renegademaster/steamcmd-minimal:<tag> \
  --file docker/steamcmd-minimal.Dockerfile \
  .
```

### Root

#### Build command

```shell
docker build \
  --tag docker.io/renegademaster/steamcmd-minimal:<tag> \
  --file docker/steamcmd-minimal.Dockerfile \
  --build-arg UID=0 --build-arg GID=0 --build-arg USER=root \
  .
```
