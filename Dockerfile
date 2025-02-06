FROM python:3.12-slim

WORKDIR /model

# from --build-arg
ARG HF_TOKEN

# Env definition
ENV PROJECT_NAME=meta-llama \
    REPOSITORY_NAME=Llama-2-7b-hf

RUN \
    echo "Install tools" && \
        pip install --no-cache-dir huggingface_hub

RUN \
    echo "Download model" && \
        huggingface-cli download --token ${HF_TOKEN} --resume-download \
            "${PROJECT_NAME}/${REPOSITORY_NAME}" \
            --local-dir /model/${REPOSITORY_NAME}/ \
        && \
    echo "Purge cache" && \
        rm -rf /model/${REPOSITORY_NAME}/.cache
