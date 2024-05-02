#!/bin/sh
set -e

############################
# setup global environment #
############################

# Set PATH for the virtual environment
export PATH="/venv/bin:$PATH"

# For mlock support (--cap-add SYS_RESOURCE must be added to docker in order to do this)
ulimit -l unlimited 2>/dev/null || true

############################
# setup user environment   #
############################

# TIMEZONE
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

############################
# run app                  #
############################

# start nginx reverse proxy
service nginx start

# start server
exec python3 -B -m host \
    --model /repository/${MODEL:-"model.gguf"}a \
    --model_alias chat \
    --n_ctx 32768 \
    --n_batch 512 \
    --n_gpu_layers -1 \
    --main_gpu 0 \
    --chat_format alpaca \
    --cache_type ram \
    --cache_size 2147483648 \
    --host 0.0.0.0 \
    --port 8000 \
    --interrupt_requests True
