################################################################################
# Copyright (c) 2024, NVIDIA CORPORATION.  All rights reserved.
# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.
################################################################################

#!/bin/bash

# Initialize variables
multiclass_path=""

# Default tuner image
#tuner_image="nvcr.io/nvidia/pipetuner:1.0"
tuner_image="pipetuner-fast:1.0"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --multiclass) 
            multiclass_path="$2"
            shift ;;
        *)
            if [ -z "$deepstream_image_id" ]; then
                deepstream_image_id="$1"
            elif [ -z "$config_file" ]; then
                config_file="$1"
            else
                echo "Unknown parameter passed: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

# Check for required parameters
if [ -z "$deepstream_image_id" ] || [ -z "$config_file" ]; then
    echo "Usage: $0 [--multiclass <path>] <deepstream image id> <config_pipetuner.yml>"
    exit 1
fi

# Ensure the config file exists
if [ ! -f "$config_file" ]; then
    echo "Error: Config file '$config_file' does not exist."
    exit 1
fi

# Check for required positional parameters
if [ -z "$deepstream_image_id" ] || [ -z "$config_file" ]; then
    echo "Usage: $0 [--multiclass <path>] <deepstream image id> <config_pipetuner.yml>"
    exit 1
fi

# Convert multiclass_path to an absolute path if set
if [ -n "$multiclass_path" ]; then
    multiclass_path=$(realpath "$multiclass_path")
fi

ip_addr="127.0.0.1"
storage=$(realpath $(pwd)/..)
echo "Directory mapped into docker: $storage"

expname=$(date +%F_%H-%M-%S)
ptcfg=$(basename $config_file)
ds_container="ds_$expname"
tuner_container="tuner_$expname"
port1=$(comm -23 <(seq 50000 52000 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
port2=$(comm -23 <(seq 53000 55000 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
echo "Found avaliable ports: $port1 $port2"

# Launch containers
echo "Launch containers:"
echo "docker run --rm --gpus all -itd --net=host -v $storage:$storage --name $ds_container $deepstream_image_id;"
echo "docker run --rm --gpus all -itd --net=host --name $tuner_container -v /var/run/docker.sock:/var/run/docker.sock -v $storage:$storage $tuner_image;"
docker run --rm --gpus all -itd --net=host -v $storage:$storage --name $ds_container $deepstream_image_id
docker run --rm --gpus all -itd --net=host --name $tuner_container -v /var/run/docker.sock:/var/run/docker.sock -v $storage:$storage $tuner_image

# Create output directory
echo "Creating output directory..."
echo "mkdir -p $storage/output; cp $config_file $storage/output; sed -i \"s/        containerImageID:*/containerImageID:$ds_container\n/\" -i \"s/    port: $port1\n/\" $storage/output/$ptcfg;"
mkdir -p $storage/output; cp $config_file $storage/output;
sed -i "s/        containerImageID:.*/        containerImageID: \"$ds_container\"/" $storage/output/$ptcfg
sed -i "s/    port:.*/    port: \"$port1\"/" $storage/output/$ptcfg
sed -i "s/        rootPath:.*/        rootPath: \"$(echo $storage | sed 's/\//\\\//g')\"/" $storage/output/$ptcfg

if [ "$tuner_image" != "pipetuner-fast:1.0" ]; then
    echo "Installing dependencies..."
    #echo "docker exec $tuner_container /bin/bash -c \"bash /pipe-tuner/utils/user_additional_install.sh""
    docker exec $tuner_container /bin/bash -c "bash /pipe-tuner/utils/user_additional_install.sh"
fi

# Check if multiclass_path is set and construct the command accordingly
if [ -n "$multiclass_path" ]; then
    echo "Enabling multiclass evaluation..."
    #echo docker cp \"$(dirname \"$0\")/update_IDMAP.sh\" $tuner_container:/pipe-tuner/utils/update_IDMAP.sh
    docker cp "$(dirname "$0")/update_IDMAP.sh" $tuner_container:/pipe-tuner/utils/update_IDMAP.sh
    #echo "docker exec $tuner_container /bin/bash -c \"bash /pipe-tuner/utils/update_IDMAP.sh $multiclass_path --start-index 1\""
    docker exec $tuner_container /bin/bash -c "bash /pipe-tuner/utils/update_IDMAP.sh $multiclass_path --start-index 1"
fi

echo "Launch BBO client..."
#echo "docker exec $tuner_container /bin/bash -c \"mkdir -p $storage/output/${ptcfg}_output/results; mkdir -p $storage/output/${ptcfg}_output/checkpoints; cd /pipe-tuner/src/client; ./main.py  -c $storage/output/$ptcfg -p $port2 -o $storage/output/${ptcfg}/results/${ptcfg}_accuracy.csv\" > $storage/output/log_client_$expname 2>&1 &;"
docker exec $tuner_container /bin/bash -c "mkdir -p $storage/output/${ptcfg}_output/results; cd /pipe-tuner/src/client; ./main.py  -c $storage/output/$ptcfg -p $port2 -o $storage/output/${ptcfg}_output/results/${ptcfg}-${expname}_accuracy.csv -l $storage/output/log_client_$expname" &

echo "Launch BBO server..."
#echo "docker exec $tuner_container /bin/bash -c \"cd $storage/output/${ptcfg}_output/checkpoints; /pipe-tuner/src/server/build/ds_bbo_server -p $port1\" > $storage/output/log_server_$expname 2>&1 &"
docker exec $tuner_container /bin/bash -c "mkdir -p $storage/output/${ptcfg}_output/checkpoints; cd $storage/output/${ptcfg}_output/checkpoints; /pipe-tuner/src/server/build/ds_bbo_server -p $port1" 2>&1 | tee -a $storage/output/log_server_$expname  &
echo "PipeTuner started successfully!"

echo ""
echo "!!!!! To stop tuning process in the middle, press CTRL+C !!!!!"
echo ""

# capture CRTL+C to stop all docker containers
STOP=0
trap ctrl_c INT

function ctrl_c() {
    echo ""
    echo "Ctrl + C pressed!"
    echo "Stopping containers..."
    docker stop $tuner_container $ds_container
    echo "Containers stopped successfully"
    STOP=1
}
while [ $STOP -eq 0 ]
do
    sleep 1
done

echo ""
echo "PipeTuner ends"
