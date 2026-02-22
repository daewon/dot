# Dotfiles Setup (zprezto + zsh + mise)

## 지원 범위
- 공식 검증/지원 대상: Linux (Ubuntu/Debian 계열)
- 이 문서 기준 최신 검증일: 2026-02-21
- macOS는 아직 실검증 대상이 아니며, 아래 사전 준비가 필요합니다.
  - Homebrew 설치 (`brew` 사용 가능 상태)
  - `git`, `mise`, `zsh` 사전 설치
  - 기본 셸 변경 시 `chsh` 권한/정책 확인
  - Homebrew `zsh` 사용 시 필요하면 `/etc/shells` 등록 후 `chsh` 적용

## 빠른 시작 (권장 순서)
저장소 루트(`/path/to/dot`, 보통 `~/dot`)에서 아래 순서대로 실행하면 기본 환경이 올라옵니다.
`setup.sh`는 실행 위치를 `REPO_ROOT`로 계산하므로 경로를 하드코딩하지 않습니다.

원클릭 실행(단계별 진행 로그 출력):
```bash
./setup.sh
```

옵션:
- `./setup.sh --dry-run`: 실제 변경 없이 실행 계획/체크
- `INSTALL_OPTIONAL_TOOLS=0 ./setup.sh`: 선택 도구(markdown/ts/yazi/dmux/difftastic) 스킵
- `INSTALL_TMUX_PLUGINS=0 ./setup.sh`: TPM 플러그인 설치 스킵
- `SET_DEFAULT_SHELL=1 ./setup.sh`: 마지막에 기본 셸 zsh 전환 시도

도구 목록 단일 소스:
- `toolset.sh`의 배열(`DOT_REQUIRED_MISE_TOOLS`, `DOT_OPTIONAL_MISE_TOOLS`, `DOT_REQUIRED_CLI_COMMANDS`)
- `setup.sh`/`cleanup.sh`/`verify.sh`는 위 배열을 공통으로 참조
- 공통 셸 유틸(`dot_require_cmd`, `dot_resolve_path`, `dot_is_link_target`)은 `scriptlib.sh`에서 공유
- 아키텍처 상세: `docs/architecture.md`

정리(삭제) 실행:
```bash
./cleanup.sh
```

정리 옵션:
- `./cleanup.sh --dry-run`: 실제 변경 없이 삭제 계획/체크
- `REMOVE_GLOBAL_TOOLS=1 ./cleanup.sh`: setup가 추가한 global mise 도구 엔트리 제거 (기본값은 유지=0)
- `FORCE_REMOVE_ZSHRC=1 ./cleanup.sh`: setup 관리 파일이 아니어도 `~/.zshrc` 강제 삭제
- 기본 동작은 setup가 만든 symlink/clone만 정리하고, 비관리 파일은 경고 후 유지

멱등성 검증(권장):
```bash
./verify.sh
```

검증 옵션:
- `SETUP_ONLY_LOOPS=5 ./verify.sh`: 최소 프로파일 setup 반복 횟수 조정
- `CYCLE_LOOPS=5 ./verify.sh`: cleanup→setup 사이클 반복 횟수 조정
- `RUN_DEFAULT_SETUP=0 ./verify.sh`: 기본 프로파일 setup 검증 스킵

수동 실행:
```bash
# 참고: 아래는 이해를 위한 수동 예시입니다.
# 완전한 멱등성(관리 대상 판별, include 중복 정규화, 백업 최소화)은 setup.sh 기준입니다.

# 1) toolchain 설치
mise trust
mise install

# 2) CLI/Helix/LSP/formatter 도구 설치 (mise, global)
# uv는 1)에서 mise.toml 기준으로 설치됨
mise use -g fzf@latest rg@latest fd@latest bat@latest jq@latest yq@latest shellcheck@latest black@latest ruff@latest \
  npm:pyright@latest npm:vscode-langservers-extracted@latest \
  npm:yaml-language-server@latest npm:prettier@latest

# 3) (선택) Markdown/TypeScript/yazi/dmux/difftastic
mise use -g marksman@latest yazi@latest difftastic@latest \
  npm:typescript-language-server@latest npm:typescript@latest npm:dmux@latest

# 4) zsh + zprezto 준비 (최초 1회)
# zsh는 mise registry 대상이 아니라 OS 패키지로 설치
if ! command -v zsh >/dev/null 2>&1; then
  if command -v apt >/dev/null 2>&1; then
    sudo apt install -y zsh
  elif command -v brew >/dev/null 2>&1; then
    brew install zsh
  else
    echo "install zsh manually" >&2
    exit 1
  fi
fi
[ -d "$HOME/.zprezto" ] || git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"

# prezto runcom 연결 (zshrc는 아래에서 wrapper로 직접 생성)
for rc in zlogin zlogout zprofile zshenv zpreztorc; do
  if [ -e "$HOME/.$rc" ] || [ -L "$HOME/.$rc" ]; then
    mv "$HOME/.$rc" "$HOME/.$rc.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  ln -sfn "$HOME/.zprezto/runcoms/$rc" "$HOME/.$rc"
done

# ~/.zshrc: prezto + dot shared 모두 로드
if [ -e "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
fi
cat > "$HOME/.zshrc" <<'EOF'
# dot-setup managed zshrc (safe for cleanup.sh)
[ -s "$HOME/.zprezto/init.zsh" ] && source "$HOME/.zprezto/init.zsh"
[ -f "$HOME/.zsh.shared.zsh" ] && source "$HOME/.zsh.shared.zsh"
EOF

# 5) dotfiles 연결
REPO_ROOT="$(pwd)"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"
for p in "$HOME/.config/helix" "$HOME/.config/lazygit" "$HOME/.tmux.conf" "$HOME/.zsh.shared.zsh"; do
  if [ -e "$p" ] || [ -L "$p" ]; then
    mv "$p" "$p.bak.$(date +%Y%m%d-%H%M%S)"
  fi
done
ln -sfn "$REPO_ROOT/helix" "$HOME/.config/helix"
ln -sfn "$REPO_ROOT/lazygit" "$HOME/.config/lazygit"
ln -sfn "$REPO_ROOT/tmux.conf.user" "$HOME/.tmux.conf"
ln -sfn "$REPO_ROOT/zsh.shared.zsh" "$HOME/.zsh.shared.zsh"
ln -sfn "$REPO_ROOT/difft-external.sh" "$HOME/.local/bin/dot-difft"
ln -sfn "$REPO_ROOT/difft-pager.sh" "$HOME/.local/bin/dot-difft-pager"
ln -sfn "$REPO_ROOT/lazygit-theme.sh" "$HOME/.local/bin/dot-lazygit-theme"

# 6) git 공용 설정 연결
INCLUDE_COUNT="$(git config --global --get-all include.path | grep -Fx "$REPO_ROOT/gitconfig.shared" | wc -l | tr -d '[:space:]')"
if [ "${INCLUDE_COUNT:-0}" = "0" ]; then
  git config --global --add include.path "$REPO_ROOT/gitconfig.shared"
elif [ "${INCLUDE_COUNT:-0}" != "1" ]; then
  git config --global --unset-all include.path "$REPO_ROOT/gitconfig.shared"
  git config --global --add include.path "$REPO_ROOT/gitconfig.shared"
fi

# 7) 기본 셸 전환 (원하면)
# PAM 정책에 따라 비밀번호 입력이 필요할 수 있음
chsh -s "$(command -v zsh)" "$USER"
```

적용 확인:
```bash
mise current
hx --health python
hx --health json
hx --health yaml
```

## 왜 이 구성이 실용적인가
- `mise`: 프로젝트 기준 버전 고정(사람마다 다른 로컬 버전 문제 최소화)
- `uv`: Python 도구 설치/실행 속도 빠르고, 전역 환경 오염이 적음
- `zprezto + zsh`: 셸 시작 파일 역할 분리로 충돌 감소
- `fzf`: 파일/히스토리 탐색 속도 개선 (zsh에서 키바인딩 자동 로드)
- `tmux + dmux`: 장시간 작업, 세션 복구, 멀티 repo 작업에 유리
- `tmux popup + lazygit`: 현재 작업 경로에서 Git 작업을 빠르게 처리 가능

## 1) 런타임 설치 (mise)
```bash
mise trust
mise install
mise current
```

`mise.toml`에 정의된 버전(`node`, `python`, `helix`, `tmux`, `lazygit`, `uv`, `fzf`, `rg`, `fd`, `bat`, `jq`, `yq`, `shellcheck`)이 활성화되면 정상입니다.

## 2) zprezto + zsh 시작 파일 원칙
전제:
- zprezto는 zsh 설정 프레임워크이며, `zsh` 바이너리 자체를 설치하지 않습니다.
- `zsh`는 OS 패키지로 설치합니다.
  - Ubuntu/Debian: `sudo apt install -y zsh`
  - macOS(Homebrew): `brew install zsh`
- zsh 설치 후 zprezto를 설치합니다.
  - `git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto`
- runcom은 `zlogin zlogout zprofile zshenv zpreztorc`를 symlink로 연결하고,
  `~/.zshrc`는 아래 wrapper 형태로 두는 것을 권장합니다.

zprezto 환경에서 가장 흔한 문제는 초기화 중복입니다. 아래처럼 역할을 고정하면 안정적입니다.

- `~/.zshenv`: 최소 설정만 (`ZDOTDIR` 정도)
- `~/.zprofile`: 로그인 셸 전용 설정만
- `~/.zshrc`: interactive 설정 전담 (`$HOME/.zsh.shared.zsh` source 권장)

`~/.zshrc` 예시:
```bash
[ -s "$HOME/.zprezto/init.zsh" ] && source "$HOME/.zprezto/init.zsh"
if [ -f "$HOME/.zsh.shared.zsh" ]; then
  source "$HOME/.zsh.shared.zsh"
fi
```

`zsh.shared.zsh` 포함 내용:
- 대용량 history(`HISTSIZE`, `SAVEHIST`) + 즉시 저장/공유 옵션
- 자주 쓰는 alias(`lg`, `ta`, `fd`, git 관련)
- `prompt skwp` 기본 적용
- `mise activate zsh --quiet` 및 PATH 초기화
- `fzf --zsh` 자동 로드(설치 시)
- `~/.zsh.local` 자동 로드(개인/민감값 분리)

주의:
- `mise activate zsh --quiet`를 `~/.zshenv`/`~/.zprofile`에 중복 선언하지 않기
- `PATH`는 한 파일(`~/.zshrc`)에서 관리해 순서 꼬임 방지
- `~/.zsh.local`은 개인 파일로 관리하고 이 저장소에는 커밋하지 않기

### Git alias 공유
`git co`, `git l` 같은 alias를 환경 간 동일하게 쓰려면:
```bash
REPO_ROOT="$(pwd)"
git config --global --get-all include.path | grep -Fx "$REPO_ROOT/gitconfig.shared" >/dev/null \
  || git config --global --add include.path "$REPO_ROOT/gitconfig.shared"
```

## 3) Helix 도구 설치 (mise 기준)
필수(CLI/Python/JSON/YAML):
```bash
mise use -g fzf@latest rg@latest fd@latest bat@latest jq@latest yq@latest shellcheck@latest black@latest ruff@latest \
  npm:pyright@latest npm:vscode-langservers-extracted@latest \
  npm:yaml-language-server@latest npm:prettier@latest
```

선택(Markdown/TypeScript):
```bash
mise use -g marksman@latest \
  npm:typescript-language-server@latest npm:typescript@latest
```

선택(tmux popup 확장 + 구조 diff):
```bash
mise use -g yazi@latest difftastic@latest npm:dmux@latest
```

## 4) tmux / dmux 운영 가이드
`tmux.conf.user`에는 아래 실사용 설정이 포함되어 있습니다.

- `set -g set-clipboard on`: tmux copy 결과를 시스템 클립보드와 연동
- `allow-passthrough on`(지원 버전만): OSC52 전달로 SSH/원격 환경 복사 성공률 개선
- TPM 최소 플러그인:
  - `tmux-plugins/tmux-sensible`
  - `tmux-plugins/tmux-yank`
  - `tmux-plugins/tmux-resurrect`
  - `tmux-plugins/tmux-continuum`
- `setup.sh` 기본값(`INSTALL_TMUX_PLUGINS=1`)에서는 TPM 플러그인까지 자동 설치됨
- 자동 설치를 끄면(`INSTALL_TMUX_PLUGINS=0`) 아래 수동 설치 절차 사용
- 팝업 단축키:
  - `prefix + h`: Helix 팝업
  - `prefix + g`: lazygit 팝업
  - `prefix + y`: yazi 팝업

TPM 최초 1회:
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source-file ~/.tmux.conf
```

tmux 안에서 플러그인 설치:
- `prefix + I` (`C-] I`)

dmux 설치:
```bash
mise use -g npm:dmux@latest
```

difftastic 설치:
```bash
mise use -g difftastic@latest
```

git에서 구조 diff 사용:
```bash
git dft            # working tree
git dftc           # staged changes
git dfts HEAD~1    # commit patch
git dftw           # wrap 모드(긴 줄 줄바꿈)
```
구조 diff는 아래 wrapper를 통해 실행됩니다.
- `dot-difft` -> `difft-external.sh`
- `dot-difft-pager` -> `difft-pager.sh`
- wrapper는 setup 시 `~/.local/bin`에 symlink로 배치됩니다.
- `difft`가 PATH에 없어도 `mise which difft` fallback으로 실행되도록 구성되어 있습니다.

dmux 실행 모드 정리:
- 가장 안전: `tmux 밖`에서 `dmux` 실행
  - dmux가 프로젝트별 `dmux-*` 세션을 자동 생성/attach
- `tmux new -s <session>`로 먼저 들어간 뒤 `dmux` 실행도 가능
  - 이 경우 `새 dmux 세션`을 만들지 않고 `현재 tmux 세션`에서 동작
- 주의: 기존 non-dmux tmux 세션 안에서 실행하면 현재 레이아웃/워크플로우와 충돌 가능
- 권장: 같은 프로젝트에서 dmux를 동시에 여러 인스턴스로 실행하지 않기 (`.dmux` 상태 파일 공유)

여러 tmux 세션 + 프로젝트별 dmux 운영 예시:
```bash
tmux new -s proj-a
cd ~/repo-a && dmux
# detach: Ctrl+b d

tmux new -s proj-b
cd ~/repo-b && dmux
```

## 5) 설정 파일 위치
- Helix 언어 설정: `helix/languages.toml`
- Helix 에디터 설정: `helix/config.toml`
- LazyGit 설정: `lazygit/config.yml`
- LazyGit 테마 관리 스크립트: `lazygit-theme.sh` (`dot-lazygit-theme`로 실행)
- tmux 설정: `tmux.conf.user`
- mise 버전 정의: `mise.toml`
- 공용 도구 목록: `toolset.sh`
- zsh 공용 설정: `zsh.shared.zsh`
- git 공용 alias: `gitconfig.shared`
- difftastic wrapper: `difft-external.sh`, `difft-pager.sh`
- 아키텍처 문서: `docs/architecture.md`

## 6) 검증 체크리스트
- `mise current`에 필요한 버전이 정확히 표시됨
- `command -v` 결과에 아래 바이너리가 보임:
  - `zsh`
  - `pyright-langserver`
  - `vscode-json-language-server`
  - `yaml-language-server`
  - `black`
  - `ruff`
- `prettier`
- `lazygit`
- `uv`
- `fzf`
- `rg`
- `fd`
- `bat`
- `jq`
- `yq`
- `shellcheck`
- (선택) Markdown/TypeScript 사용 시:
  - `marksman`
  - `typescript-language-server`
- `yazi` (팝업 단축키 `prefix + y` 사용 시)
- `dmux` (dmux 워크플로우 사용 시)
- `difft` (`git dft` alias 사용 시)
- `~/.config/helix`가 이 저장소의 `helix`를 가리킴
  - `readlink -f ~/.config/helix`
- `~/.config/lazygit`가 이 저장소의 `lazygit`를 가리킴
  - `readlink -f ~/.config/lazygit`
- `~/.local/bin/dot-difft`가 이 저장소의 `difft-external.sh`를 가리킴
  - `readlink -f ~/.local/bin/dot-difft`
- `~/.local/bin/dot-difft-pager`가 이 저장소의 `difft-pager.sh`를 가리킴
  - `readlink -f ~/.local/bin/dot-difft-pager`
- `~/.local/bin/dot-lazygit-theme`가 이 저장소의 `lazygit-theme.sh`를 가리킴
  - `readlink -f ~/.local/bin/dot-lazygit-theme`
- setup manifest 파일이 생성됨
  - `${XDG_STATE_HOME:-$HOME/.local/state}/dot/setup-manifest.v1.tsv`
- `tmux show -g set-clipboard` 결과가 `on`
- `git co` / `git l`가 정상 동작

## 7) 트러블슈팅
- `command not found`:
  - 새 셸을 열거나 `exec zsh`
  - `~/.zshrc`에서 `source "$HOME/.zsh.shared.zsh"` 로드 확인
- `mise current`에 `python ... (missing)` 표시:
  - `mise install` 재실행
  - `mise current`로 누락 해소 확인
- `mise use -g ...` 후 바이너리가 안 보임:
  - 새 셸 실행 후 `command -v <binary>` 재확인
  - `mise current`/`mise doctor`로 활성화 상태 점검
- zprezto 설치 후 설정이 적용되지 않음:
  - 로그인 셸 확인: `getent passwd "$USER" | cut -d: -f7`
  - 필요 시 `chsh -s "$(command -v zsh)" "$USER"` 후 재로그인
- `chsh`에서 `PAM: Authentication failure` 발생:
  - 인터랙티브 터미널에서 다시 실행(비밀번호 입력 필요)
  - 서버/정책 환경이면 관리자 권한으로 변경: `sudo usermod -s "$(command -v zsh)" "$USER"`
- Helix에서만 도구 누락:
  - `hx --health <language>`로 누락 바이너리 확인
- tmux 클립보드가 안 됨:
  - 로컬 터미널의 OSC52 지원 여부 확인
  - tmux 내부에서 `tmux show -g set-clipboard` 결과 확인
- `prefix + h/g/y` 눌렀는데 바로 닫히거나 메시지가 뜸:
  - `command -v hx`, `command -v lazygit`, `command -v yazi` 확인
  - 누락된 도구가 있으면 `mise install` 또는 해당 도구를 설치
- `git dft`에서 `external diff died` 또는 `difft: not found`:
  - `mise use -g difftastic@latest` 실행
  - `command -v dot-difft` / `command -v dot-difft-pager` 확인
  - symlink 확인: `readlink -f ~/.local/bin/dot-difft`
