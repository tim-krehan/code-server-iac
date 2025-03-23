ARG CODER_VERSION

# Use the base image for code-server
FROM ghcr.io/coder/code-server:$CODER_VERSION-ubuntu

# Install necessary tools for Dockerfile development and rootless Docker
USER root

# Set non-interactive frontend for debconf to avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools or dependencies if needed
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    docker.io \
    docker-compose \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure rootless Podman
RUN mkdir -p /etc/containers && \
    echo -e "[registries.search]\nregistries = ['docker.io']" > /etc/containers/registries.conf

# Switch back to the non-root user
USER coder

# Install recommended VS Code extensions for Dockerfile development
RUN code-server --install-extension ms-azuretools.vscode-docker \
    && code-server --install-extension redhat.vscode-yaml

# Expose the default code-server port
# EXPOSE 8080

# WORKDIR /home/coder
# ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]
