#!/bin/bash
# ============================================================
# RunPod MiniMax H3 자동 셋업 (팟 시작 시 자동 실행)
# 
# 사용법: RunPod 팟 생성 시 Docker Args에 추가:
#   bash /workspace/comfyui-minimax-h3/scripts/startup.sh
#
# 또는 환경변수로:
#   STARTUP_SCRIPT=/workspace/comfyui-minimax-h3/scripts/startup.sh
#
# 첫 실행: ~5분 (모델은 persistent volume에 저장되므로 다음부터 즉시)
# ============================================================
set -euo pipefail

COMFY_DIR="/workspace/runpod-slim/ComfyUI"
REPO_DIR="/workspace/comfyui-minimax-h3"
VENV="$COMFY_DIR/.venv-cu128"
REQUIRED_VERSION="0.34.7"
LOG="/tmp/startup-setup.log"

exec > >(tee -a "$LOG") 2>&1
echo "$(date): === MiniMax H3 자동 셋업 시작 ==="

# --- 1. GitHub 리포지토리 확인/업데이트 ---
echo "[1/5] GitHub 리포지토리 확인..."
if [ ! -d "$REPO_DIR" ]; then
  cd /workspace
  git clone --depth 1 https://github.com/dlsrms4-jpg/comfyui-minimax-h3.git
  echo "  클론 완료"
else
  cd "$REPO_DIR"
  git pull --ff-only 2>/dev/null || echo "  이미 최신"
fi

# --- 2. ComfyUI 버전 확인/업데이트 ---
echo "[2/5] ComfyUI 버전 확인..."
CURRENT_VER=$(cat "$COMFY_DIR/comfyui_version.py" 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")
echo "  현재: v$CURRENT_VER / 필요: v$REQUIRED_VERSION"
if [ "$CURRENT_VER" != "$REQUIRED_VERSION" ]; then
  echo "  업데이트 중..."
  cd "$COMFY_DIR"
  git fetch --tags 2>/dev/null
  git checkout "v$REQUIRED_VERSION" 2>/dev/null || git checkout "v0.34.5" 2>/dev/null
  $VENV/bin/pip install -r requirements.txt -q 2>/dev/null
  echo "  업데이트 완료"
else
  echo "  버전 OK"
fi

# --- 3. 커스텀 노드 확인/설치 ---
echo "[3/5] 커스텀 노드 확인..."
mkdir -p "$COMFY_DIR/custom_nodes"
cd "$COMFY_DIR/custom_nodes"

install_node() {
  local name="$1" repo="$2"
  if [ -d "$name" ]; then
    echo "  $name: 이미 설치됨"
  else
    echo "  $name: 설치 중..."
    git clone --depth 1 "$repo" "$name"
    [ -f "$name/requirements.txt" ] && $VENV/bin/pip install -r "$name/requirements.txt" -q 2>/dev/null
    echo "  $name: 완료"
  fi
}

install_node "comfyui-deno-custom-nodes" "https://github.com/Deno2026/comfyui-deno-custom-nodes.git"
install_node "ComfyUI-VideoHelperSuite" "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# sageattention (KJNodes의 PatchSageAttentionKJ 노드 의존성)
if ! $VENV/bin/python -c "import sageattention" 2>/dev/null; then
  echo "  sageattention: 설치 중..."
  $VENV/bin/pip install sageattention -q 2>/dev/null
  echo "  sageattention: 완료"
else
  echo "  sageattention: 이미 설치됨"
fi

# --- 4. 모델 파일 확인/다운로드 ---
echo "[4/5] 모델 파일 확인..."
MODELS_DIR="$COMFY_DIR/models"
mkdir -p "$MODELS_DIR"/{vae,text_encoders,unet,minimax_h3_acc_loras}

download_if_missing() {
  local dir="$1" name="$2" url="$3"
  if [ -f "$MODELS_DIR/$dir/$name" ]; then
    local size=$(stat -c%s "$MODELS_DIR/$dir/$name" 2>/dev/null || echo 0)
    if [ "$size" -gt 1000000 ]; then
      echo "  $name: 존재 ($(du -h "$MODELS_DIR/$dir/$name" | cut -f1))"
      return
    fi
  fi
  echo "  $name: 다운로드 중..."
  wget -q "$url" -O "$MODELS_DIR/$dir/$name"
  echo "  $name: 완료"
}

BASE="https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main"
download_if_missing "vae" "minimax_h3_video_vae_fp16.safetensors" "$BASE/vae/minimax_h3_video_vae_fp16.safetensors"
download_if_missing "vae" "minimax_h3_audio_vae_fp32.safetensors" "$BASE/vae/minimax_h3_audio_vae_fp32.safetensors"
download_if_missing "text_encoders" "qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors" "$BASE/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors"
download_if_missing "unet" "minimax_h3_ref2va_pruned_int8_convrot.safetensors" "$BASE/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors"
download_if_missing "minimax_h3_acc_loras" "MiniMax-H3-Ref2VA-Acc-8Step.safetensors" "https://huggingface.co/alibaba-pai/MiniMax-H3-Acc-LoRAs/resolve/main/MiniMax-H3-Ref2VA-Acc-8Step.safetensors"

# --- 5. 워크플로우 배치 + ComfyUI 재시작 ---
echo "[5/5] 워크플로우 + 재시작..."
mkdir -p "$COMFY_DIR/user/default/workflows"
cp -f "$REPO_DIR/workflows/minimax_h3_ref2va_acc_multiref_audio.json" "$COMFY_DIR/user/default/workflows/"

# ComfyUI 재시작
pkill -f "main.py" 2>/dev/null || true
sleep 3
cd "$COMFY_DIR"
nohup $VENV/bin/python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header > /tmp/comfyui.log 2>&1 &
echo "  ComfyUI 재시작됨 (pid $!)"

echo ""
echo "=========================================="
echo "  MiniMax H3 셋업 완료!"
echo "  ComfyUI: http://localhost:8188"
echo "=========================================="
