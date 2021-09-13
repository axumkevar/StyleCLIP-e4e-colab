# ==================================================================
# module list
# ------------------------------------------------------------------
# python        3.7    (apt)
# pytorch       latest (pip)
# ==================================================================

FROM nvidia/cuda:10.1-cudnn8-runtime-ubuntu18.04

ARG APT_INSTALL="apt-get install -y --no-install-recommends"
ARG PIP_INSTALL="python -m pip --no-cache-dir install --upgrade"
ARG GIT_CLONE="git clone --depth 10"

ENV HOME /root

WORKDIR $HOME

RUN rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update

ARG DEBIAN_FRONTEND=noninteractive

RUN $APT_INSTALL build-essential software-properties-common ca-certificates \
                 wget git zlib1g-dev nasm cmake

RUN $GIT_CLONE https://github.com/libjpeg-turbo/libjpeg-turbo.git
WORKDIR libjpeg-turbo
RUN mkdir build
WORKDIR build
RUN cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=libjpeg-turbo -DWITH_JPEG8=1 ..
RUN make
RUN make install
WORKDIR libjpeg-turbo
RUN mv include/jerror.h include/jmorecfg.h include/jpeglib.h include/turbojpeg.h /usr/include
RUN mv include/jconfig.h /usr/include/x86_64-linux-gnu
RUN mv lib/*.* /usr/lib/x86_64-linux-gnu
RUN mv lib/pkgconfig/* /usr/lib/x86_64-linux-gnu/pkgconfig
RUN ldconfig
WORKDIR HOME


RUN apt-get update

RUN $APT_INSTALL python3.7 python3.7-dev python3-pip
RUN ln -s /usr/bin/python3.7 /usr/local/bin/python3
RUN ln -s /usr/bin/python3.7 /usr/local/bin/python

#MAIN DEPENDENCIES
RUN $APT_INSTALL screen nvidia-driver-470 nvidia-utils-470 unzip

RUN $PIP_INSTALL setuptools

RUN $PIP_INSTALL pip

RUN $PIP_INSTALL numpy scipy nltk dlib lmdb cython pydantic pyhocon matplotlib jupyter 

RUN $PIP_INSTALL torch==1.5.1+cu101 torchvision==0.6.1+cu101 -f https://download.pytorch.org/whl/torch_stable.html
RUN $PIP_INSTALL tensorflow==1.15.0 tqdm ftfy regex requests
RUN $PIP_INSTALL git+https://github.com/openai/CLIP.git 
RUN wget https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-linux.zip
RUN unzip ninja-linux.zip -d /usr/local/bin/
RUN update-alternatives --install /usr/bin/ninja ninja /usr/local/bin/ninja 1 --force

RUN ln -s /usr/local/cuda /usr/local/nvidia
RUN ln -s /usr/local/nvidia/lib64 /usr/local/nvidia/lib
RUN cd /usr/local/nvidia
RUN ls -1 /usr/local/cuda/lib64/*.so | xargs -I '{}' ln -s {} {}.10.0


ENV FORCE_CUDA="1"
ENV TORCH_CUDA_ARCH_LIST="Pascal;Volta;Turing"


RUN python -m pip uninstall -y pillow pil jpeg libtiff libjpeg-turbo
RUN CFLAGS="${CFLAGS} -mavx2" $PIP_INSTALL --force-reinstall --no-binary :all: --compile pillow-simd

RUN $APT_INSTALL libsm6 libxext6 libxrender1
RUN $PIP_INSTALL opencv-python-headless

WORKDIR $HOME
RUN $GIT_CLONE https://github.com/NVIDIA/apex.git
WORKDIR apex
RUN $PIP_INSTALL -v --global-option="--cpp_ext" --global-option="--cuda_ext" ./

WORKDIR $HOME

RUN ldconfig
RUN apt-get clean
RUN apt-get autoremove
RUN rm -rf /var/lib/apt/lists/* /tmp/* ~/*
