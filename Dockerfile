FROM ubuntu:22.04

# default args (versions)
ARG ARCH=amd64
ARG KUBECTL_VERSION=1.28.7
ARG HELM_VERSION=3.14.3
ARG STERN_VERSION=1.28.0
ARG KUBECTX_VERSION=0.9.5

# environment setup
ENV DEBIAN_FRONTEND=noninteractive
ENV ARCH=${ARCH}
ENV KUBECTL_VERSION=${KUBECTL_VERSION}
ENV HELM_VERSION=${HELM_VERSION}
ENV STERN_VERSION=${STERN_VERSION}
ENV KUBECTX_VERSION=${KUBECTX_VERSION}

# base updates and os packages
RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt-lib,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,id=debconf,target=/var/cache/debconf,sharing=locked \
<<EOF
    apt update && apt upgrade -y
    apt install -y curl bash-completion vim less jq iputils-ping
EOF

# kubectl
# install: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
# releases: https://kubernetes.io/releases/
RUN <<EOF
    curl -L -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
    chmod +x /usr/local/bin/kubectl
EOF

# helm
# install: https://helm.sh/docs/intro/install/
# releases: https://github.com/helm/helm/releases
RUN <<EOF
    curl -L -o - "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" | \
        tar -C /usr/local/bin -zxvf - --strip-components=1 linux-${ARCH}/helm
EOF

# stern
# install: https://github.com/stern/stern?tab=readme-ov-file#installation
# releases: https://github.com/stern/stern/releases
RUN <<EOF
    curl -L -o - "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_${ARCH}.tar.gz" | \
        tar -C /usr/local/bin -zxvf - stern
EOF

# kubens, kubectx
# install: https://github.com/ahmetb/kubectx/?tab=readme-ov-file#installation
# releases: https://github.com/ahmetb/kubectx/releases
RUN <<EOF
    if test "${ARCH}" = "amd64" ; then
        MACH=x86_64
    else
        MACH=${ARCH}
    fi
    curl -L -o - "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_linux_${MACH}.tar.gz" | \
        tar -C /usr/local/bin -zxvf - kubectx
    curl -L -o - "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_linux_${MACH}.tar.gz" | \
        tar -C /usr/local/bin -zxvf - kubens
    curl -L -o /usr/share/bash-completion/completions/kubectx "https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.bash" 
    curl -L -o /usr/share/bash-completion/completions/kubens "https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.bash"
EOF

# complete_alias
# install: https://github.com/cykerway/complete-alias?tab=readme-ov-file#install
RUN <<EOF
    curl -L -o /usr/share/bash-completion/completions/complete_alias "https://raw.githubusercontent.com/cykerway/complete-alias/master/complete_alias"
EOF

# non-root user setup
# odd indent due to nested heredocs
RUN <<EOF
    useradd -m user
    cat <<END >>/home/user/.bashrc

source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
source <(helm completion bash)
source <(stern --completion=bash)
source /usr/share/bash-completion/completions/kubectx
source /usr/share/bash-completion/completions/kubens
source /usr/share/bash-completion/completions/complete_alias

alias k=kubectl
alias kctx=kubectx
alias kns=kubens

complete -o default -F __start_kubectl k
complete -F _complete_alias kctx
complete -F _complete_alias kns
END
EOF

WORKDIR /home/user
USER user
