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

상세 설치/복구/문제해결은 `SETUP.md`를 기준으로 확인하세요.

## 플랫폼/패키지 관리자 기준
- Linux(Ubuntu/Debian): `apt-get`
- macOS: `Homebrew` (기본/권장 패키지 관리자)

macOS에서 `brew`가 없다면:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
brew --version
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
- 공통 클립보드 유틸(required): `sclip` (`stdin -> 시스템 클립보드`, 내부 backend: macOS `pbcopy`, WSL `clip.exe`, Linux `wl-copy|xclip|xsel`)
- 선택 체인(optional): Python LSP(`pyright`), Scala(`java 21` + `mill` + `metals` launcher), TypeScript(`typescript-language-server` + `tsc`), `dmux`, `codex`, Vim(`vim` binary + `~/.vim_runtime` + plugin update)
- zsh 기본 정책: `HISTSIZE/SAVEHIST=1000000`, 즉시 append + 세션 간 공유 + 중복 축소
- Prezto 모듈: `completion`, `command-not-found`, `git`, `history-substring-search`, `autosuggestions`, `syntax-highlighting` 포함
- GitHub/Gist credential helper는 `config/gitconfig.shared`에서 `!$HOME/.local/share/mise/shims/gh auth git-credential`로 관리(글로벌 `~/.gitconfig` host override 금지)

## 자주 쓰는 옵션
- `./setup.sh --dry-run`
- `INSTALL_OPTIONAL_TOOLS=1 ./setup.sh`
- `INSTALL_OPTIONAL_TOOLS=0 ./setup.sh`
- `./setup.sh` 실행 시(인터랙티브 TTY, 변수 미지정) 선택 도구 설치 여부 프롬프트 표시
- 비대화형 실행(예: CI, 파이프)에서 변수 미지정 시 `INSTALL_OPTIONAL_TOOLS=0` 기본값 적용
- `INSTALL_TMUX_PLUGINS=0 ./setup.sh`
- `SET_DEFAULT_SHELL=1 ./setup.sh`
- `SET_DEFAULT_SHELL=0 ./setup.sh`
- 인터랙티브 TTY에서 `SET_DEFAULT_SHELL` 미지정 시 zsh 전환 여부를 프롬프트로 확인(`[Y/n]`, 기본 Yes)
- 비대화형 실행에서 `SET_DEFAULT_SHELL` 미지정 시 기본값 `0`(전환 생략)
- `./cleanup.sh --dry-run`
- `REMOVE_GLOBAL_TOOLS=1 ./cleanup.sh`
- `./cleanup.sh` 실행 시(인터랙티브 TTY, 변수 미지정) global tool 엔트리 제거 여부 프롬프트 표시
- 비대화형 실행에서 `REMOVE_GLOBAL_TOOLS` 미지정 시 `0` 기본값 적용
- `./verify.sh --profile full|stress`

옵션 한눈에 보기:

| 변수 | 스크립트 | 값 | 인터랙티브 미지정 | 비대화형 미지정 |
| --- | --- | --- | --- | --- |
| `INSTALL_OPTIONAL_TOOLS` | `setup.sh` | `0/1` | 프롬프트 `[y/N]` | `0` |
| `SET_DEFAULT_SHELL` | `setup.sh` | `0/1` | 프롬프트 `[Y/n]` | `0` |
| `INSTALL_TMUX_PLUGINS` | `setup.sh` | `0/1` | `1` | `1` |
| `REMOVE_GLOBAL_TOOLS` | `cleanup.sh` | `0/1` | 프롬프트 `[y/N]` | `0` |
| `FORCE_REMOVE_ZSHRC` | `cleanup.sh` | `0/1` | `0` | `0` |

추가 참고:
- `tmux`는 `scripts/lib/toolset.sh`에 정의된 backend로 설치하고, 설치 후 `tmux -V` health check가 실패하면 prebuilt/source backend 간 자동 fallback을 시도합니다.
- `tmux` copy-command는 `sclip`을 우선 사용하고, 없으면 OS별 backend로 fallback합니다.
- 직접 사용 예시: `printf 'hello' | sclip`
- 선택 도구에서 `metals` 설치 시 native `cs`가 CPU 미지원으로 실패하면 JVM launcher(`coursier` script)로 자동 fallback합니다.
- 클립보드 런타임 검증이 필요하면: `VERIFY_CLIPBOARD_RUNTIME=1 ./verify.sh --profile fast`

## 저장소 구조
- `config/`: zsh, tmux, helix, lazygit, git 설정
- `scripts/`: 실제 setup/cleanup/verify 구현
- `scripts/lib/toolset.sh`: 설치 도구 목록 단일 소스
- `scripts/lib/scriptlib.sh`: 공통 셸 유틸
- `mise.toml`: 로컬 오버라이드 방지용 placeholder(툴 선언 없음)

## 운영 원칙
- 도구 버전은 가능하면 pin(고정)하여 재현성을 유지합니다(예외: optional `codex`는 최신 빌드 추종).
- 동작이 바뀌면 문서(`README.md`, `SETUP.md`, `docs/architecture.md`)를 함께 갱신합니다.

## 추가 문서
- `SETUP.md`: 설치/복구 절차
- `docs/architecture.md`: 설계와 계약 요약
- `agents.md`: 에이전트 작업 규칙
