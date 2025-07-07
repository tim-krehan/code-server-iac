# Use the base image for code-server
FROM ghcr.io/coder/code-server:4.101.2-noble

LABEL DESCRIPTION="Development environment for infrastructure-as-code with code-server, Go, Python, Kubernetes, Terraform, and related tools."

# github-releases:golang/go
ARG GOLANG_VERSION=1.24.4
# github-releases:helm/helm
ARG HELM_VERSION=3.18.3
# managed manually, must match the cluster :)
ARG KUBECTL_VERSION=1.33.1
# github-releases:hashicorp/terraform
ARG TERRAFORM_VERSION=1.12.2
# github-releases:terraform-linters/tflint
ARG TFLINT_VERSION=0.58.0
# github-releases:PowerShell/PowerShell
ARG POWERSHELL_VERSION=7.5.1
# github-releases:argoproj/argo-cd
ARG ARGOCD_VERSION=3.0.6
# github-releases:derailed/k9s
ARG K9S_VERSION=0.50.7
# managed manually
ARG PYTHON_VERSION=3.12

LABEL GOLANG_VERSION=${GOLANG_VERSION} \
      HELM_VERSION=${HELM_VERSION} \
      KUBECTL_VERSION=${KUBECTL_VERSION} \
      TERRAFORM_VERSION=${TERRAFORM_VERSION} \
      TFLINT_VERSION=${TFLINT_VERSION} \
      POWERSHELL_VERSION=${POWERSHELL_VERSION} \
      ARGOCD_VERSION=${ARGOCD_VERSION} \
      K9S_VERSION=${K9S_VERSION} \
      PYTHON_VERSION=${PYTHON_VERSION}

# Install necessary tools for Dockerfile development and rootless Docker
USER root

# Set non-interactive frontend for debconf to avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools and dependencies
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    software-properties-common \
    bash-completion \
    unzip \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION%%.*}-venv \
    python${PYTHON_VERSION%%.*}-pip \
    curl \
    git \
    vim \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install k9s
RUN set -eux; \
    curl -sSLO https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_linux_amd64.deb && \
    dpkg -i k9s_linux_amd64.deb && rm k9s_linux_amd64.deb && \
    # Install ArgoCD CLI
    curl -fsSL -o /usr/local/bin/argocd "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" && \
    chmod +x /usr/local/bin/argocd && \
    # Install Go
    curl -fsSL https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xz && \
    ln -s /usr/local/go/bin/go /usr/bin/go &&\
    mkdir -p /go/bin && chmod -R 777 /go && chown -R coder:coder /go && \
    # Install Helm, kubectl, Terraform, TFLint
    curl -fsSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xz && mv linux-amd64/helm /usr/local/bin/helm && \
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && chmod +x kubectl && mv kubectl /usr/local/bin/ && \
    curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && unzip terraform.zip && mv terraform /usr/local/bin/ && rm terraform.zip && \
    curl -fsSL https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip -o tflint.zip && unzip tflint.zip && mv tflint /usr/local/bin/ && rm tflint.zip &&\
    # Install PowerShell
    curl -fsSL https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-x64.tar.gz | tar -xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/pwsh && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    # Install Starship
    curl -sS https://starship.rs/install.sh | sh -s -- --yes && \
    # Install GitHub CLI
    sudo mkdir -p -m 755 /etc/apt/keyrings && \
    wget -nv -O/tmp/ghcli.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    cat /tmp/ghcli.gpg > /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/* /tmp/ghcli.gpg

# Switch back to the non-root user
USER coder

ENV PATH=$PATH:/go/bin
ENV GOPATH=/go

# Install Go packages
RUN go install github.com/arttor/helmify/cmd/helmify@latest && \
    go install sigs.k8s.io/kustomize/kustomize/v5@latest && \
    go install github.com/stern/stern@latest

ENV CODER_VERSION_IAC=$CODER_VERSION
