# 설치 가이드

## 지원 범위
- 공식 지원: Linux (Ubuntu/Debian)
- macOS: 사전 준비 후 부분 지원

## 사전 준비
- `git`, `bash`, `mise` 사용 가능 상태
- `zsh`가 없으면 `setup.sh`가 자동 설치 시도
- 저장소를 원하는 경로에 clone (경로 고정 필요 없음)
- macOS는 `Homebrew`를 기본 패키지 관리자로 사용

`mise`가 없다면:
```bash
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
exec "$SHELL" -l
```

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

## SSOT 원칙
- `dot` 저장소가 설치/도구 정책의 단일 기준입니다.
- `~/.config/mise/config.toml` 등 전역 파일은 `setup.sh` 결과로만 관리합니다(수동 편집 비권장).
- 실제 `mise` 설치 상태는 `~/.config/mise`, `~/.local/share/mise`, `~/.local/state/mise`, `~/.cache/mise` 같은 사용자 전역 경로에 기록됩니다.
- 설치 도구 정책:
  - `scripts/lib/toolset.sh`: global required/optional 도구 정책(단일 기준)
  - repo root에는 project-local `mise` 파일(`mise.toml`, `.mise.toml`, `.tool-versions`)을 두지 않음

## 설치 그룹 정책
- `mise-managed global toolchain`
  - 기본 방향은 `mise-first`입니다.
  - required/optional global CLI/runtime는 `scripts/lib/toolset.sh`를 기준으로 `mise use -g`로 수렴시킵니다.
- `system integration packages`
  - `zsh`, `vim`, Linux clipboard backend, tmux source-build prerequisites는 OS 패키지 관리자를 사용합니다.
  - setup는 필요 시 설치만 수행하며, system-wide upgrade는 기본 동작에 포함하지 않습니다.
- `repo-managed wrappers`
  - `sclip`, `dot-difft`, `dot-difft-pager`, `dot-lazygit-theme`는 저장소 스크립트를 `~/.local/bin`에 symlink로 배포합니다.
  - tmux/git/zsh 같은 1st-party 설정은 이 래퍼를 우선 사용합니다.
- `managed git assets`
  - `~/.zprezto`, `~/.tmux/plugins/tpm`, optional `~/.vim_runtime`는 git clone 자산으로 관리합니다.
- `non-mise app wrappers`
  - Scala 예외 정책: `java`/`coursier`는 `mise`, `metals`는 `coursier`, `mill`은 bootstrap script direct download를 사용합니다.
  - fallback JVM `coursier` launcher는 native `cs`가 실패할 때만 보조 경로로 사용합니다.
- `update policy`
  - 기본 `setup.sh`는 missing install + declared-state convergence에 집중합니다.
  - `UPDATE_PACKAGES=1` 또는 `./setup.sh --update-packages`는 managed clone refresh와 non-mise app wrapper refresh를 추가로 수행합니다.

## 옵션 빠른 참조
| 변수 | 스크립트 | 값 | 인터랙티브 미지정 | 비대화형 미지정 |
| --- | --- | --- | --- | --- |
| `INSTALL_OPTIONAL_TOOLS` | `setup.sh` | `0/1` | 프롬프트 `[y/N]` | `0` |
| `SET_DEFAULT_SHELL` | `setup.sh` | `0/1` | 프롬프트 `[Y/n]` | `0` |
| `INSTALL_TMUX_PLUGINS` | `setup.sh` | `0/1` | `1` | `1` |
| `UPDATE_PACKAGES` | `setup.sh` | `0/1` | `0` | `0` |
| `REMOVE_GLOBAL_TOOLS` | `cleanup.sh` | `0/1` | 프롬프트 `[y/N]` | `0` |
| `FORCE_REMOVE_ZSHRC` | `cleanup.sh` | `0/1` | `0` | `0` |

## 1) 설치
기본 설치:
```bash
./setup.sh
```

자주 쓰는 옵션:
- `./setup.sh --dry-run`: 변경 없이 계획만 확인
- `./setup.sh --update-packages`: update-capable 자산 refresh
- `INSTALL_OPTIONAL_TOOLS=1 ./setup.sh`: 선택 도구(Python/Scala/TypeScript/Rust/codex + metals launcher + vim runtime) 설치 포함
- `INSTALL_OPTIONAL_TOOLS=0 ./setup.sh`: 선택 도구 설치 생략
- `UPDATE_PACKAGES=1 ./setup.sh`: managed clone/non-mise app wrapper refresh
- `UPDATE_PACKAGES=1 INSTALL_OPTIONAL_TOOLS=1 ./setup.sh`: optional 체인까지 포함해 refresh
- 인터랙티브 TTY에서 `INSTALL_OPTIONAL_TOOLS` 미지정 시: 설치 시작 전에 선택 도구 설치 여부를 프롬프트로 확인
- 비대화형 실행에서 `INSTALL_OPTIONAL_TOOLS` 미지정 시: `0`으로 처리
- `INSTALL_TMUX_PLUGINS=0 ./setup.sh`: TPM 플러그인 설치 생략
- `SET_DEFAULT_SHELL=1 ./setup.sh`: 기본 셸을 zsh로 변경 시도
- `SET_DEFAULT_SHELL=0 ./setup.sh`: 기본 셸 변경 생략

설치 시 수행되는 일:
- 필수/선택 도구 설치 (`scripts/lib/toolset.sh` 기준)
- `tmux` 설치 후 `tmux -V` health check를 수행하고, 실패 시 prebuilt/source backend 간 자동 fallback 시도
- 공통 클립보드 유틸 `sclip`을 설치(관리형 symlink)하고, 환경별 backend(`pbcopy`/`clip.exe`/`wl-copy|xclip|xsel`)를 필수 검증( Linux 누락 시 OS 패키지 설치 시도)
- 필수(global) 도구에 Scala 런처 `coursier(cs)` 포함
- 선택 도구 설치 시 Python LSP(`pyright`), Scala 도구 체인(`java 21`, `metals` launcher via `coursier`, `mill` bootstrap via direct download), TypeScript 도구 체인(`typescript-language-server`, `tsc`), Rust 도구 체인(`rustc`, `cargo`, `rustfmt`, `rust-analyzer`, `rust-src`), `codex`, Vim(`vim` binary + `~/.vim_runtime` + plugin update)를 설치
- zprezto 준비 및 관리형 `~/.zshrc` 구성
- zsh 공유 정책 적용: `HISTSIZE/SAVEHIST=1000000`, 즉시 append, 세션 간 history 공유, 중복 축소
- Prezto 모듈(`completion`, `command-not-found`, `git`, `history-substring-search`, `autosuggestions`, `syntax-highlighting`) 활성
- `config/*`와 helper 스크립트 symlink 연결(`sclip`, `dot-difft`, `dot-difft-pager`, `dot-lazygit-theme` 포함)
- git `include.path` 정규화
- GitHub/Gist credential helper를 `config/gitconfig.shared`의 `!$HOME/.local/share/mise/shims/gh auth git-credential`로 고정하고 `~/.gitconfig` host override를 자동 정리
- 기존 managed clone(`~/.zprezto`, `~/.tmux/plugins/tpm`)이 비정상/비관리 상태면 백업 후 재구성
- `UPDATE_PACKAGES=1`이면 managed clone을 `git pull --ff-only`로 새로고침하고 optional Scala app wrapper(`metals`, `mill`)도 refresh
- setup manifest 기록

기본값:
- 인터랙티브 TTY: 프롬프트 응답값 사용(`Enter`는 No)
- 비대화형: `INSTALL_OPTIONAL_TOOLS=0` (선택 도구 미설치)
- 인터랙티브 TTY에서 `SET_DEFAULT_SHELL` 미지정: zsh 전환 여부를 프롬프트로 확인(`[Y/n]`, `Enter`는 Yes)
- 비대화형에서 `SET_DEFAULT_SHELL` 미지정: `0` (기본 셸 전환 생략)

선택 도구 구성(`INSTALL_OPTIONAL_TOOLS=1`):
- Python: global `pyright` 설치(Helix는 `.venv`의 `pyright`/`basedpyright` 우선, 없으면 global fallback)
- Scala: `java 21` + `metals` launcher(`~/.local/bin/metals`, `coursier(cs)` 사용, native `cs` 실패 시 JVM launcher fallback) + `mill` bootstrap script(`~/.local/bin/mill`)
- JavaScript/TypeScript: `typescript-language-server` + `tsc`
- Rust: `rustc` + `cargo` + `rustfmt` + `rust-analyzer` + `rust-src` (`mise`의 `rust` toolchain 옵션 사용)
- 기타: `codex`
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
- `VERIFY_CLIPBOARD_RUNTIME=1` (선택: `sclip` 기반 클립보드 런타임 검증까지 수행)
- `./verify.sh --skip-default-setup`
- `./verify.sh --no-restore`
- `verify.sh`는 repo root에 local `mise` 파일이 생기면 실패합니다(`mise.toml`, `.mise.toml`, `.tool-versions`).

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
- `./cleanup.sh` 실행 시(인터랙티브 TTY, `REMOVE_GLOBAL_TOOLS` 미지정): global tool 엔트리 제거 여부를 프롬프트로 확인(`[y/N]`, 기본 No)
- 비대화형 실행에서 `REMOVE_GLOBAL_TOOLS` 미지정 시: `0`으로 처리

정리 원칙:
- setup가 관리한 항목만 삭제
- 비관리 일반 파일은 보존
- manifest 불일치 시 static fallback으로 안전 정리

## 4) 운영 규칙
- 도구/버전 변경: global required/optional 정책은 `scripts/lib/toolset.sh`에서 관리
- optional `codex`는 최신 빌드 추종을 위해 unpinned로 관리
- 구조 변경: `docs/architecture.md` 동시 갱신
- 최종 확인:
```bash
git status --short
./verify.sh --profile fast
```

## 5) 문제 해결
- `zsh` 없음: OS 패키지로 먼저 설치
- 비대화형 환경(CI 등)에서 `zsh`/`vim` 자동 설치가 필요한 경우:
  - `setup.sh`는 `sudo -n apt-get ...`(passwordless sudo)로 설치를 시도합니다.
  - passwordless sudo가 불가하면 사전에 `zsh`/`vim`을 설치하거나 인터랙티브 셸에서 실행하세요.
- `chsh` 실패: 시스템 정책/권한 확인 후 재시도
- 일부 도구 미검출: `mise current`로 활성 버전 확인
- `tmux`가 설치됐지만 실행(`tmux -V`)이 CPU feature 부족으로 실패하는 경우:
  - `setup.sh`는 자동으로 반대 backend(prebuilt <-> source)로 1회 fallback을 시도합니다.
  - 수동 전환이 필요하면 아래를 실행하세요.
    ```bash
    mise use -g --remove github:tmux/tmux-builds
    mise use -g asdf:tmux@3.6a
    ```
- `mise` 설치 중 `Permission denied (os error 13)`:
  - 권한 점검: `ls -ld ~/.config/mise ~/.local/share/mise ~/.local/state/mise ~/.cache/mise`
  - root 소유면 소유권 복구:
    ```bash
    sudo chown -R "$USER:$(id -gn)" \
      ~/.config/mise \
      ~/.local/share/mise \
      ~/.local/state/mise \
      ~/.cache/mise
    ```
