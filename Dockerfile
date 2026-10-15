# ---------- Стаge1: setting up llama-server ----------
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libgomp1 cmake git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

ARG LLAMA_CPP_TAG=b9879
RUN git clone --depth 1 --branch ${LLAMA_CPP_TAG} \
    https://github.com/ggml-org/llama.cpp /opt/llama.cpp && \
    cmake -S /opt/llama.cpp -B /opt/llama.cpp/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DLLAMA_BUILD_UI=OFF \
        -DLLAMA_USE_PREBUILT_UI=OFF \
        -DLLAMA_CURL=OFF && \
    cmake --build /opt/llama.cpp/build --target llama-server -j$(nproc)

# ---------- Стадия 2: final image ----------
FROM debian:bookworm-slim

# only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/llama.cpp/build/bin/llama-server /usr/local/bin/llama-server

RUN mkdir -p /models && \
    curl -L -o /models/model.gguf \
    "https://huggingface.co/unsloth/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_K_M.gguf?download=true"

EXPOSE 8000
ENTRYPOINT ["llama-server", \
            "-m", "/models/model.gguf", \
            "--host", "0.0.0.0", \
            "--port", "8000", \
            "--threads", "4", \
            "--threads-batch", "4", \
	    "--batch-size", "512", \
	    "--ubatch-size", "512", \
            "--flash-attn", "on"]
