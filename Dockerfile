# Use the base image for code-server
FROM ghcr.io/coder/code-server:4.108.0-noble

ARG CODE_SERVER_IAC_VERSION=0.0.0

# github-releases:argoproj/argo-cd
ARG ARGOCD_VERSION=3.2.5
# github-releases:cli/cli
ARG GHCLI_VERSION=2.83.2
# github-releases:hickford/git-credential-oauth
ARG GIT_CREDENTIAL_OAUTH_VERSION=0.17.2
# github-releases:golang/go
ARG GOLANG_VERSION=1.24.4
# github-releases:helm/helm
ARG HELM_VERSION=4.0.4
# github-releases:arttor/helmify
ARG HELMIFY_VERSION=0.4.19
# github-releases:derailed/k9s
ARG K9S_VERSION=0.50.18
# github-tags:kubernetes/kubectl
ARG KUBECTL_VERSION=1.34.2
# github-releases:kubernetes-sigs/krew
ARG KREW_VERSION=0.4.5
# github-releases:kubernetes/kompose
ARG KOMPOSE_VERSION=1.37.0
# github-releases:kubernetes-sigs/kustomize
ARG KUSTOMIZE_VERSION=5.6.0
# github-releases:PowerShell/PowerShell
ARG POWERSHELL_VERSION=7.5.4
# github-tags:python/cpython
ARG PYTHON_VERSION=3.14.2
# github-releases:stern/stern
ARG STERN_VERSION=1.33.1
# github-releases:hashicorp/terraform
ARG TERRAFORM_VERSION=1.14.3
# github-releases:terraform-linters/tflint
ARG TFLINT_VERSION=0.60.0

# Install necessary tools for Dockerfile development and rootless Docker
USER root

# Set non-interactive frontend for debconf to avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools and dependencies
RUN set -eux; apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    --no-install-recommends \
    software-properties-common \
    bash-completion \
    unzip \
    curl \
    git \
    vim \
    jq \
    iputils-ping \
    netcat-openbsd && \
    add-apt-repository ppa:deadsnakes/ppa --yes && \
    apt-get install -y \
    python${PYTHON_VERSION%.*} \
    python${PYTHON_VERSION%%.*}-venv \
    python${PYTHON_VERSION%%.*}-pip && \
    rm -rf /var/lib/apt/lists/*

# k9s
RUN set -eux; \
    curl -fsSL https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz | tar -C /usr/local/bin/ -xz && \
    rm /usr/local/bin/LICENSE /usr/local/bin/README.md

# ArgoCD CLI
RUN set -eux; \
    curl -fsSL -o /usr/local/bin/argocd "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" && \
    chmod +x /usr/local/bin/argocd

# Go
RUN set -eux; \
    curl -fsSL https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xz && \
    ln -s /usr/local/go/bin/go /usr/bin/go && \
    mkdir -p /go/bin && chmod -R 777 /go && chown -R coder:coder /go

# Helm
RUN set -eux; \
    curl --retry 5 --retry-delay 2 -fsSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz && \
    tar -xzf helm.tar.gz && mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 helm.tar.gz

# Helmify
RUN set -eux; \
    curl -fsSL https://github.com/arttor/helmify/releases/download/v${HELMIFY_VERSION}/helmify_Linux_x86_64.tar.gz |tar -C /usr/local/bin/ -xz

# kustomize
RUN set -eux; \
    curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz |tar -C /usr/local/bin/ -xz

# kubectl
RUN set -eux; \
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# stern
RUN set -eux; \
    curl -fsSL https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_amd64.tar.gz |tar -C /usr/local/bin/ -xz \
    && rm /usr/local/bin/LICENSE

# kompose
RUN set -eux; \
    curl -L https://github.com/kubernetes/kompose/releases/download/v${KOMPOSE_VERSION}/kompose-linux-amd64 -o kompose && \
    chmod +x kompose && \
    mv ./kompose /usr/local/bin/kompose

# Install Terraform
RUN set -eux; \
    curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip

# TFLint
RUN set -eux; \
    curl -fsSL https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip -o tflint.zip && \
    unzip tflint.zip && \
    mv tflint /usr/local/bin/ && \
    rm tflint.zip

# Install PowerShell
RUN set -eux; \
    curl -fsSL https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-x64.tar.gz | tar -xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/pwsh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Starship
RUN set -eux; \
    curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Install GitHub CLI
RUN set -eux; \
    curl -fsSL https://github.com/cli/cli/releases/download/v${GHCLI_VERSION}/gh_${GHCLI_VERSION}_linux_amd64.tar.gz | tar -xz -C /tmp && \
    mv /tmp/gh_${GHCLI_VERSION}_linux_amd64/bin/gh /usr/bin/ && \
    rm -rf /tmp/gh_${GHCLI_VERSION}_linux_amd64

# Install git-credential-oauth
RUN set -eux; \
    curl -fsSL https://github.com/hickford/git-credential-oauth/releases/download/v${GIT_CREDENTIAL_OAUTH_VERSION}/git-credential-oauth_${GIT_CREDENTIAL_OAUTH_VERSION}_linux_amd64.tar.gz | tar -xz -C /usr/local/bin/

# Switch back to the non-root user
USER coder

# krew installation
RUN cd "$(mktemp -d)" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v${KREW_VERSION}/krew-linux_amd64.tar.gz" && \
    tar zxvf "krew-linux_amd64.tar.gz" && \
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" && \
    ./krew-linux_amd64 install krew && \
    kubectl krew install oidc-login

ENV PATH=$PATH:/go/bin
ENV GOPATH=/go
ENV CODE_SERVER_IAC_VERSION=${CODE_SERVER_IAC_VERSION}

LABEL org.opencontainers.image.description="Development environment for infrastructure-as-code with code-server, Go, Python, Kubernetes, Terraform, and related tools."
LABEL ARGOCD_VERSION=${ARGOCD_VERSION} \
      GHCLI_VERSION=${GHCLI_VERSION} \
      GIT_CREDENTIAL_OAUTH_VERSION=${GIT_CREDENTIAL_OAUTH_VERSION} \
      GOLANG_VERSION=${GOLANG_VERSION} \
      HELM_VERSION=${HELM_VERSION} \
      HELMIFY_VERSION=${HELMIFY_VERSION} \
      K9S_VERSION=${K9S_VERSION} \
      KUBECTL_VERSION=${KUBECTL_VERSION} \
      KREW_VERSION=${KREW_VERSION} \
      KOMPOSE_VERSION=${KOMPOSE_VERSION} \
      KUSTOMIZE_VERSION=${KUSTOMIZE_VERSION} \
      POWERSHELL_VERSION=${POWERSHELL_VERSION} \
      PYTHON_VERSION=${PYTHON_VERSION} \
      STERN_VERSION=${STERN_VERSION} \
      TERRAFORM_VERSION=${TERRAFORM_VERSION} \
      TFLINT_VERSION=${TFLINT_VERSION}
