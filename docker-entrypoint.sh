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

# download model
if [ "$MODEL_REPO" != "local" ] && { [ "$MODEL_DOWNLOAD" = "True" ] || [ "$MODEL_DOWNLOAD" = "true" ] || [ "$MODEL_DOWNLOAD" = "TRUE" ]; }; then
    if [ ! -e "${MODEL_PATH}"/"${MODEL}" ]; then
        mkdir -p "${MODEL_PATH}"
        /venv/bin/huggingface-cli download --repo-type model --local-dir="${MODEL_PATH}" --local-dir-use-symlinks=False --resume-download --token="${HF_TOKEN:-''}" "${MODEL_REPO}" "${MODEL}"
    fi
fi

# start nginx reverse proxy
service nginx start

# set parameters
param=""
param="${param} --model '${MODEL_PATH:-"/model"}/${MODEL:-"llama-2-7b-chat.Q4_K_M.gguf"}'"
param="${param} --model_alias ${MODEL_ALIAS:-'chat'}"
param="${param} --n_ctx ${N_CTX:-2048}"
param="${param} --n_batch ${N_BATCH:-512}"
param="${param} --n_gpu_layers ${N_GPU_LAYERS:-0}"
param="${param} --main_gpu ${MAIN_GPU:-0}"
param="${param} --rope_freq_base ${ROPE_FREQ_BASE:-0.0}"
param="${param} --rope_freq_scale ${ROPE_FREQ_SCALE:-0.0}"
param="${param} --mul_mat_q ${MUL_MAT_Q:-True}"
param="${param} --logits_all ${LOGITS_ALL:-True}"
param="${param} --vocab_only ${VOCAB_ONLY:-False}"
param="${param} --use_mmap ${USE_MMAP:-True}"
param="${param} --use_mlock ${USE_MLOCK:-True}"
param="${param} --embedding ${EMBEDDING:-True}"
param="${param} --n_threads ${N_THREADS:-6}"
param="${param} --last_n_tokens_size ${LAST_N_TOKENS_SIZE:-64}"
param="${param} --lora_base ${LORA_BASE:-''}"
param="${param} --lora_path ${LORA_PATH:-''}"
param="${param} --numa ${NUMA:-False}"
param="${param} --chat_format ${CHAT_FORMAT:-'llama-2'}"
param="${param} --cache ${CACHE:-False}"
param="${param} --cache_type ${CACHE_TYPE:-'ram'}"
param="${param} --cache_size ${CACHE_SIZE:-2147483648}"
param="${param} --verbose ${VERBOSE:-True}"
param="${param} --host ${HOST:-'0.0.0.0'}"
param="${param} --port ${PORT:-8000}"
param="${param} --interrupt_requests ${INTERRUPT_REQUESTS:-True}"

# start server
exec sh -c "/venv/bin/python3 -B -m host ${param}"
