#!/usr/bin/env bash
# ============================================================
# MiniMax H3 (ref2va) 필수 모델 다운로드 스크립트
# 사용법: bash download_models.sh [COMFYUI_MODELS_DIR]
#   미지정 시 자동 감지:
#     RunPod 공식: /workspace/runpod-slim/ComfyUI/models
#     일반 RunPod: /workspace/ComfyUI/models
#     로컬:        $HOME/ComfyUI/models
#   명시 예: bash download_models.sh /workspace/runpod-slim/ComfyUI/models
# ============================================================
set -euo pipefail

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

detect_models_dir() {
  local given="${1:-}"
  if [[ -n "$given" ]]; then
    echo "$given"
    return 0
  fi
  for d in "/workspace/runpod-slim/ComfyUI/models" "/workspace/ComfyUI/models" "$HOME/ComfyUI/models"; do
    if [[ -d "$d" ]]; then
      echo "$d"
      return 0
    fi
  done
  # ComfyUI 루트에서 models 폴더 탐색
  local found
  found=$(find /workspace "$HOME" -maxdepth 3 -type d -name models -path "*ComfyUI*" 2>/dev/null | head -1)
  if [[ -n "$found" ]]; then
    echo "$found"
    return 0
  fi
  echo ""
}

MODELS_DIR="$(detect_models_dir "${1:-}")"
if [[ -z "$MODELS_DIR" ]]; then
  echo "!! models 디렉토리를 찾지 못했습니다. 첫 인자로 경로를 지정하세요:"
  echo "   bash download_models.sh /workspace/runpod-slim/ComfyUI/models"
  exit 1
fi

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
find "$MODELS_DIR"/{vae,diffusion_models,text_encoders,loras} \( -name "*minimax*" -o -name "*MiniMax-H3*" -o -name "qwen3vl_32b*" \) 2>/dev/null | sort