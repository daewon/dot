# dot

재현 가능한 개발 터미널 환경을 빠르게 구성하는 dotfiles 저장소입니다.
핵심은 `setup`, `cleanup`, `verify` 3개 스크립트로 설치/정리/검증을 표준화하는 것입니다.

## 빠른 시작
```bash
./setup.sh
./verify.sh --profile fast
```

주의:
- `verify.sh`는 실제 `setup/cleanup` 루프를 실행합니다.

정리:
```bash
./cleanup.sh
```

## 주요 스크립트
- `setup.sh`: 도구 설치, 설정 symlink 연결, 초기 상태 구성
- `cleanup.sh`: setup가 관리한 항목만 안전하게 제거
- `verify.sh`: 멱등성/재현성 검증

## SSOT 원칙
- 이 저장소(`dot`)가 단일 기준(Single Source of Truth)입니다.
- 시스템 전역 설정(`~/.config/mise/config.toml` 등)은 `setup.sh` 실행 결과로만 파생되어야 하며 수동 편집을 권장하지 않습니다.
- 설치 정책의 기준은 `scripts/lib/toolset.sh`(required/optional), 로컬 기본 툴체인은 `mise.toml`입니다.

주요 개발 도구:
- Helix LSP: Markdown(`marksman`), JSON(`vscode-json-language-server`), YAML(`yaml-language-server`)
- Python/Scala 체인(선택 설치): Python(`uv 로컬 .venv 우선 + global pyright fallback`), Scala(`java 21` + `mill` + `coursier(cs)` + `metals`)

## 자주 쓰는 옵션
- `./setup.sh --dry-run`
- `INSTALL_OPTIONAL_TOOLS=1 ./setup.sh`
- `INSTALL_OPTIONAL_TOOLS=0` (default)
- `INSTALL_TMUX_PLUGINS=0 ./setup.sh`
- `SET_DEFAULT_SHELL=1 ./setup.sh`
- `./cleanup.sh --dry-run`
- `REMOVE_GLOBAL_TOOLS=1 ./cleanup.sh`
- `./verify.sh --profile full|stress`

## 저장소 구조
- `config/`: zsh, tmux, helix, lazygit, git 설정
- `scripts/`: 실제 setup/cleanup/verify 구현
- `scripts/lib/toolset.sh`: 설치 도구 목록 단일 소스
- `scripts/lib/scriptlib.sh`: 공통 셸 유틸
- `mise.toml`: 버전 고정 도구 선언

## 운영 원칙
- 도구 버전은 가능하면 pin(고정)하여 재현성을 유지합니다.
- 동작이 바뀌면 문서(`README.md`, `SETUP.md`, `docs/architecture.md`)를 함께 갱신합니다.

## 추가 문서
- `SETUP.md`: 설치/복구 절차
- `docs/architecture.md`: 설계와 계약 요약
- `agents.md`: 에이전트 작업 규칙
