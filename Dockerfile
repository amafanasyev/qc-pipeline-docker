FROM ubuntu:14.04
MAINTAINER Afanasyev Alexander <aafanasyev@parseq.pro>

# Install dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    default-jre \
    g++ \
    libatlas-dev \
    libbz2-dev \
    liblapack-dev \
    libncurses-dev \
    wget \
    zlib1g-dev


# Set all necessary enviroment variables
ENV BUILD_ROOT_DIR=/opt/tsvc-tmp/ \
    TVC_VERSION=tvc-4.4.3 \
    ION_GATK_VERSION=ion_gatk-4.4.3 \
    ARMADILLO_VERSION=armadillo-4.300.8 \
    BAMTOOLS_VERSION=bamtools-2.3.0.20131211+git67178ae187 \
    SAMTOOLS_VERSION=samtools-0.1.19 \
    VCFTOOLS_VERSION=vcftools_0.1.11 \
    HTSLIB_VERSION=htslib-1.1 \
    DISTRIBUTION_CODENAME=ubuntu_14.04
ENV TVC_SOURCE_DIR=$BUILD_ROOT_DIR/$TVC_VERSION
ENV TVC_INSTALL_DIR=$BUILD_ROOT_DIR/$TVC_VERSION-$DISTRIBUTION_CODENAME-binary
ENV TVC_ROOT_DIR=/opt/$TVC_VERSION


# Create directories
RUN mkdir $BUILD_ROOT_DIR \
    && mkdir $TVC_ROOT_DIR


# Add directory with binary files to PATH
ENV PATH=$TVC_ROOT_DIR/bin:$PATH

# Copy and extract dependencies
ADD $TVC_VERSION.tar.gz $BUILD_ROOT_DIR
ADD $ION_GATK_VERSION.tar.gz $BUILD_ROOT_DIR
ADD $ARMADILLO_VERSION.tar.gz $BUILD_ROOT_DIR
ADD $BAMTOOLS_VERSION.tar.gz $BUILD_ROOT_DIR
ADD $SAMTOOLS_VERSION.tar.bz2 $BUILD_ROOT_DIR
ADD $VCFTOOLS_VERSION.tar.gz $BUILD_ROOT_DIR
ADD $HTSLIB_VERSION.tar.gz $BUILD_ROOT_DIR

# Build armadillo
WORKDIR $BUILD_ROOT_DIR/$ARMADILLO_VERSION 
RUN cmake . && make -j4


# Build bamtools
WORKDIR $BUILD_ROOT_DIR
RUN mkdir $BAMTOOLS_VERSION-build
WORKDIR $BUILD_ROOT_DIR/$BAMTOOLS_VERSION-build
RUN cmake ../$BAMTOOLS_VERSION  -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo \
    && make -j4


# Build samtools
WORKDIR $BUILD_ROOT_DIR/$SAMTOOLS_VERSION
RUN make -j4


# Build vcftools
WORKDIR $BUILD_ROOT_DIR/$VCFTOOLS_VERSION
RUN make -j4


# Build htslib
WORKDIR $BUILD_ROOT_DIR/$HTSLIB_VERSION
RUN make -j4


# Build TVC
WORKDIR $BUILD_ROOT_DIR
RUN mkdir $TVC_VERSION-build 
WORKDIR $TVC_VERSION-build 
RUN cmake $TVC_SOURCE_DIR -DCMAKE_INSTALL_PREFIX:PATH=$TVC_INSTALL_DIR -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo 
RUN make -j4 install


# Copy tvc binary version to $TVC_ROOT_DIR
WORKDIR $BUILD_ROOT_DIR
RUN cp -r $ION_GATK_VERSION/jar $TVC_INSTALL_DIR/share/TVC/ \
    && cp $VCFTOOLS_VERSION/bin/vcftools $TVC_INSTALL_DIR/bin/ \ 
    && cp $SAMTOOLS_VERSION/samtools $TVC_INSTALL_DIR/bin/ \
    && cp $HTSLIB_VERSION/tabix $TVC_INSTALL_DIR/bin/ \
    && cp $HTSLIB_VERSION/bgzip $TVC_INSTALL_DIR/bin/ \
    && cp -r $TVC_INSTALL_DIR/* $TVC_ROOT_DIR 

# Copy and extract SAMtools archive
ADD samtools-1.2.tar.bz2 /opt/

WORKDIR /opt/samtools-1.2

# Make SAMtools
RUN make
RUN make prefix=/opt/samtools-1.2 install

# Setting up SAMtools environmental variable
ENV PATH /opt/samtools-1.2/bin:$PATH

# Copy and extract SeqUtils archive
ADD sequtils-0.2.tar.bz2 /opt/sequtils-0.2

WORKDIR /opt/sequtils-0.2

# Compose an SeqUtils execution script
RUN printf %"s\n" '#!/bin/bash' 'java -jar /opt/sequtils-0.2/sequtils.jar $@' >> sequtils.sh \
	&& chmod +x sequtils.sh

ENV PATH /opt/sequtils-0.2:$PATH

ADD qc_pipeline.py /opt/

# Delete not necessary files from $BUILD_ROOT_DIR, remove not necessary packages and clean apt cache
WORKDIR $BUILD_ROOT_DIR
RUN rm -r * \
    && apt-get --purge -y remove cmake g++ wget \
    && apt-get -y clean \
    && apt-get -y autoremove


# Volumes for input and output data
RUN mkdir /mnt/reference/ \
    && mkdir /mnt/input_bam/ \
    && mkdir /mnt/parameters/ \
    && mkdir /mnt/tvc-output/ \
    && mkdir /mnt/pipeline-results/
VOLUME ["/mnt/pipeline-results/"]

ENTRYPOINT ["/opt/qc_pipeline.py"]
