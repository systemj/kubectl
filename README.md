# kubectl image
A container image with kubectl, helm, stern, kubectx, and kubens installed, with common aliases and all completions enabled.

Some other helpful tools are installed such as curl and jq.

## build
```bash
DOCKER_BUILDKIT=1 docker build -t kubectl .
```

## launch
Example using an existing kube config:
```bash
docker run -i -t --rm -v"$(HOME)/.kube:/home/user/.kube" kubectl:latest
```
