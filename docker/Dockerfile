FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    llvm \
    libclang-rt-18-dev \
    libpng-dev \
    lcov \
    make \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && printf '#!/bin/bash\nexec llvm-cov gcov "$@"\n' > /usr/local/bin/llvm-gcov \
    && chmod +x /usr/local/bin/llvm-gcov

WORKDIR /src
