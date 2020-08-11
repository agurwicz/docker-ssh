# Name of the base image
base_image_name=${1}

# Name of the image to be created
image_name=${2:-"${USER}/ssh:latest"}

# Path to dockerfile
dockerfile_path=${3:-"./ssh_dockerfile.sh"}

docker build \
-f "${dockerfile_path}" \
--build-arg base_image_name="${base_image_name}" \
--build-arg user="${USER}" \
--build-arg user_id="${UID}" \
--build-arg home="${HOME}" \
-t "${image_name}" \
.
