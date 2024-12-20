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
    echo "Usage: bash $0 <PipeTuner result folder> <metric>"
    exit 1
fi

expname=$(date +%F_%H-%M-%S)
tuner_image="nvcr.io/nvidia/pipetuner:1.0"
container="analysis_$expname"
storage=$(realpath $(pwd)/..)
resultdir=$(realpath $1)
echo "storage: $storage"

analysis_cmd="pip3 install matplotlib==3.8.0 > /dev/null; python3 /pipe-tuner/utils/plot_csv_results.py $resultdir/results/*.csv $resultdir/results/accuracy_plot.png; python3 /pipe-tuner/utils/retrieve_checkpoints.py $resultdir $2;"
echo "Result analysis command:"
echo "docker run --gpus all --rm -itd --net=host --name $container -v /var/run/docker.sock:/var/run/docker.sock -v $storage:$storage $tuner_image /bin/bash -c \"$analysis_cmd\""
docker run --gpus all --rm -it --net=host --name $container -v /var/run/docker.sock:/var/run/docker.sock -v $storage:$storage $tuner_image /bin/bash -c "$analysis_cmd"
