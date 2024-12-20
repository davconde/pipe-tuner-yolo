#!/bin/bash

# Check if the positional argument is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <path_to_labels_file> [optional_argument]"
  exit 1
fi

# Assign the positional argument to a variable
LABELS_FILE=$1

# Optional argument
OPTIONAL_ARG=$2

# Set the starting index for ID mapping (default is 1)
START_INDEX=1

# Variable to use constant ID (default is off)
USE_CONSTANT_ID=0

# Check if different options are provided as arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --start-index)
            START_INDEX=$2
            shift # past argument
            shift # past value
            ;;
        --use-constant-id)
            USE_CONSTANT_ID=1
            shift # past argument
            ;;
        *)
            shift # past unrecognized argument
            ;;
    esac
done

# Read labels from the provided labels file
labels=()
while IFS= read -r label; do
    labels+=("$label")
    echo "Processing label: $label"
done < "$LABELS_FILE"

# Generate IDMAP array
declare -A IDMAP
for i in "${!labels[@]}"; do
    label="${labels[$i]}"
    if [[ $USE_CONSTANT_ID -eq 1 ]]; then
        id=1
    else
        id=$((i + START_INDEX))
    fi
    IDMAP["$label"]=$id
    IDMAP["${label^}"]=$id
done

# Create a temporary file to store the new IDMAP definition
temp_file=$(mktemp)
{
    echo "# IDMAP_START"
    echo "declare -A IDMAP"
    echo "IDMAP=("
    for label in "${labels[@]}"; do
        echo "    [${label^}]=${IDMAP[${label^}]}"
    done
    for label in "${labels[@]}"; do
        echo "    [$label]=${IDMAP[$label]}"
    done
    echo ")"
    echo "# IDMAP_END"
} > "$temp_file"

# Function to add markers if they do not exist
add_markers_if_not_exist() {
    local file=$1
    if ! grep -q "# IDMAP_START" "$file"; then
        sed -i '/declare -A IDMAP/i # IDMAP_START' "$file"
    fi
    if ! grep -q "# IDMAP_END" "$file"; then
        sed -i '/usage() {/i # IDMAP_END' "$file"
    fi
}

# Add markers to kittiTrack2mot.sh if they do not exist
add_markers_if_not_exist /pipe-tuner/utils/kittiTrack2mot.sh

# Add markers to kittiDetect2mot.sh if they do not exist
add_markers_if_not_exist /pipe-tuner/utils/kittiDetect2mot.sh

# Replace the IDMAP definition in /pipe-tuner/utils/kittiTrack2mot.sh
sed -i -e '/# IDMAP_START/,/# IDMAP_END/{
    /# IDMAP_START/r '"$temp_file"'
    /# IDMAP_START/,/# IDMAP_END/d
}' /pipe-tuner/utils/kittiTrack2mot.sh

# Replace the IDMAP definition in /pipe-tuner/utils/kittiDetect2mot.sh
sed -i -e '/# IDMAP_START/,/# IDMAP_END/{
    /# IDMAP_START/r '"$temp_file"'
    /# IDMAP_START/,/# IDMAP_END/d
}' /pipe-tuner/utils/kittiDetect2mot.sh

# Clean up the temporary file
rm "$temp_file"