# Use a slim Ubuntu base image
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set arguments for non-root user
ARG USERNAME=cheng
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    bash \
    curl \
    ca-certificates \
    sudo \
    python3.10 \
    python3-pip && \
    ln -sf python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    rm -rf /var/lib/apt/lists/*

# Install Poetry (latest stable) to a root-owned path
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    ln -s /root/.local/bin/poetry /usr/local/bin/poetry

# Set Poetry environment variables to avoid virtualenv in Docker
ENV POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1

# Set working directory for app
WORKDIR /opt/app

# Copy only Poetry files first to leverage Docker layer caching
COPY pyproject.toml poetry.lock* ./

# Install dependencies as root
RUN poetry install --no-root

# Create non-root user with bash as default shell
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Change ownership of app dir and switch to user
RUN chown -R $USERNAME:$USERNAME /opt/app
USER $USERNAME

# Set user working directory
WORKDIR /opt/app

# Copy the rest of the source
COPY --chown=$USERNAME:$USERNAME . .

# Set bash as default shell for interactive containers
SHELL ["/bin/bash", "-c"]
