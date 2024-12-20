FROM nvcr.io/nvidia/deepstream:7.0-triton-multiarch

# Install additional GStreamer plugins and fixes
RUN /opt/nvidia/deepstream/deepstream/user_additional_install.sh
RUN /opt/nvidia/deepstream/deepstream/update_rtpmanager.sh

# Download ReID model
RUN mkdir /opt/nvidia/deepstream/deepstream/samples/models/Tracker && \
    wget -O /opt/nvidia/deepstream/deepstream/samples/models/Tracker/reid_model.zip --content-disposition https://api.ngc.nvidia.com/v2/models/nvidia/tao/reidentificationnet/versions/deployable_v1.2/zip && \
    unzip -o /opt/nvidia/deepstream/deepstream/samples/models/Tracker/reid_model.zip -d /opt/nvidia/deepstream/deepstream/samples/models/Tracker/ && \
    rm /opt/nvidia/deepstream/deepstream/samples/models/Tracker/reid_model.zip

# Install and update packages, then clean
RUN apt-get update && \
    apt-get install -y git build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install DeepStream-Yolo
RUN git clone https://github.com/marcoslucianops/DeepStream-Yolo.git \
    /opt/nvidia/deepstream/deepstream-7.0/DeepStream-Yolo
WORKDIR /opt/nvidia/deepstream/deepstream-7.0/DeepStream-Yolo
RUN CUDA_VER=12.2 make -C nvdsinfer_custom_impl_Yolo
RUN chmod -R 777 /opt/nvidia/deepstream/deepstream/DeepStream-Yolo

# Set working directory
WORKDIR /opt/nvidia/deepstream/deepstream-7.0/
