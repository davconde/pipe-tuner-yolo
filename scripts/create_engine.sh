#!/usr/bin/env bash

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <config_file.txt> <docker_image>"
    exit 1
fi

config_abs_path=$(realpath "$1")
docker_image="$2"

# Per the requirement
storage=$(realpath "$(pwd)/..")
config_dir=$(dirname "$config_abs_path")

# Extract batch-size from the provided config
batch_size_value=$(grep '^batch-size=' "$config_abs_path" | cut -d '=' -f2)
if [ -z "$batch_size_value" ]; then
    echo "Error: Could not find batch-size in $config_abs_path"
    exit 1
fi

# Extract model-engine-file path from the provided config
model_engine_file=$(grep '^model-engine-file=' "$config_abs_path" | cut -d '=' -f2)
if [ -z "$model_engine_file" ]; then
    echo "Error: Could not find model-engine-file in $config_abs_path"
    exit 1
fi

model_engine_dir=$(dirname "$model_engine_file")

# Define a container name
ds_container="deepstream_container_$$"

# Run the container in detached mode
docker run --gpus all -d --rm --net=host --privileged \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY="$DISPLAY" \
    -v "$storage":"$storage" \
    -v "$config_dir":"$config_dir" \
    -w /opt/nvidia/deepstream/deepstream/samples/configs/deepstream-app \
    --name "$ds_container" \
    "$docker_image" \
    tail -f /dev/null

# Now exec into the running container to do the modifications and run deepstream
docker exec "$ds_container" bash -c "
    # Remove lines with model-engine-file
    sed -i '/model-engine-file/d' source30_1080p_dec_infer-resnet_tiled_display_int8.txt

    # Replace batch-size with the one from the provided config
    sed -i 's/^batch-size=.*/batch-size=$batch_size_value/' source30_1080p_dec_infer-resnet_tiled_display_int8.txt

    # Replace config-file line
    sed -i 's|config-file=config_infer_primary.txt|config-file=$config_abs_path|' source30_1080p_dec_infer-resnet_tiled_display_int8.txt

    # Replace the URI line
    sed -i 's|uri=file://../../streams/sample_1080p_h264.mp4|uri=file://../../streams/sample_1080p_h264_.mp4|' source30_1080p_dec_infer-resnet_tiled_display_int8.txt

    # Run deepstream-app
    deepstream-app -c source30_1080p_dec_infer-resnet_tiled_display_int8.txt

    # Copy model_b* files to the directory defined by model-engine-file from the provided config
    cp model_b* $model_engine_dir
"

# Stop the container
docker stop "$ds_container"

# Check if model_b* files exist in the host's model_engine_dir
if ls "$model_engine_dir"/model_b* >/dev/null 2>&1; then
    echo "Model files successfully copied to $model_engine_dir"
else
    echo "Warning: No model_b* files found in $model_engine_dir"
fi
