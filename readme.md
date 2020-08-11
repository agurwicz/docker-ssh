# IDE Debugging in Remote Docker Container

## This code is intended to be used in [ICA-PUC](https://github.com/ICA-PUC) projects.

### Index

- [Motivation](#motivation)
- [Usage](#usage)
  - [SSH Key Creation](#ssh-key-creation)
  - [Docker Image Creation](#docker-image-creation)
  - [Docker Container Creation](#docker-container-creation)  
  - [SSH Tunnel](#ssh-tunnel)
  - [IDE Configuration](#ide-configuration)
    - [PyCharm](#pycharm)
- [Troubleshooting](#troubleshooting)

## Motivation

This project was born from the need to locally debug code that is being run inside a Docker container, which is running in a node requested via `qsub` from a GPU cluster, accessed via SSH.

## Usage

- The [SSH Key Creation](#ssh-key-creation) step only needs to be done once per user.
- The [Docker Image Creation](#docker-image-creation) step needs to be done once per Docker image to be created by the user. 
  - The `ssh_dockerfile.sh` file can also be modified as to include other commands, appending to the base image content.
- The [Docker Container Creation](#docker-container-creation) step should be done once per coding session, as to avoid holding cluster resources (requested via `qsub`). 
  - When finished, the container needs to be stopped and removed. To do so, run `docker rm -f <container_name>`.
- The [SSH Tunnel](#ssh-tunnel) step needs to be done before every coding session.
  - When finished, the SSH credentials in the local machine need to be removed, in order to avoid problems when connecting again from the same port. To do so, run `ssh-keygen -R [127.0.0.1]:<port>` in the local machine.
- The [IDE Configuration](#ide-configuration) step should be done once per coding session.
  - With the [PyCharm](#pycharm) IDE, when finished, the remote interpreter and deployment configurations should be removed. This avoids problems when connecting again from the same port.

### SSH Key Creation

- The steps to access the remote machines are made easier by using SSH keys, in lieu of passwords. To do so:
- In the cluster, with the same user that will be used to run code, run the following command:
  
  ```
  ssh-keygen
  ``` 
  
  When prompted, choose the full path, and the optional passphrase, of the key to be created. This creates a pair of keys, a private and a public one.
   
- Add the public key to the user's set of authorized keys, with the following command:

  ```
  cat <path_to_key>.pub >> ~/.ssh/authorized_keys
  ```

- Copy the private key to the local machine. This can be achieved with the following command, from the local machine:

  ```
  scp <user>@<cluster_ip>:<path_to_key> <directory_in_local_machine>
  ```  

- This key can now be used not only for accessing the cluster, but also its nodes. It will also be used in the following steps to access the Docker container.

### Docker Image Creation

- Copy the `scripts/ssh_dockerfile.sh` and `scripts/create_image.sh` files to the cluster.
- Run the script in the cluster node, passing the required arguments, with the following default values:
  
  ```
  <path_to_script>/create_image.sh <base_image_name> <image_name> <dockerfile_path>
  ```
  
  - `<base_image_name>`: `None`
  - `<image_name>`: `${USER}/ssh:latest`
  - `<dockerfile_path>`: `./ssh_dockerfile.sh`    

- The image is now created. To confirm, run `docker image list | grep <image_name>`.
  
### Docker Container Creation   

**These steps need to be done in the node while accessed via `qsub`**. Make sure to keep the connection alive while using the container here, or elsewhere.

- Copy the `scripts/create_container.sh` file to the cluster.
- Run the script, passing the required arguments, with the following default values:
  
  ```
  <path_to_script>/create_container.sh <gpu> <port> <mapped_directories> <image_name>
  ```
  
  - `<gpu>`: `None` (options: `P` for P100, `V` for V100, `G` for GTX1080 and `GT` for GTX1080TI)
  - `<port>`: `None` (important: must be unique and not in use)
  - `<mapped_directories>`: `""` (format: `"local_path_1:remote_path_2;...;local_path_n:remote_path_n"`)
  - `<image_name>`: `${USER}/ssh:latest`
  
- The container is now created and started, with its name printed in the format `${USER]_<random_number>`. To confirm, run `docker ps | grep <container_name>`.
- The running container can be now used, by running:
  - `docker exec -it <container_name> /bin/bash`  
    or  
  - `ssh -p <port> -i "<path_to_ssh_key>" ${USER}@127.0.0.1`

### SSH Tunnel

- In order to access the running container from the local machine, a tunnel needs to be created. To do so:
- Copy the `scripts/ssh_tunnel.bat` file to the local machine.
- Run the script in the local machine, passing the required arguments. Note that there are no default arguments.
  
  ```
  <path_to_script>\ssh_tunnel.bat <node_ip> <port> <user> <local_key_path> <remote_key_path> <remote_ip>
  ```
  - `<node_ip>`: IP or name of the node requested via `qsub`
  - `<port>`: Port chosen in the Docker container creation
  - `<user>`: User on all remote machines
  - `<local_key_path>`: Key path on the user's machine
  - `<remote_key_path>`: Key path on the cluster
  - `<remote_ip>`: IP or name of the cluster

  This script can be edited as to substitute the passing of arguments for fixed ones inside it.

- This creates the SSH tunnel, connecting the local machine to the running container. To confirm, in another terminal, run `ssh -p <port> -i "<path_to_ssh_key>" <user>@127.0.0.1`.  
- To close the connection, press `Ctrl+C`.

### IDE Configuration

#### PyCharm

- In `File > Settings > Build, Execution, Deployment > Deployment`, make sure there are no configured connections to `<user>@<127.0.0.1>:<port>`.
- In `File > Settings > Project: <project_name> > Python Interpreter > ⚙ > Add > SSH Interpreter`, fill a `New server configuration`:
  - `Host`: `127.0.0.1`
  - `Port`: Port chosen in the Docker container creation
  - `Username`: Username used in all previous steps
- In `Key pair`, fill the path to the SSH key in the local machine.
- In `Interpreter`, set the path for the Python interpreter in the Docker container (if unknown, run `which python` or `which python3` in the Docker container).
- This creates a new remote interpreter and deployment configuration, with the project directory mapped to a temporary random directory in the Docker container, automatically updated when the files are modified in PyCharm.

## Troubleshooting

- **SSH connection attempt ignoring key and asking for password:**  
  
  Most likely, the problem lies in the permissions for the files in the container user's `.ssh` directory. Try running the following command, from inside the Docker container:
  
  ```
  chmod 600 ~/.ssh/*
  ```
