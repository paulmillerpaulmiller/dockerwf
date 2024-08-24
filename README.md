# Docker Command Line Cheat Sheet 

Docker virtualizes the file system.  Unlike a virtual machine, it does not virtualize the CPU or instructions.

A Docker **image** is like a hard drive image.  A Docker **container** is a running instance like a virtual machine.  In some conversations the word "container" may be used interchangeably when the word "image" is intended from the context.  

### Why does this exist?  What problem does docker solve? 

Linux is a clone of Unix.  In the Linux ecosystem, there is <a href="https://upload.wikimedia.org/wikipedia/commons/1/1b/Linux_Distribution_Timeline.svg">an eff-ton of different Linux distributions</a>.  There are also a ton of packages and libraries each with many versions.  Too often one package version has a conflict with another package version. A library can be over-written with an incompatible version (e.g. sudo make install), and thus make software applications broken.  In Windows this is called "DLL Hell".   

Docker solves package and library conflicts for Linux.  

For a team of software developers, Docker ensures that every contributor has exactly the same packages and library versions as the rest of the team.  No one on the team can say "it works on my machine, I don't know why it doesn't work on yours".  

Docker is also a way to deploy software applications with all dependency package versions under control. Docker is also a way to distribute components in the cloud.




| Use-Case                 | Command Line  | 
| :------------            |:---------------| 
| **Build** a docker image from a Dockerfile. | `docker build <args ...>` <br>1. The current directory is the “context” where the Dockerfile and artifacts exist. <br>2. In the Dockerfile, each RUN command is effectively an independent shell session. |
| **Run** a docker container from a docker image, and keep it running with an **interactive** bash shell.  | `docker run -it <args ...> bash "$@"` |
|  **Run one command** inside the container, and then exit out of the container and delete the container so its not residual. |  `docker run -rm <args ...> bash -c "$@"`  |
| **Run one command** inside the container, and then exit out of the container but don't delete the container. |  `docker run <args ...> bash -c "$@"`  |
|  <br> |    |
|  **Create** a container from an image.  The container is not in the running state yet. | `docker create <args ...>`<br>See command line ingredients below |
|  <br> |    |
|  **Run** a container interactively.  The container was already created using docker create, but its not in the running state yet.  | `docker start <containername>`<br>`docker exec -it <args ... containername> bash "$@"`<br>See command line ingredients below |
|  <br> |    |
|  List docker images | `docker images`  |
|  List docker containers | `docker ps -a` |
|  Stop a container from running. | `docker stop <container ID>` |
|  Clean up and delete containers | `docker rm <container ID>` |
|  Clean up and delete images | `docker rmi <image ID>`  |
|  <br> |    |



| Command Line Ingredients | args  | 
| :------------            |:---------------| 
|  <br> | Some args could be in any order, other args might be in a specific position. For example the last arg, or second-to-last arg. |
|  **Volume mounting.**  Directories from the host machine can be mounted in the container. This includes any file or device in file system so its usable inside the container. | `-v source:dest`   |
|  **Network.**  Use the host machine's network. | `--network host` <br>`--net host`    |
|  **Network.**  Isolate, or open only specific ports, or map to different ports. | `-p port:port` |
|  **User**. By default, inside the container, the user is root. You can do all kinds of messy Unix things inside the container. Setup the user in the Dockerfile, and specify the username when running the container, in order to make the experience less messy. |  `--user username`  |
|  **Container Name** |  Sometimes the second-to-last arg on the command line, other times its explicit with <br>`--name containername`  |
| **Image Name** | Sometimes maybe the second-to-last arg on the command line, other times its explicit maybe with `-t imagename`   |
|  **Environment Variables** | `-e environmentvariable`   |
|  **Working Directory** |  `-w workingdirectory`  |


<br>

### Example Dockerfile, and Build the Docker Image
Dockerfile
```
FROM ubuntu:24.04

ARG ARG_USERID
ARG ARG_USER

# Add the user from the host
RUN useradd -m $ARG_USER -u $ARG_USERID -s /bin/bash && \
    passwd -d $ARG_USER && \
    usermod -aG sudo $ARG_USER 

CMD ["bash"]
```
Command line to build the image.  Note the '.' at the end of the command line to indicate the context.  Typically you would run this command from the same directory that the Dockerfile exists in. 
```
  # This adds you as the user inside the container.
  docker build \
    -f "${DOCKERFILE}" \
    --build-arg ARG_USERID="${USERID}" \
    --build-arg ARG_USER="${USER}" \
    -t "${IMAGENAME}" \
    --target "${IMAGENAME}" .
```

<br>

### Example Create the Container from the Image
```
  docker create -it \
    --name "${CONTAINERNAME}" \
    --net host \
    --privileged \
    --shm-size 4G \
    --user "${USER}" \
    -v "${HOME}/:${HOME}" \
    -v "${HOME}/.bashrc:${HOME}/.bashrc" \
    -v "${HOME}/.bash_history:${HOME}/.bashrc_history" \
    -v "${HOME}/.vimrc:${HOME}/.vimrc" \
    -v /etc/hosts:/etc/hosts \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /var/run/dbus:/var/run/dbus \
    -e "DISPLAY=${DISPLAY}" \
    -e CONTAINER_NAME="${CONTAINERNAME}" \
    -h "${CONTAINERNAME}" "${IMAGENAME}"
```

<br>

### Example Start the Container Running
```
  [ ! "$(docker ps -aq -f name=${CONTAINERNAME} -f status=running)" ] && docker start "${CONTAINERNAME}"
```

<br>

### Examples of Running the Container
Run the container like a server daemon.
```
    docker run -d --restart unless-stopped \
      --shm-size 4G \
      --user "${USER}" \
      ${SERVERARGS} \
      -v "${HOME}/:${HOME}" \
      -w "${HOME}" \
      --name "${CONTAINERNAME}" "${IMAGENAME}"
```

When there is no command given, run interactively, and use bash shell inside the container. 
```
    if [ $# == 0 ]; then
        docker exec -it -w "$(pwd)" "${CONTAINERNAME}" bash "$@"
    fi
```

When a command or script is specified, run the command or script inside the container.
```   
    if [ $# -ne 0 ]; then
      docker exec -it -w "$(pwd)" "${CONTAINERNAME}" bash -c "$@"
    fi
```

<br>

### Example Stop the Container and Delete the Container
```
  [ "$(docker ps -aq -f name=${CONTAINERNAME} -f status=running)" ] && \
    docker stop "${CONTAINERNAME}" >/dev/null; 

  docker rm "${CONTAINERNAME}" >/dev/null
```


<br>

### Example Delete the Container and the Image
```
  [ "$(docker ps -aq -f name=${CONTAINERNAME} -f status=running)" ] && \
    docker stop $CONTAINERNAME

  [ "$(docker ps -aq -f name=${CONTAINERNAME})" ] && docker rm $CONTAINERNAME

  docker rmi -f $IMAGENAME
```

