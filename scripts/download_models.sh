#!/usr/bin/env bash
# ============================================================
# MiniMax H3 (ref2va) 필수 모델 다운로드 스크립트
# 사용법: bash download_models.sh [COMFYUI_MODELS_DIR]
#   기본값: $HOME/ComfyUI/models  (RunPod 기본 ComfyUI 경로)
#   예:    bash download_models.sh /workspace/ComfyUI/models
# ============================================================
set -euo pipefail

MODELS_DIR="${1:-$HOME/ComfyUI/models}"
BASE="https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main"
ACC_BASE="https://huggingface.co/alibaba-pai/MiniMax-H3-Acc-LoRAs/resolve/main"

# (대상폴더|파일명|URL)
FILES=(
  "vae|minimax_h3_video_vae_fp16.safetensors|$BASE/vae/minimax_h3_video_vae_fp16.safetensors"
  "vae|minimax_h3_audio_vae_fp32.safetensors|$BASE/vae/minimax_h3_audio_vae_fp32.safetensors"
  "diffusion_models|minimax_h3_ref2va_pruned_int8_convrot.safetensors|$BASE/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors"
  "text_encoders|qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors|$BASE/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors"
  "loras|MiniMax-H3-Ref2VA-Acc-8Step.safetensors|$ACC_BASE/MiniMax-H3-Ref2VA-Acc-8Step.safetensors"
)

echo ">> 대상 모델 디렉토리: $MODELS_DIR"
mkdir -p "$MODELS_DIR"/{vae,diffusion_models,text_encoders,loras}

DL=""
if command -v aria2c >/dev/null 2>&1; then
  DL="aria2c -x 16 -s 16 -c"
  echo ">> 다운로더: aria2c (16분할)"
elif command -v wget >/dev/null 2>&1; then
  DL="wget -c"
  echo ">> 다운로더: wget"
elif command -v curl >/dev/null 2>&1; then
  DL="curl -L -C - -o"
  echo ">> 다운로더: curl"
else
  echo "!! aria2c/wget/curl 중 하나가 필요합니다."; exit 1
fi

for entry in "${FILES[@]}"; do
  IFS='|' read -r subdir fname url <<< "$entry"
  dest="$MODELS_DIR/$subdir/$fname"
  if [[ -f "$dest" && -s "$dest" ]]; then
    echo "== [SKIP] 이미 존재: $fname ($(du -h "$dest" | cut -f1))"
    continue
  fi
  echo "== [GET]  $fname -> $MODELS_DIR/$subdir/"
  if [[ "$DL" == curl* ]]; then
    $DL "$dest" "$url"
  else
    $DL "$url" -d "$dest"
  fi
done

echo ">> 모델 다운로드 완료."
echo "   확인:"
find "$MODELS_DIR"/{vae,diffusion_models,text_encoders,loras} -name "*minimax*" -o -name "*MiniMax-H3*" -o -name "qwen3vl_32b*" 2>/dev/null | sort
