#!/usr/bin/env bash
set -euo pipefail

: "${SHA_TAG:?Need SHA_TAG}"          # 这次部署用的不可变标签（commit SHA）
: "${REGISTRY:=ghcr.io}"              # 默认 GHCR
: "${OWNER:?Need OWNER}"              # 你的 GHCR 命名空间/组织
: "${REPO_NAME:=mini-cicd}"           # 仓库名，便于通用

# 1) 拉镜像
echo "[pull] $REGISTRY/$OWNER/$REPO_NAME-web:$SHA_TAG"
docker pull "$REGISTRY/$OWNER/$REPO_NAME-web:$SHA_TAG"

# 2) 用 commit SHA 渲染 index.html（仅演示：显示当前版本）
#    做法：从镜像里复制出 index.html，替换后再覆盖回容器的方式
#    为了简单，我们直接在 compose 使用镜像，不改容器内文件；
#    把 SHA 写入一个环境文件或标签更常见。这里用 override 的 LABEL 演示。
cat > docker-compose.override.yml <<EOF
services:
  web:
    image: $REGISTRY/$OWNER/$REPO_NAME-web:$SHA_TAG
    labels:
      commit-sha: "$SHA_TAG"
EOF

# 3) 启动/更新
docker compose up -d

# 4) 健康探测（可选）
echo "[health] curl localhost/"
sleep 2
curl -fsS http://localhost/ >/dev/null && echo "OK"

# 5) 清理悬挂镜像（可选）
docker image prune -f >/dev/null 2>&1 || true

echo "Deploy done: $SHA_TAG"
