# kubectl
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k

# kustomize
source <(kustomize completion bash)

# stern
source <(stern --completion bash)

# helm
source <(helm completion bash)

# k9s
source <(k9s completion bash)

# argocd
source <(argocd completion bash)

# bash environment
eval "$(starship init bash)"

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'