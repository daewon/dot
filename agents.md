# AI 에이전트 작업 지침 (dot)

이 문서는 `dot` 레포에서 작업하는 에이전트를 위한 실무 지침입니다.
목표는 "설정 변경을 안전하게 적용하고, 재현 가능한 상태로 유지"하는 것입니다.

## 0) 기본 소통 원칙
- 사용자 응답은 기본적으로 한글로 작성합니다(사용자가 다른 언어를 요청하면 그 요청을 우선).
- 변경 내용은 "무엇을, 왜, 어떻게 검증했는지"를 짧고 명확하게 보고합니다.
- 사용자가 요청하지 않은 대규모 리팩터링/스타일 변경은 하지 않습니다.

## 1) 현재 레포 구조 (현실 기준)
- `config/tmux.conf.user`: tmux 핵심 설정
- `config/helix/config.toml`, `config/helix/languages.toml`: Helix 설정
- `config/lazygit/config.yml`, `config/lazygit/themes/*`: LazyGit 설정/테마
- `mise.toml`: 도구 버전 선언
- `scripts/lib/toolset.sh`: setup/cleanup/verify 공통 도구 목록 단일 소스
- `scripts/lib/scriptlib.sh`: setup/cleanup/verify 공통 셸 유틸 함수
- `docs/architecture.md`: 설치/복원/멱등성 아키텍처 문서
- `SETUP.md`: 실제 온보딩/설치 문서
- `config/zsh.shared.zsh`: zsh 공용 alias/history/prompt 설정
- `config/zpreztorc`: prezto 모듈 설정 (`git` 모듈 포함)
- `config/gitconfig.shared`: git 공용 alias 설정
- `setup.sh`, `cleanup.sh`, `verify.sh`: 설치/정리/멱등성 검증 진입점(래퍼)
- `scripts/setup.sh`, `scripts/cleanup.sh`, `scripts/verify.sh`: 실제 구현
- `scripts/difft-external.sh`, `scripts/difft-pager.sh`: `git dft*` wrapper 구현
- `scripts/lazygit-theme.sh`: LazyGit 테마 순환/적용 스크립트
- `config/emacs`: Emacs 설정 파일 (디렉터리 아님)
- `gemini.md`, `qwen.md`: `agents.md`로 연결된 심볼릭 링크(환경에 따라 없을 수 있음)

주의:
- `zsh/` 디렉터리는 이 레포에 없습니다.
- zprezto/zsh 운영 원칙은 `SETUP.md` 문서 기준으로 다룹니다.

## 2) 세션 시작 초기화 체크리스트 (필수)
작업 시작 시 아래 순서로 컨텍스트를 고정합니다.

1. 작업 위치/변경 상태 확인
```bash
pwd
git status --short
```

dirty 상태라면:
- 기존 변경 파일 목록을 먼저 고정해 두고(메모)
- 이번 요청 범위와 무관한 파일은 건드리지 않습니다.

2. 기준 문서/파일 읽기
```bash
sed -n '1,220p' agents.md
sed -n '1,260p' SETUP.md
```

3. 대상 파일 존재 확인
```bash
ls -la
```

4. 변경 대상별 빠른 점검
- tmux 작업이면: `config/tmux.conf.user` 우선 확인
- Helix 작업이면: `config/helix/config.toml`, `config/helix/languages.toml` 우선 확인
- 도구/버전 작업이면: `mise.toml`, `SETUP.md` 동시 확인
- shell/git alias 작업이면: `config/zsh.shared.zsh`, `config/gitconfig.shared`, `scripts/difft-*.sh`, `SETUP.md` 동시 확인
- lazygit 테마 작업이면: `config/lazygit/config.yml`, `config/lazygit/themes/*`, `scripts/lazygit-theme.sh`, `SETUP.md` 동시 확인

## 3) 변경 원칙
- 최소 변경: 요청 범위 밖 수정 금지
- 안전 우선: 사용자 워크플로우(키 바인딩, prefix, popup)를 깨지 않기
- 문서 동기화: 동작/설치/버전이 바뀌면 `SETUP.md` 같이 갱신
- 기존 변경 존중: 이미 dirty 상태인 다른 파일은 함부로 되돌리지 않기
- 검증 후 보고: "적용 + 확인 결과"까지 한 번에 제공

## 4) 영역별 실무 규칙

### 4.1 tmux (`config/tmux.conf.user`)
- 키 바인딩 변경 시 기존 충돌 여부를 먼저 확인합니다.
- popup 관련 바인딩(`h`, `g`, `y`)은 실제 도구 존재 여부와 같이 설명합니다.
- 클립보드/터미널 옵션 변경 시 호환성 옵션(버전 가드)을 유지합니다.
- 적용 후 최소 검증:
```bash
TMUX_SOCK="codexcheck-$RANDOM"
tmux -L "$TMUX_SOCK" -f "$PWD/config/tmux.conf.user" start-server \; show-options -g set-clipboard \; show-options -gqv @plugin
tmux -L "$TMUX_SOCK" kill-server >/dev/null 2>&1 || true
```

### 4.2 Helix (`config/helix/*`)
- 언어 서버/formatter 변경 시 실제 설치 경로와 도구명을 맞춥니다.
- 변경 후 최소 검증:
```bash
hx --health python
hx --health json
hx --health yaml
```

### 4.3 mise/설치 문서 (`mise.toml`, `SETUP.md`)
- 도구 추가/버전 변경 시 `mise.toml`과 `SETUP.md`를 함께 수정합니다.
- setup/cleanup/verify에서 쓰는 도구 목록은 `scripts/lib/toolset.sh`를 기준으로 유지합니다.
- 설치/복원 구조 변경 시 `docs/architecture.md`도 같이 갱신합니다.
- "latest" 사용 시 재현성 저하를 문서에 명시합니다.
- 설치/실행 명령은 복붙 가능한 형태로 유지합니다.
- 경로 원칙: 레포 절대경로 하드코딩 대신 `REPO_ROOT` + symlink(`~/.local/bin/dot-*`) 구조를 유지합니다.
- `.dmux/`, `.dmux-hooks/` 같은 실행 중 생성 디렉터리는 설정 소스가 아니므로 수정/커밋 대상으로 취급하지 않습니다.

### 4.4 Emacs (`config/emacs`)
- 현재는 단일 파일 기반 설정입니다.
- Emacs 관련 변경은 기존 스타일과 로딩 영향(성능/초기화 순서)을 고려합니다.

## 5) 완료 전 최종 점검
```bash
git status --short
git diff -- <수정한 파일>
bash -n setup.sh cleanup.sh verify.sh
bash -n scripts/setup.sh scripts/cleanup.sh scripts/verify.sh scripts/difft-external.sh scripts/difft-pager.sh scripts/lazygit-theme.sh
mise x shellcheck@latest -- shellcheck setup.sh cleanup.sh verify.sh scripts/setup.sh scripts/cleanup.sh scripts/verify.sh scripts/lib/toolset.sh scripts/lib/scriptlib.sh scripts/difft-external.sh scripts/difft-pager.sh scripts/lazygit-theme.sh
```

보고 시 포함:
- 변경 파일 목록
- 사용자 체감 동작 변화
- 실행한 검증 명령과 핵심 결과
- 남은 리스크(있다면 1~2줄)

## 6) 금지/주의 사항
- 요청 없는 파괴적 명령(`reset --hard`, 대량 삭제 등) 금지
- 근거 없는 추정으로 문서/설정 확장 금지
- 확인되지 않은 경로(`zsh/` 등) 전제로 지침 작성 금지
