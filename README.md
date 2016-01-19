# Base QC pipeline image

This repository contains a Dockerfile to create a Docker image with QC pipeline tools:

* standalone command-line version of __Torrent Variant Caller (TVC)__ 4.4.3
* __SeqUtils__ v.0.2
* and __samtools__ v.1.2

Tools are wrapped by the pipeline script ``qc_pipeline.py`` being an entrypoint for the image. It implements basic strand coverage and variant calling.

You can pull already builded docker image [here](https://hub.docker.com/r/aafanasyev/qc-pipeline/) from Docker Hub.

### Building an image
From directory with Dockerfile run command:

```sh
docker build -t qc-pipeline .
```

### Main pipeline script

To start QC pipeline run command:

```sh
docker run --rm qc-pipeline start \
            -b /your/bam/file \
            -r /your/target/regions/file \
            -f /your/reference/fasta/file \
            -p /variant/caller/parameters/json/file
```

Pipeline results would be stored in ``/mnt/pipeline-results`` inside a container.

Command to see help message:

```sh
docker run --rm qc-pipeline start -h
```
