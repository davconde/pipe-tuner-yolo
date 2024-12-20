################################################################################
# Copyright (c) 2024, NVIDIA CORPORATION.  All rights reserved.
# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.
################################################################################

if [ ! $1 ] || [ ! $2 ]
then
    echo "Usage: bash $0 <deepstream image id> <config_pipetuner.yml>"
    exit 1
fi

ip_addr="127.0.0.1"
storage=$(realpath $(pwd)/..)
echo "Directory mapped into docker: $storage"

expname=$(date +%F_%H-%M-%S)
ptcfg=$(basename $2)
tuner_image="nvcr.io/nvidia/pipetuner:1.0"
ds_container="ds_$expname"
tuner_container="tuner_$expname"
port1=$(comm -23 <(seq 50000 52000 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
port2=$(comm -23 <(seq 53000 55000 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1)
echo "Found avaliable ports: $port1 $port2"

# Launch containers
echo "Launch containers:"
echo "docker run --rm --gpus all -itd --net=host -v $storage:$storage --name $ds_container $1;"
echo "docker run --rm --gpus all -itd --net=host --name $tuner_container -v /var/run/docker.sock:/var/run/docker.sock -v $storage:$storage $tuner_image;"
docker run --rm --gpus all -itd --net=host -v $storage:$storage --name $ds_container $1
docker run --rm --gpus all -itd --net=host --name $tuner_container -v /var/run/docker.sock:/var/run/docker.sock -v $storage:$storage $tuner_image

# Create output directory
echo "Creating output directory..."
echo "mkdir -p $storage/output; cp $2 $storage/output; sed -i \"s/        containerImageID:*/containerImageID:$ds_container\n/\" -i \"s/    port: $port1\n/\" $storage/output/$ptcfg;"
mkdir -p $storage/output; cp $2 $storage/output;
sed -i "s/        containerImageID:.*/        containerImageID: \"$ds_container\"/" $storage/output/$ptcfg
sed -i "s/    port:.*/    port: \"$port1\"/" $storage/output/$ptcfg
sed -i "s/        rootPath:.*/        rootPath: \"$(echo $storage | sed 's/\//\\\//g')\"/" $storage/output/$ptcfg

echo "Installing dependencies..."
#echo "docker exec $tuner_container /bin/bash -c \"bash /pipe-tuner/utils/user_additional_install.sh""
docker exec $tuner_container /bin/bash -c "bash /pipe-tuner/utils/user_additional_install.sh"

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
