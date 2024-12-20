# pipe-tuner-yolo
NVIDIA PipeTuner data and tools for the optimization of a MOT DeepStream pipeline.

## Get access to the NVIDIA NGC Catalog:
Obtain an NVIDIA NGC API key:
1. Visit [NGC sign in page](https://catalog.ngc.nvidia.com/), Enter your email address and click Next, or Create an Account.
2. Choose your organization when prompted for Organization/Team. DeepStream users may use any organization and team; Metropolis Microservice users need to select nv-mdx/mdx-v2-0; Click Sign In.
3. Generate an API key following the instructions.
4. Log in to the NGC docker registry (nvcr.io) and enter the following credentials, where YOUR_NGC_API_KEY corresponds to the key you generated from the previous step.

```bash
$ docker login nvcr.io
Username: "$oauthtoken"
Password: "YOUR_NGC_API_KEY"
```

## Setup
Clone this repository:

```bash
git clone https://github.com/davconde/pipe-tuner-yolo.git
```

Run the setup script to obtain the Docker images and sample model files:

```bash
sudo chmod -R 777 pipe-tuner-yolo
cd pipe-tuner-yolo/scripts
sudo bash setup.sh deepstream-yolo  # Replace "deepstream-yolo" with "deepstream" if YOLO is not needed
```

**NOTE:** Running `setup.sh` with deepstream-yolo also creates by default a new PipeTuner image with already installed dependencies for speeding up testing, at the expense of a larger Docker image.

## Build engine

Models based in YOLO don't generate by default their TensorRT engine files in the same directory as the ONNX base. To avoid the building process in every iteration of PipeTuner, prepare the engine file to use in advance by running:

```bash
sudo bash create_engine.sh <config_infer_primary.txt> <DeepStream image name or ID>
```

<details>

<summary>Sample YOLO11 model:</summary>

```bash
sudo bash create_engine.sh ../configs/config_PGIE/config_infer_primary_yoloV11.txt deepstream-yolo:7.1-triton-multiarch
```

</details>

## Dataset

Build your dataset inside the `data` directory or download and import one of the following:

<details>

<summary>NVIDIA official sample data:</summary>

```bash
wget "https://universidadevigo-my.sharepoint.com/:u:/g/personal/david_conde_morales_uvigo_gal/EWa8KIaqWQVIgobdlGFpn7QBEDnLuxxBrZNrnh6pJco1qg?e=y06wgK&download=1" -O ../data_nvidia.zip
unzip -o ../data_nvidia.zip -d ..
rm ../data_nvidia.zip
```

</details>

<details>

<summary>Road traffic data</summary>

```bash
wget "https://universidadevigo-my.sharepoint.com/:u:/g/personal/david_conde_morales_uvigo_gal/EYtqs_yF2LpEmGd5KzU9KfQB0IkNkP2PyJjQGCSUMj2fgQ?e=T44yUz&download=1" -O ../data_road.zip
unzip -o ../data_road.zip -d ..
rm ../data_road.zip
```

</details>

**NOTE:** Current version of PipeTuner doesn't support evaluation over datasets with multiple classes. Although modified scripts are provided at the execution step for using models with detection of different classes, the dataset must contain all instances of objects as class "1".

## Execution
Localize the ID of your Docker images with:

```bash
docker images
```

Launch the tool using `launch.sh` (NVIDIA original script) or `launch2.sh` (supporting multiclass datasets) with:

```bash
sudo bash launch.sh <DeepStream image name or ID> <config_pipetuner.yml>
```

<details>

<summary>If running DeepStream 7.1 with NVIDIA data:</summary>

```bash
sudo bash launch.sh nvcr.io/nvidia/deepstream:7.1-triton-multiarch ../configs/config_PipeTuner/SDG_sample_PeopleNet-ResNet34_NvDCF-ResNet50_MOT.yml
```

</details>

<details>

<summary>If running DeepStream 7.1 with YOLO and road traffic data:</summary>

```bash
sudo bash launch2.sh --multiclass ../models/YOLO11/labels.txt deepstream-yolo:7.1-triton-multiarch ../configs/config_PipeTuner/road_MOT.yml
```

</details>

## Result analysis
After execution, run:

```bash
sudo bash result_analysis.sh <output folder> <metric>
```

<details>

<summary>For NVIDIA data with MOTA evaluation:</summary>

```bash
sudo bash result_analysis.sh ../output/SDG_sample_PeopleNet-ResNet34_NvDCF-ResNet50_MOT.yml_output/ MOTA
```

</details>

<details>

<summary>For road traffic data with MOTA evaluation:</summary>

```bash
sudo bash result_analysis.sh ../output/road_MOT.yml_output/ MOTA
```

</details>
