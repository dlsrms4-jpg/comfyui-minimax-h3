#!/usr/bin/env bash
# ============================================================
# RunPod ComfyUI 원클릭 셋업 스크립트 (MiniMax H3 ref2va)
# RunPod 템플릿 "RunPod ComfyUI" 기준 (ComfyUI가 $HOME/ComfyUI에 있음)
#
# 사용법:
#   bash runpod_setup.sh
# 또는 저장소 클론 후:
#   git clone https://github.com/dlsrms4-jpg/comfyui-minimax-h3.git
#   bash comfyui-minimax-h3/scripts/runpod_setup.sh
# ============================================================
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-$HOME/ComfyUI}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY=python
command -v python3 >/dev/null 2>&1 && PY=python3

echo "########################################"
echo "# 1/3 ComfyUI 최신 버전으로 업데이트"
echo "########################################"
if [[ -d "$COMFYUI_DIR/.git" ]]; then
  git -C "$COMFYUI_DIR" pull --ff-only || echo "   (pull 실패 — 리베이스 등 로컬 변경 확인 필요)"
  "$PY" -m pip install -r "$COMFYUI_DIR/requirements.txt" || true
else
  echo "!! $COMFYUI_DIR 에 ComfyUI가 없습니다. COMFYUI_DIR 환경변수로 경로를 지정하세요."
  exit 1
fi

echo ""
echo "########################################"
echo "# 2/3 모델 다운로드 (약 40GB, 시간 소요)"
echo "########################################"
bash "$REPO_ROOT/scripts/download_models.sh" "$COMFYUI_DIR/models"

echo ""
echo "########################################"
echo "# 3/3 커스텀 노드 설치"
echo "########################################"
bash "$REPO_ROOT/scripts/install_nodes.sh" "$COMFYUI_DIR/custom_nodes"

echo ""
echo "########################################"
echo "# 완료! RunPod에서 ComfyUI 재시작 후"
echo "# workflows/minimax_h3_ref2va_acc_multiref_audio.json 불러오기"
echo "########################################"
