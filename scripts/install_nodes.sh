#!/usr/bin/env bash
# ============================================================
# MiniMax H3 워크플로우 전용 커스텀 노드 설치 스크립트
# 사용법: bash install_nodes.sh [COMFYUI_CUSTOM_NODES_DIR]
#   기본값: $HOME/ComfyUI/custom_nodes  (RunPod 기본 경로)
# ============================================================
set -euo pipefail

NODES_DIR="${1:-$HOME/ComfyUI/custom_nodes}"
mkdir -p "$NODES_DIR"
cd "$NODES_DIR"

echo ">> 커스텀 노드 디렉토리: $NODES_DIR"

# Python 실행기 결정 (RunPod은 /usr/bin/python3, 포터블은 venv 등)
PY=python
command -v python3 >/dev/null 2>&1 && PY=python3

install_node() {
  local name="$1" repo="$2" req="$3"
  if [[ -d "$name" ]]; then
    echo "== [SKIP] $name 이미 존재"
    return
  fi
  echo "== [CLONE] $name ($repo)"
  git clone --depth 1 "$repo" "$name"
  if [[ -n "$req" && -f "$name/requirements.txt" ]]; then
    echo "== [PIP] $name requirements 설치"
    "$PY" -m pip install -r "$name/requirements.txt" || echo "   (pip 실패했지만 계속 진행)"
  fi
}

install_node "deno-custom-nodes" \
  "https://github.com/Deno2026/comfyui-deno-custom-nodes.git" \
  "requirements.txt"

install_node "ComfyUI-VideoHelperSuite" \
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" \
  "requirements.txt"

echo ">> 커스텀 노드 설치 완료."
ls -d */ | head -30
