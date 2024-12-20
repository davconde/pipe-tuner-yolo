################################################################################
# Copyright (c) 2024, NVIDIA CORPORATION.  All rights reserved.
# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.
################################################################################

storage=$(realpath $(pwd)/..)
storage_sed=$(echo $storage | sed 's/\//\\\//g')
BACKUP=../configs/config_PipeTuner/temp_do_not_use

backup_configs() {
	if ls ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D_default.yml 2>/dev/null
	then
		echo "Tracker/PGIE configs are backed up"
	else
		# backup original config files before overwriting
		cp ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D.yml ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D_default.yml
		cp ../configs/config_Tracker/config_tracker_NvDCF_accuracy_SWIN_3D.yml ../configs/config_Tracker/config_tracker_NvDCF_accuracy_SWIN_3D_default.yml
		cp ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D.yml ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D_default.yml
		cp ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50.yml ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_default.yml
		cp ../configs/config_PGIE/config_infer_primary_PeopleNet_ResNet34.txt ../configs/config_PGIE/config_infer_primary_PeopleNet_ResNet34_default.txt
	fi
	if ls $BACKUP 2>/dev/null
	then
		echo "PipeTuner configs are backed up"
	else
		mkdir -p $BACKUP
		mv ../configs/config_PipeTuner/*.yml $BACKUP
	fi
}

update_config_tracker_3d() {
	# Update cameraModelFilepath to the actual path on host machine in tracker configs for 3D tracking. Needed by both DeepStream and Metropolis
	sed -i "s/\/media\/sdb\/pipe-tuner-sample/$storage_sed/g" ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D.yml
	sed -i "s/\/media\/sdb\/pipe-tuner-sample/$storage_sed/g" ../configs/config_Tracker/config_tracker_NvDCF_accuracy_SWIN_3D.yml
}


update_config_tracker_reid_ds() {
	# Update Re-ID model paths to the actual model downloaded from NGC to host machine. Needed by DeepStream
	sed -i -e "s/  tltEncodedModel:.*/  onnxFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx/g" \
		   -e "s/  onnxFile:.*/  onnxFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx/g" \
	       -e "s/  modelEngineFile:.*/  modelEngineFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx_b100_gpu0_fp16.engine/g" ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D.yml
	sed -i -e "s/  tltEncodedModel:.*/  onnxFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx/g" \
		   -e "s/  onnxFile:.*/  onnxFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx/g" \
	       -e "s/  modelEngineFile:.*/  modelEngineFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx_b100_gpu0_fp16.engine/g" ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50.yml
	sed -i -e "s/  tltEncodedModel:.*/  onnxFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx/g" \
		   -e "s/  onnxFile:.*/  onnxFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx/g" \
	       -e "s/  modelEngineFile:.*/  modelEngineFile: $storage_sed\/models\/resnet50_market1501_aicity156.onnx_b100_gpu0_fp16.engine/g" ../configs/config_Tracker/config_tracker_NvDCF_accuracy_YOLO.yml
}

update_config_pgie_ds() {
	# Update PGIE model paths to the actual model downloaded from NGC to host machine. Needed by DeepStream
	sed -i -e "s/model-engine-file.*/model-engine-file=$storage_sed\/models\/resnet34_peoplenet_int8.etlt_b8_gpu0_int8.engine/g" \
           -e "s/labelfile-path.*/labelfile-path=$storage_sed\/models\/labels.txt/g" \
           -e "s/tlt-encoded-model.*/tlt-encoded-model=$storage_sed\/models\/resnet34_peoplenet_int8.etlt/g" \
           -e "s/int8-calib-file.*/int8-calib-file=$storage_sed\/models\/resnet34_peoplenet_int8.txt/g" ../configs/config_PGIE/config_infer_primary_PeopleNet_ResNet34.txt
}

update_config_pgie_ds_yolo() {
	# Update PGIE model paths to the actual model downloaded from NGC to host machine. Needed by DeepStream
	sed -i -e "s/model-engine-file.*/model-engine-file=$storage_sed\/models\/YOLO11\/model_b13_gpu0_fp32.engine/g" \
           -e "s/labelfile-path.*/labelfile-path=$storage_sed\/models\/YOLO11\/labels.txt/g" \
           -e "s/onnx-file.*/onnx-file=$storage_sed\/models\/YOLO11\/yolo11s_last_1024.onnx/g" \
           -e "s/int8-calib-file.*/int8-calib-file=$storage_sed\/models\/YOLO11\/yolo11_int8.txt/g" ../configs/config_PGIE/config_infer_primary_yoloV11.txt
}

update_config_tracker_reid_mdx() {
	# MDX model paths are the same as default
	cp ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D_default.yml ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_3D.yml
	cp ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_default.yml ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50.yml
	cp ../configs/config_Tracker/config_tracker_NvDCF_accuracy_ResNet50_default.yml ../configs/config_Tracker/config_tracker_NvDCF_accuracy_YOLO.yml
}

update_config_pgie_mdx() {
	# MDX model paths are the same as default
	cp ../configs/config_PGIE/config_infer_primary_PeopleNet_ResNet34_default.txt ../configs/config_PGIE/config_infer_primary_PeopleNet_ResNet34.txt
}

setup_ds_container() {
	if docker pull nvcr.io/nvidia/pipetuner:1.0
	then
		echo "[1/2] Pulled pipe-tuner image"
	else
		echo "Exit..."
		exit 1
	fi
	if docker pull nvcr.io/nvidia/deepstream:7.1-triton-multiarch
	then
		echo "[2/2] Pulled deepstream image"
	else
		echo "Exit..."
		exit 1
	fi
}

setup_ds_yolo_container() {
	if docker build -t deepstream-yolo:7.1-triton-multiarch ../docker/deepstream-yolo-7_1
	then
		echo "Built deepstream-yolo image"
	else
		echo "Exit..."
		exit 1
	fi
	if docker build -t pipetuner-fast:1.0 ../docker/pipetuner-fast-1_0
	then
		echo "Built pipetuner-fast image"
	else
		echo "Exit..."
		exit 1
	fi
}

setup_mdx_container() {
	if docker pull nvcr.io/nvidia/pipetuner:1.0
	then
		echo "[1/2] Pulled pipe-tuner image"
	else
		echo "Exit..."
		exit 1
	fi
	if docker pull nvcr.io/nfgnkvuikvjm/mdx-v2-0/mdx-perception:2.1
	then
		echo "[2/2] Pulled mdx-perception image"
	else
		echo "Exit..."
		exit 1
	fi
}

backup_configs;
if [ $1 ] && ([[ $1 == "deepstream" ]] || [[ $1 == "deepstream-yolo" ]])
then
	echo "Setup for PipeTuner and DeepStream SDK..."

	echo "Pulling required containers..."
	setup_ds_container;

	# DeepStream container doesn't include the detector and Re-ID models needed, so need to download from NGC.
	echo "Downloading NGC models..."
	NGC_DOWNLOAD='../ngc_download/'
	mkdir -p $NGC_DOWNLOAD
	MODEL_DIR="../models"
	mkdir -p $MODEL_DIR

	# Download Detector used by PGIE and update PGIE configs
	DET_ZIP=$NGC_DOWNLOAD/peoplenet_deployable_quantized.zip
	wget --content-disposition https://api.ngc.nvidia.com/v2/models/nvidia/tao/peoplenet/versions/deployable_quantized_v2.6.1/zip -O $DET_ZIP
	unzip -o $DET_ZIP -d $MODEL_DIR
	update_config_pgie_ds;

	# Download YOLO based models
	if [ $1 == "deepstream-yolo" ]
	then
		setup_ds_yolo_container;
		DET_ZIP=$NGC_DOWNLOAD/models_yolo11.zip
		wget "https://universidadevigo-my.sharepoint.com/:u:/g/personal/david_conde_morales_uvigo_gal/Efn2PvM2-DJLmd8xqhE54gABTYltmJ6LsHTxZD67lQSrAw?download=1" -O $DET_ZIP
		mkdir -p $MODEL_DIR/YOLO11
		unzip -o $DET_ZIP -d $MODEL_DIR/YOLO11
		update_config_pgie_ds_yolo;
	fi

	# Download Re-ID used by tracker and update Re-ID section in tracker configs
	wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/reidentificationnet/versions/deployable_v1.2/files/resnet50_market1501_aicity156.onnx' -P ../models
	update_config_tracker_reid_ds;

	# Update tracker configs for 3D tracking
	echo "Updating DeepStream Perception SV3DT configs..."
	update_config_tracker_3d;

	# Copy PipeTuner configs
	rm -f $BACKUP/../*.yml
	cp $BACKUP/*MOT.yml $BACKUP/..
	echo "Sample data setup is done"

elif [ $1 ] && [ $1 == "metropolis" ]
then
	echo "Setup for PipeTuner and Metropolis Microservices..."

	echo "Pulling required containers..."
	setup_mdx_container;

	update_config_pgie_mdx;
	update_config_tracker_reid_mdx;

	echo "Setting up MTMC repo..."
	NGC_DOWNLOAD="../ngc_download/"
	mkdir -p $NGC_DOWNLOAD
	rm -rf $NGC_DOWNLOAD/metropolis-apps-standalone-deployment*

	# Download Metropolis standalone package from NGC
	if ngc registry resource download-version nfgnkvuikvjm/mdx-v2-0/metropolis-apps-standalone-deployment --dest $NGC_DOWNLOAD
	then
		echo "Downloaded Metropolis Standalone Package"
	else
		echo "Failed to download Metropolis Standalone Package. Run \"ngc config set\" to set NGC configuration. Exit..."
		exit 1
	fi

	# Extract MTMC from the package
	METRO_DIR=$(ls $NGC_DOWNLOAD | grep metropolis-apps-standalone-deployment)
	METRO_TAR=$(ls "$NGC_DOWNLOAD/$METRO_DIR")
	tar -xvpf "$NGC_DOWNLOAD/$METRO_DIR/$METRO_TAR" -C "$NGC_DOWNLOAD/$METRO_DIR" > /dev/null
	mv "$NGC_DOWNLOAD/$METRO_DIR/standalone-deployment/modules/multi-camera-tracking" ../

	# Update tracker configs for 3D tracking
	echo "Updating DeepStream Perception SV3DT configs..."
	update_config_tracker_3d;

	# Copy PipeTuner configs
	rm -f $BACKUP/../*.yml
	cp $BACKUP/*.yml $BACKUP/..
	echo "Sample data setup is done"
else
	echo "Usage: bash $0 [deepstream or metropolis]"
	echo "Ex1: bash $0 deepstream"
	echo "Ex2: bash $0 metropolis"
	exit 1
fi
