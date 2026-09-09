# ComfyUI MiniMax H3 — Reference-to-Video 셋업

[MiniMax H3](https://www.minimax.io/blog/minimax-h3) 오디오·비디오·이미지 통합 생성 모델의
**Reference-to-Video (ref2va)** 워크플로우와 RunPod을 포함한 모든 환경의 자동 설치 스크립트입니다.

---

## 포함된 파일

```
├── workflows/
│   └── minimax_h3_ref2va_acc_multiref_audio.json   ← ComfyUI 워크플로우
├── scripts/
│   ├── download_models.sh    ← 모델 파일 5종 다운로드
│   ├── install_nodes.sh      ← 커스텀 노드 설치
│   └── runpod_setup.sh       ← RunPod 원클릭 셋업
```

---

## 필수 모델 파일 (약 42GB)

| 파일 | 폴더 | 크기 | 출처 |
|------|------|------|------|
| `minimax_h3_video_vae_fp16.safetensors` | `models/vae/` | ~5.2GB | [Comfy-Org/MiniMax-H3](https://huggingface.co/Comfy-Org/MiniMax-H3) |
| `minimax_h3_audio_vae_fp32.safetensors` | `models/vae/` | ~0.6GB | Comfy-Org/MiniMax-H3 |
| `minimax_h3_ref2va_pruned_int8_convrot.safetensors` | `models/diffusion_models/` | ~21GB | Comfy-Org/MiniMax-H3 |
| `qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors` | `models/text_encoders/` | ~15.7GB | Comfy-Org/MiniMax-H3 |
| `MiniMax-H3-Ref2VA-Acc-8Step.safetensors` | `models/loras/` | ~1.4GB | [alibaba-pai/MiniMax-H3-Acc-LoRAs](https://huggingface.co/alibaba-pai/MiniMax-H3-Acc-LoRAs) |

---

## 설치 방법

### 1) RunPod에서 (원클릭)

```bash
git clone https://github.com/dlsrms4-jpg/comfyui-minimax-h3.git
bash comfyui-minimax-h3/scripts/runpod_setup.sh
```

### 2) 로컬 ComfyUI 포터블에서 (Windows)

```bash
cd C:\Users\<you>\Desktop\ComfyUI_windows_portable_nvidia\ComfyUI_windows_portable\ComfyUI
bash /path/to/download_models.sh ./models
bash /path/to/install_nodes.sh ./custom_nodes
```

### 3) 수동 설치

#### 모델 다운로드

```bash
bash scripts/download_models.sh /path/to/ComfyUI/models
```
- `aria2c`(기본 16분할), `wget`, `curl` 중 하나 필요
- 이미 존재하는 파일은 자동 건너뜀

#### 커스텀 노드 설치

```bash
bash scripts/install_nodes.sh /path/to/ComfyUI/custom_nodes
```

| 노드 | GitHub |
|------|--------|
| **deno-custom-nodes** | [Deno2026/comfyui-deno-custom-nodes](https://github.com/Deno2026/comfyui-deno-custom-nodes) |
| **ComfyUI-VideoHelperSuite** | [Kosinkadink/ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite) |

---

## 워크플로우 사용법

1. ComfyUI를 실행합니다.
2. `workflows/minimax_h3_ref2va_acc_multiref_audio.json`을 드래그 앤 드롭으로 불러옵니다.
3. **Reference Image Loader**에 입력 이미지를 연결합니다.
4. **Main prompt (manual)**에 영문 프롬프트를 입력합니다.
   - `<Picture 1>` 태그로 연결된 이미지를 참조합니다.
5. **Seconds** 슬라이더로 영상 길이를 설정합니다 (기본 2초).
6. **Queue Prompt**를 눌러 생성합니다.

### 출력

- 영상: `output/minimax_h3_acc_multiref_audio/` 폴더에 MP4로 저장
- 해상도 예시: 960×544 (16:9, 0.5MP 기준), 124프레임 ≈ 약 5초

### 권장 설정

| 항목 | 권장값 |
|------|--------|
| Sampler | `euler` |
| Scheduler | `simple` 또는 `normal` |
| Steps | 8 |
| Ref Image Size | `match` (빠르게) 또는 `max` (정밀도 높게) |

---

## 참고 링크

- [MiniMax H3 블로그 포스트](https://www.minimax.io/blog/minimax-h3)
- [Comfy-Org/MiniMax-H3 HuggingFace](https://huggingface.co/Comfy-Org/MiniMax-H3)
- [ComfyUI MiniMax H3 PR #15224](https://github.com/Comfy-Org/ComfyUI/pull/15224)
- [Acc LoRA 소스](https://huggingface.co/alibaba-pai/MiniMax-H3-Acc-LoRAs)

---

## 라이선스

[MiniMax H3 Community License Agreement](https://huggingface.co/Comfy-Org/MiniMax-H3/blob/main/LICENSE)
