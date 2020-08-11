if [ $# -eq 0 ]; then
    echo "Empty Arguments!"
    exit 1
fi

# P for P100, V for V100, G for GTX1080 or GT for GTX1080TI
gpu=${1}

# Port to map ssh connections - **important: must be unique and not in use**
port=${2}

# Directories to be mapped to the container, in the format: "local_path_1:remote_path_2;...;local_path_n:remote_path_n"
# Home directory already separately mapped
mapped_directories=${3:-""}

# Image name
image_name=${4:-"${USER}/ssh:latest"}

if [ "${gpu}" = "P" ]; then
	echo "GPU: P100"
	extra_parameters="--cpus=8 --memory 28G --memory-swap 28G"
elif [ "${gpu}" = "V" ]; then
	echo "GPU: V100"
	extra_parameters="--cpus=16"
elif [ "${gpu}" = "G" ] || [ "${gpu}" = "GT" ]; then
	echo "GPU: GTX1080 or GTX1080TI"
	extra_parameters="--cpus=5 --memory 28G --memory-swap 28G"
else
	echo "Wrong GPU parameter!"
	exit 1
fi

if ! [[ ${port} =~ $(echo "^[0-9]+$") ]]; then
   echo "Port incorrectly defined!"
   exit 1
fi

gpu_id=$(echo $(cat ${PBS_GPUFILE}) | cut -d'-' -f 4 | tr -dc '0-9')
container_name="${USER}_$(((RANDOM%100000)+1))"

parsed_mapped_directories=""
IFS=';' read -ra ADDR <<< "${mapped_directories}"
for directory in "${ADDR[@]}"; do
    parsed_mapped_directories="${parsed_mapped_directories} -v ${directory}"
done

docker create \
-it \
--name "${container_name}" \
--runtime=nvidia \
-p ${port}:22 \
-u ${USER} \
-e HOME=${HOME} \
-e NVIDIA_VISIBLE_DEVICES=${gpu_id} \
-v ${HOME}:${HOME} \
${parsed_mapped_directories} \
${extra_parameters} "${image_name}" \
/bin/bash

docker start \
"${container_name}"
