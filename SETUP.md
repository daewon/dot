# 설치 가이드

## 지원 범위
- 공식 지원: Linux (Ubuntu/Debian)
- macOS: 사전 준비 후 부분 지원

## 사전 준비
- `git`, `bash`, `mise` 사용 가능 상태
- `zsh`가 없으면 `setup.sh`가 자동 설치 시도
- 저장소를 원하는 경로에 clone (경로 고정 필요 없음)

`mise`가 없다면:
```bash
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
exec "$SHELL" -l
```

## SSOT 원칙
- `dot` 저장소가 설치/도구 정책의 단일 기준입니다.
- `~/.config/mise/config.toml` 등 전역 파일은 `setup.sh` 결과로만 관리합니다(수동 편집 비권장).
- 설치 도구 정책:
  - `scripts/lib/toolset.sh`: global required/optional 도구 정책(단일 기준)
  - `mise.toml`: 로컬 오버라이드 방지용 빈 placeholder

## 1) 설치
기본 설치:
```bash
./setup.sh
```

자주 쓰는 옵션:
- `./setup.sh --dry-run`: 변경 없이 계획만 확인
- `INSTALL_OPTIONAL_TOOLS=1 ./setup.sh`: 선택 도구(Python/Scala/TypeScript/dmux + metals launcher + vim runtime) 설치 포함
- `INSTALL_OPTIONAL_TOOLS=0 ./setup.sh`: 선택 도구 설치 생략
- 인터랙티브 TTY에서 `INSTALL_OPTIONAL_TOOLS` 미지정 시: 설치 시작 전에 선택 도구 설치 여부를 프롬프트로 확인
- 비대화형 실행에서 `INSTALL_OPTIONAL_TOOLS` 미지정 시: `0`으로 처리
- `INSTALL_TMUX_PLUGINS=0 ./setup.sh`: TPM 플러그인 설치 생략
- `SET_DEFAULT_SHELL=1 ./setup.sh`: 기본 셸을 zsh로 변경 시도

설치 시 수행되는 일:
- 필수/선택 도구 설치 (`scripts/lib/toolset.sh` 기준)
- 필수(global) 도구에 Scala 런처 `coursier(cs)` 포함
- 선택 도구 설치 시 Python LSP(`pyright`), Scala 도구 체인(`java 21`, `mill` + `metals` launcher), TypeScript 도구 체인(`typescript-language-server`, `tsc`), `dmux`, Vim(`vim` binary + `~/.vim_runtime` + plugin update)를 설치
- zprezto 준비 및 관리형 `~/.zshrc` 구성
- `config/*`와 helper 스크립트 symlink 연결
- git `include.path` 정규화
- 기존 managed clone(`~/.zprezto`, `~/.tmux/plugins/tpm`)이 비정상/비관리 상태면 백업 후 재구성
- setup manifest 기록

기본값:
- 인터랙티브 TTY: 프롬프트 응답값 사용(`Enter`는 No)
- 비대화형: `INSTALL_OPTIONAL_TOOLS=0` (선택 도구 미설치)

선택 도구 구성(`INSTALL_OPTIONAL_TOOLS=1`):
- Python: global `pyright` 설치(Helix는 `.venv`의 `pyright`/`basedpyright` 우선, 없으면 global fallback)
- Scala: `java 21` + `mill` + `metals` launcher(`~/.local/bin/metals`, `coursier(cs)` 사용)
- JavaScript/TypeScript: `typescript-language-server` + `tsc`
- 기타: `dmux`
- Vim: `vim` binary + `~/.vim_runtime` clone + 관리형 `~/.vimrc` + `update_plugins.py`

## 2) 검증
빠른 검증:
```bash
./verify.sh --profile fast
```

전체 검증:
```bash
./verify.sh --profile full
```

강한 반복 검증:
```bash
./verify.sh --profile stress
```

추가 제어:
- `SETUP_ONLY_LOOPS=<n>`
- `CYCLE_LOOPS=<n>`
- `RUN_DEFAULT_SETUP=0|1`
- `./verify.sh --skip-default-setup`
- `./verify.sh --no-restore`

주의:
- `verify.sh`는 실제 `setup/cleanup` 루프를 실행하므로 홈 환경을 변경할 수 있습니다.
- 실행 로그는 `/tmp/dot-verify-*`에 남습니다.

## 3) 정리
기본 정리:
```bash
./cleanup.sh
```

옵션:
- `./cleanup.sh --dry-run`
- `REMOVE_GLOBAL_TOOLS=1 ./cleanup.sh`
- `FORCE_REMOVE_ZSHRC=1 ./cleanup.sh`

정리 원칙:
- setup가 관리한 항목만 삭제
- 비관리 일반 파일은 보존
- manifest 불일치 시 static fallback으로 안전 정리

## 4) 운영 규칙
- 도구/버전 변경: global required/optional 정책은 `scripts/lib/toolset.sh`에서 관리
- 구조 변경: `docs/architecture.md` 동시 갱신
- 최종 확인:
```bash
git status --short
./verify.sh --profile fast
```

## 5) 문제 해결
- `zsh` 없음: OS 패키지로 먼저 설치
- `chsh` 실패: 시스템 정책/권한 확인 후 재시도
- 일부 도구 미검출: `mise current`로 활성 버전 확인
