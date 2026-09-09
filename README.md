# ComfyUI MiniMax H3 — Reference-to-Video 셋업

[MiniMax H3](https://www.minimax.io/blog/minimax-h3) 오디오·비디오·이미지 통합 생성 모델의
**Reference-to-Video (ref2va)** 워크플로우와 RunPod을 포함한 모든 환경의 자동 설치 스크립트입니다.

---

## 포함된 파일

```
├── workflows/
│   └── minimax_h3_ref2va_acc_multiref_audio.json
├── scripts/
│   ├── startup.sh          ← RunPod 자동 셋업 (이것만 쓰면 됨)
│   ├── download_models.sh
│   ├── install_nodes.sh
│   └── runpod_setup.sh
```

---

## RunPod 자동 셋업 (추천 — 5분 이내)

### 방법 1: 팟 생성 시 Docker Args (가장 빠름)

1. RunPod 콘솔 → **New Pod**
2. 이미지: `runpod/comfyui:1.4.7-cuda13.0` 선택
3. **Volume**: 50GB (`/workspace`)
4. **Container Disk**: 40GB+
5. **Docker Args** 또는 **Environment Variables**에:

```
Docker Args:
bash -c "git clone --depth 1 https://github.com/dlsrms4-jpg/comfyui-minimax-h3.git /workspace/comfyui-minimax-h3 && bash /workspace/comfyui-minimax-h3/scripts/startup.sh"
```

또는 ComfyUI가 시작된 후 Web Terminal에서:

```bash
bash /workspace/comfyui-minimax-h3/scripts/startup.sh
```

### 방법 2: Web Terminal에서 수동 실행

```bash
cd /workspace
git clone --depth 1 https://github.com/dlsrms4-jpg/comfyui-minimax-h3.git
bash comfyui-minimax-h3/scripts/startup.sh
```

### 첫 실행 vs 재사용

| | 첫 실행 | 두 번째부터 |
|---|---|---|
| 모델 다운로드 | ~42GB (20분) | **SKIP** (볼륨에 보존) |
| 커스텀 노드 | git clone + pip (3분) | **SKIP** (이미 설치됨) |
| ComfyUI 업데이트 | v0.30 → v0.34 (3분) | **SKIP** (이미 최신) |
| 워크플로우 복사 | 즉시 | 즉시 |
| **총 소요** | **~25분** | **~30초** |

> **팁**: 같은 볼륨을 재사용하면 모델 재다운로드 없이 바로 시작됩니다.
> 팟을 종료(STOP)해도 볼륨은 유지되니, 다음에 팟을 켤 때 startup.sh만 실행하면 됩니다.

---

## 수동 설치

### 모델 파일 (약 42GB)

| 파일 | 폴더 | 크기 |
|------|------|------|
| minimax_h3_video_vae_fp16.safetensors | models/vae/ | ~5.2GB |
| minimax_h3_audio_vae_fp32.safetensors | models/vae/ | ~0.6GB |
| minimax_h3_ref2va_pruned_int8_convrot.safetensors | models/unet/ | ~20GB |
| qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors | models/text_encoders/ | ~15GB |
| MiniMax-H3-Ref2VA-Acc-8Step.safetensors | models/minimax_h3_acc_loras/ | ~1.4GB |

### 커스텀 노드

| 노드 | GitHub |
|------|--------|
| comfyui-deno-custom-nodes | [Deno2026/comfyui-deno-custom-nodes](https://github.com/Deno2026/comfyui-deno-custom-nodes) |
| ComfyUI-VideoHelperSuite | [Kosinkadink/ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite) |

> ⚠️ **ComfyUI v0.34+ 필수** — RunPod 기본 이미지(v0.30)에는 ModelAttentionBackend 노드가 없어 워크플로우 오류 발생. startup.sh가 자동 업데이트합니다.

---

## 워크플로우 사용법

1. ComfyUI 접속 (RunPod: Connect → HTTP 8188)
2. 파일 탐색기 또는 드래그앤드롭으로 JSON 로드
3. **Main prompt**에 영문 프롬프트 입력
4. **Seconds**로 영상 길이 설정
5. **Queue Prompt** 실행

---

## 참고 링크

- [MiniMax H3 블로그](https://www.minimax.io/blog/minimax-h3)
- [Comfy-Org/MiniMax-H3](https://huggingface.co/Comfy-Org/MiniMax-H3)
- [deno-custom-nodes](https://github.com/Deno2026/comfyui-deno-custom-nodes)
