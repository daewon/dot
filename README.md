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
- 설치 도구 정책의 기준은 `scripts/lib/toolset.sh`(required/optional, global)입니다.
- `mise.toml`은 로컬 오버라이드를 만들지 않기 위한 빈 placeholder로 유지합니다.

주요 개발 도구:
- Helix LSP: Markdown(`marksman`), JSON(`vscode-json-language-server`), YAML(`yaml-language-server`)
- Scala 런처(required): `coursier(cs)`
- 선택 체인(optional): Python LSP(`pyright`), Scala(`java 21` + `mill` + `metals` launcher), TypeScript(`typescript-language-server` + `tsc`), `dmux`, Vim(`vim` binary + `~/.vim_runtime` + plugin update)

## 자주 쓰는 옵션
- `./setup.sh --dry-run`
- `INSTALL_OPTIONAL_TOOLS=1 ./setup.sh`
- `INSTALL_OPTIONAL_TOOLS=0 ./setup.sh`
- `./setup.sh` 실행 시(인터랙티브 TTY, 변수 미지정) 선택 도구 설치 여부 프롬프트 표시
- 비대화형 실행(예: CI, 파이프)에서 변수 미지정 시 `INSTALL_OPTIONAL_TOOLS=0` 기본값 적용
- `INSTALL_TMUX_PLUGINS=0 ./setup.sh`
- `SET_DEFAULT_SHELL=1 ./setup.sh`
- `./cleanup.sh --dry-run`
- `REMOVE_GLOBAL_TOOLS=1 ./cleanup.sh`
- `./verify.sh --profile full|stress`

추가 참고:
- `tmux`는 `mise`의 prebuilt backend(`github:tmux/tmux-builds`)로 설치합니다(소스 빌드 의존성 최소화).
- ARM 지원: `tmux-builds`는 `linux-arm64`, `macos-arm64` 아티팩트를 제공합니다.

## 저장소 구조
- `config/`: zsh, tmux, helix, lazygit, git 설정
- `scripts/`: 실제 setup/cleanup/verify 구현
- `scripts/lib/toolset.sh`: 설치 도구 목록 단일 소스
- `scripts/lib/scriptlib.sh`: 공통 셸 유틸
- `mise.toml`: 로컬 오버라이드 방지용 placeholder(툴 선언 없음)

## 운영 원칙
- 도구 버전은 가능하면 pin(고정)하여 재현성을 유지합니다.
- 동작이 바뀌면 문서(`README.md`, `SETUP.md`, `docs/architecture.md`)를 함께 갱신합니다.

## 추가 문서
- `SETUP.md`: 설치/복구 절차
- `docs/architecture.md`: 설계와 계약 요약
- `agents.md`: 에이전트 작업 규칙
