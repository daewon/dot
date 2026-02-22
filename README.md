# dot

재현 가능한 터미널 개발 환경(dotfiles) bootstrap 저장소입니다.
핵심 목표는 `설치(setup)`, `정리(cleanup)`, `검증(verify)`을 스크립트로 표준화해서,
새 머신에서도 같은 작업 환경을 반복 가능하게 만드는 것입니다.

## 이 저장소가 해결하는 문제
- 새 장비/새 계정에서 셸, 에디터, tmux, git 설정을 수동으로 다시 맞추는 비용
- 사람마다 다른 설치 순서/버전으로 생기는 환경 드리프트
- 정리(cleanup) 시 사용자 개인 파일까지 건드릴 위험
- 반복 실행할수록 설정이 꼬이거나 백업 파일이 쌓이는 문제

## 어떤 일을 해서 무엇이 되는가
`setup.sh`는 아래를 수행해 작업 가능한 개발 셸 환경을 만듭니다.
- `mise` 기반 런타임/CLI/LSP 도구 설치
- `zsh` 설치 보장 + `prezto` 부트스트랩
- `config/*`를 사용자 홈 경로에 symlink로 연결
- `~/.zshrc`를 관리형 wrapper로 구성
- `git include.path`를 `config/gitconfig.shared`로 정규화
- tmux TPM 플러그인(옵션) 설치
- setup manifest(`${XDG_STATE_HOME:-$HOME/.local/state}/dot/setup-manifest.v1.tsv`) 기록

`cleanup.sh`는 아래를 수행해 setup가 만든 상태만 안전하게 정리합니다.
- manifest 우선 삭제(없으면 정적 managed target 규칙으로 fallback)
- setup가 관리한 symlink/clone/include만 제거
- 비관리 파일/예상 외 symlink는 보존

`verify.sh`는 멱등성과 재현성을 검증합니다.
- `bash -n`/`shellcheck` 정적 점검
- 계약 가드레일 스모크(잘못된 flag/manifest 계약 위반 fail-fast, version mismatch fallback)
- `setup/cleanup` dry-run 스모크 테스트
- setup-only 반복 루프(백업 증가 여부 확인)
- cleanup→setup 반복 루프(상태 수렴 확인)
- default profile에서 optional 도구 명령 존재까지 검증
- 최종 복원(옵션)

## 빠른 시작
레포 루트(예: `~/dot`)에서 실행:

```bash
./setup.sh
./verify.sh --profile full
```

정리:

```bash
./cleanup.sh
```

자주 쓰는 옵션:
- `./setup.sh --dry-run`
- `INSTALL_OPTIONAL_TOOLS=0 ./setup.sh`
- `INSTALL_TMUX_PLUGINS=0 ./setup.sh`
- `SET_DEFAULT_SHELL=1 ./setup.sh`
- `./cleanup.sh --dry-run`
- `REMOVE_GLOBAL_TOOLS=1 ./cleanup.sh`
- `./verify.sh --profile fast` (빠른 로컬 확인)
- `./verify.sh --profile stress` (강한 반복 검증)

버전 재현성:
- `mise.toml`과 `scripts/lib/toolset.sh`는 `latest` 대신 pin 버전을 사용합니다.
- 유틸 버전 변경 시 위 두 파일 + `SETUP.md`/`docs/architecture.md`를 함께 갱신하세요.

CI:
- GitHub Actions 품질 게이트: `.github/workflows/quality.yml`
  - PR/push: `actionlint` + `verify --profile fast`
  - schedule/manual: `actionlint` + `verify --profile full`

## 저장소 구조
- `config/`: zsh, prezto, git, tmux, helix, lazygit 설정 소스
- `scripts/`: setup/cleanup/verify 실제 구현 + helper 스크립트
- `scripts/lib/toolset.sh`: 공통 도구 목록 단일 소스
- `scripts/lib/scriptlib.sh`: 공통 셸 유틸 함수
- `setup.sh`, `cleanup.sh`, `verify.sh`: 루트 진입점 래퍼
- `docs/architecture.md`: 설치/정리/검증 아키텍처 상세
- `SETUP.md`: 운영 절차와 상세 커맨드 가이드

## 지원 범위
- 공식 검증 대상: Linux (Ubuntu/Debian 계열)
- macOS는 부분 지원(사전 준비 필요)이며 상세는 `SETUP.md` 참고
