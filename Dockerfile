FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04
WORKDIR /
EXPOSE 8000/tcp

# Setup dependencies
RUN apt update && \
    apt install -y python3 python3-venv python3-pip python3-uvicorn

RUN python3 -m venv venv && \
    /venv/bin/pip install llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu121 && \
    /venv/bin/pip install anyio fastapi starlette sse_starlette starlette_context pydantic pydantic_settings huggingface_hub[cli]

# Setup environment
ENV TZ="UTC" \
    MODEL_PATH="/repository" \
    MODEL_REPO="TheBloke/X-MythoChronos-13B-GGUF" \
    MODEL="x-mythochronos-13b.Q4_0.gguf" \
    N_CTX=1024 \
    N_BATCH=512 \
    N_GPU_LAYERS=0 \
    MAIN_GPU=0 \
    ROPE_FREQ_BASE=0.0 \
    ROPE_FREQ_SCALE=0.0 \
    MUL_MAT_Q=True \
    LOGITS_ALL=True \
    VOCAB_ONLY=False \
    USE_MMAP=True \
    USE_MLOCK=True \
    EMBEDDING=True \
    N_THREADS=4 \
    LAST_N_TOKENS_SIZE=64 \
    LORA_BASE="" \
    LORA_PATH="" \
    NUMA=False \
    CHAT_FORMAT="alpaca" \
    CACHE=False \
    CACHE_TYPE="ram" \
    CACHE_SIZE=2147483648 \
    VERBOSE=True \
    HOST="0.0.0.0" \
    PORT=8000 \
    INTERRUPT_REQUESTS=True

# Setup entrypoint
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
