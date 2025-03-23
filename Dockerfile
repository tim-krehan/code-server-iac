# Use the base image for code-server
FROM coder/code-server:CODER_VERSION-ubuntu

# Install necessary tools for Dockerfile development and rootless Docker
USER root

# Update and install required packages
RUN apt-get update && apt-get install -y \
    podman \
    fuse-overlayfs \
    slirp4netns \
    uidmap \
    iptables \
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
EXPOSE 8080

# Set the entrypoint to code-server
ENTRYPOINT ["dumb-init", "code-server"]

WORKDIR /home/coder
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]