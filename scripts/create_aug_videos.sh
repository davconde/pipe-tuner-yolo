################################################################################
# Copyright (c) 2024, NVIDIA CORPORATION.  All rights reserved.
# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.
################################################################################

if [ ! $1 ]
then
    echo "Usage: bash $0 <video folder>"
    exit 1
fi
storage=$(realpath $(pwd)/..)
tuner_image="nvcr.io/nvidia/pipetuner:1.0"
echo "Lauch command:"
echo "docker run --gpus all -it --rm --net=host --privileged -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY= -v $storage:$storage $tuner_image /bin/bash /pipe-tuner/utils/launch_augmenter.sh $storage/data/SDG_1min_videos"
docker run --gpus all -it --rm --net=host --privileged -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY= -v $storage:$storage $tuner_image /bin/bash /pipe-tuner/utils/launch_augmenter.sh $storage/data/SDG_1min_videos
