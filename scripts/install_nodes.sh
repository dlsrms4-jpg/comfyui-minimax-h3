#!/usr/bin/env bash
# ============================================================
# MiniMax H3 워크플로우 전용 커스텀 노드 설치 스크립트
# 사용법: bash install_nodes.sh [COMFYUI_DIR]
#   기본: 자동 감지
#     RunPod 공식 이미지: /workspace/runpod-slim/ComfyUI
#     일반 RunPod:        /workspace/ComfyUI
#     로컬/기타:          $HOME/ComfyUI
# ============================================================
set -euo pipefail

detect_comfyui_dir() {
  for d in "$1" "/workspace/runpod-slim/ComfyUI" "/workspace/ComfyUI" "$HOME/ComfyUI"; do
    if [[ -n "$d" && -d "$d" && -d "$d/custom_nodes" ]]; then
      echo "$d"
      return 0
    fi
  done
  # custom_nodes 없어도 ComfyUI 메인 디렉토리로 판단 (첫 설치 시)
  for d in "$1" "/workspace/runpod-slim/ComfyUI" "/workspace/ComfyUI" "$HOME/ComfyUI"; do
    if [[ -n "$d" && -d "$d" && -f "$d/main.py" ]]; then
      echo "$d"
      return 0
    fi
  done
  echo ""
}

COMFYUI_DIR="$(detect_comfyui_dir "${1:-}")"
if [[ -z "$COMFYUI_DIR" ]]; then
  echo "!! ComfyUI 디렉토리를 찾지 못했습니다. 첫 인자로 경로를 지정하세요:"
  echo "   bash install_nodes.sh /workspace/runpod-slim/ComfyUI"
  exit 1
fi

NODES_DIR="$COMFYUI_DIR/custom_nodes"
mkdir -p "$NODES_DIR"
cd "$NODES_DIR"
echo ">> 커스텀 노드 디렉토리: $NODES_DIR"

# Python 실행기 결정 — RunPod 이미지는 venv를 사용 (.venv-cu128 / .venv)
PY=python
if [[ -x "$COMFYUI_DIR/.venv-cu128/bin/python" ]]; then
  PY="$COMFYUI_DIR/.venv-cu128/bin/python"
elif [[ -x "$COMFYUI_DIR/.venv/bin/python" ]]; then
  PY="$COMFYUI_DIR/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PY=python3
fi
echo ">> Python: $PY"
"$PY" -m pip --version >/dev/null 2>&1 || { echo "!! pip 사용 불가"; exit 1; }

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

echo ""
echo ">> 설치된 노드 (MiniMax H3 관련):"
ls -d deno-custom-nodes ComfyUI-VideoHelperSuite 2>/dev/null
echo ""
echo ">> 중요: ComfyUI 재시작 필요 (RunPod 콘솔에서 Stop → Start, 또는 아래 명령)"
echo "   cd $COMFYUI_DIR && supervisorctl restart comfyui 2>/dev/null || pkill -f 'main.py' || true"