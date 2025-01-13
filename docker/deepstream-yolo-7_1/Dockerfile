FROM nvcr.io/nvidia/deepstream:7.1-triton-multiarch

ARG DS_VER=7.1
ARG CUDA_VER=12.6
ARG TRT_VER=10.5.0
ARG TRT_SUBVER=10.5.0.18
ARG CPYTHON_VER=310

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

# Update to TensorRT 10.5.0
RUN if [ $(uname -m) = "aarch64" ]; \
        then export TRT_DOWNLOAD=https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/${TRT_VER}/tars/TensorRT-${TRT_SUBVER}.l4t.aarch64-gnu.cuda-${CUDA_VER}.tar.gz; \
        else export TRT_DOWNLOAD=https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/${TRT_VER}/tars/TensorRT-${TRT_SUBVER}.Linux.x86_64-gnu.cuda-${CUDA_VER}.tar.gz; \
    fi && \
    wget -O /TensorRT-${TRT_SUBVER}.tar.gz --content-disposition ${TRT_DOWNLOAD} && \
    mkdir /TensorRT-${TRT_SUBVER} && \
    tar -xzvf /TensorRT-${TRT_SUBVER}.tar.gz -C /
WORKDIR /TensorRT-${TRT_SUBVER}/python
RUN export LD_LIBRARY_PATH=/TensorRT-${TRT_SUBVER}/lib:$LD_LIBRARY_PATH && \
    if [ $(uname -m) = "aarch64" ]; \
    then \
        python3 -m pip install tensorrt-${TRT_VER}-cp${CPYTHON_VER}-none-linux_aarch64.whl; \
        python3 -m pip install tensorrt_dispatch-${TRT_VER}-cp${CPYTHON_VER}-none-linux_aarch64.whl; \
        python3 -m pip install tensorrt_lean-${TRT_VER}-cp${CPYTHON_VER}-none-linux_aarch64.whl; \
    else \
        python3 -m pip install tensorrt-${TRT_VER}-cp${CPYTHON_VER}-none-linux_x86_64.whl; \
        python3 -m pip install tensorrt_dispatch-${TRT_VER}-cp${CPYTHON_VER}-none-linux_x86_64.whl; \
        python3 -m pip install tensorrt_lean-${TRT_VER}-cp${CPYTHON_VER}-none-linux_x86_64.whl; \
    fi

# Install DeepStream-Yolo
RUN git clone https://github.com/marcoslucianops/DeepStream-Yolo.git \
    /opt/nvidia/deepstream/deepstream-${DS_VER}/DeepStream-Yolo
WORKDIR /opt/nvidia/deepstream/deepstream-${DS_VER}/DeepStream-Yolo
RUN CUDA_VER=${CUDA_VER} make -C nvdsinfer_custom_impl_Yolo
RUN chmod -R 777 /opt/nvidia/deepstream/deepstream/DeepStream-Yolo

# Set working directory
WORKDIR /opt/nvidia/deepstream/deepstream-7.1/
