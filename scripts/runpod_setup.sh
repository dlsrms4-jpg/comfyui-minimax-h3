#!/usr/bin/env bash
# ============================================================
# RunPod ComfyUI 원클릭 셋업 스크립트 (MiniMax H3 ref2va)
#
# RunPod 공식 ComfyUI 이미지 기준:
#   ComfyUI = /workspace/runpod-slim/ComfyUI  (자동 감지)
#
# 사용법:
#   git clone https://github.com/dlsrms4-jpg/comfyui-minimax-h3.git
#   bash comfyui-minimax-h3/scripts/runpod_setup.sh
# ============================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- ComfyUI 경로 자동 감지 ---
detect_comfyui_dir() {
  for d in "${COMFYUI_DIR:-}" "/workspace/runpod-slim/ComfyUI" "/workspace/ComfyUI" "$HOME/ComfyUI"; do
    if [[ -n "$d" && -d "$d" && -f "$d/main.py" ]]; then
      echo "$d"
      return 0
    fi
  done
  echo ""
}

COMFYUI_DIR="$(detect_comfyui_dir)"
if [[ -z "$COMFYUI_DIR" ]]; then
  echo "!! ComfyUI 디렉토리를 찾지 못했습니다:"
  ls -la /workspace 2>/dev/null || true
  find / -maxdepth 3 -name "main.py" -path "*ComfyUI*" 2>/dev/null || true
  exit 1
fi

PY=python
if [[ -x "$COMFYUI_DIR/.venv-cu128/bin/python" ]]; then
  PY="$COMFYUI_DIR/.venv-cu128/bin/python"
elif [[ -x "$COMFYUI_DIR/.venv/bin/python" ]]; then
  PY="$COMFYUI_DIR/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PY=python3
fi
echo ">> ComfyUI 디렉토리: $COMFYUI_DIR"
echo ">> Python: $PY"

echo ""
echo "########################################"
echo "# 1/4 모델 다운로드 (~42GB, 시간 소요)"
echo "########################################"
bash "$REPO_ROOT/scripts/download_models.sh" "$COMFYUI_DIR/models"

echo ""
echo "########################################"
echo "# 2/4 커스텀 노드 설치 (deno-custom-nodes, VHS)"
echo "########################################"
bash "$REPO_ROOT/scripts/install_nodes.sh" "$COMFYUI_DIR"

echo ""
echo "########################################"
echo "# 3/4 워크플로우 배치"
echo "########################################"
mkdir -p "$COMFYUI_DIR/user/default/workflows"
cp "$REPO_ROOT/workflows/minimax_h3_ref2va_acc_multiref_audio.json" \
   "$COMFYUI_DIR/user/default/workflows/"
echo ">> workflows/minimax_h3_ref2va_acc_multiref_audio.json 복사 완료"

echo ""
echo "########################################"
echo "# 4/4 ComfyUI 재시작"
echo "########################################"
# RunPod 이미지의 프로세스 관리자로 재시작 시도
if command -v supervisorctl >/dev/null 2>&1 && supervisorctl status comfyui >/dev/null 2>&1; then
  supervisorctl restart comfyui || true
else
  pkill -f "main.py" || true
  echo "   (재시작 시도됨 — 30초 내 자동 복구되는지 확인)"
fi

echo ""
echo "########################################"
echo "# 완료!"
echo "# ComfyUI 접속: RunPod 콘솔 → Connect → HTTP 8188"
echo "# 워크플로우: Workflows 패널 또는 드래그앤드롭"
echo "########################################"