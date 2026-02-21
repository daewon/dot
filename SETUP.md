# Dotfiles Setup (zprezto + mise + uv)

## 빠른 시작 (권장 순서)
저장소 루트(`/path/to/dot`)에서 아래 순서대로 실행하면 기본 환경이 올라옵니다.

```bash
# 1) toolchain 설치
mise trust
mise install

# 2) Helix용 언어 도구 설치
npm i -g pyright vscode-langservers-extracted yaml-language-server prettier
uv tool install black
uv tool install ruff

# 3) dotfiles 연결
REPO_ROOT="$(pwd)"
ln -sfn "$REPO_ROOT/helix" "$HOME/.config/helix"
ln -sfn "$REPO_ROOT/tmux.conf.user" "$HOME/.tmux.conf"
ln -sfn "$REPO_ROOT/zsh.shared.zsh" "$HOME/.zsh.shared.zsh"

# 4) zsh/git 공용 설정 연결
grep -F 'source "$HOME/.zsh.shared.zsh"' "$HOME/.zshrc" >/dev/null \
  || printf '\n# dot shared zsh presets\n[ -f "$HOME/.zsh.shared.zsh" ] && source "$HOME/.zsh.shared.zsh"\n' >> "$HOME/.zshrc"
git config --global --get-all include.path | grep -Fx "$REPO_ROOT/gitconfig.shared" >/dev/null \
  || git config --global --add include.path "$REPO_ROOT/gitconfig.shared"
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
- `tmux + dmux`: 장시간 작업, 세션 복구, 멀티 repo 작업에 유리
- `tmux popup + lazygit`: 현재 작업 경로에서 Git 작업을 빠르게 처리 가능

## 1) 런타임 설치 (mise)
```bash
mise trust
mise install
mise current
```

`mise.toml`에 정의된 버전(`node`, `python`, `helix`, `tmux`, `lazygit`)이 활성화되면 정상입니다.

## 2) zprezto + zsh 시작 파일 원칙
zprezto 환경에서 가장 흔한 문제는 초기화 중복입니다. 아래처럼 역할을 고정하면 안정적입니다.

- `~/.zshenv`: 최소 설정만 (`ZDOTDIR` 정도)
- `~/.zprofile`: 로그인 셸 전용 설정만
- `~/.zshrc`: interactive 설정 전담 (`$HOME/.zsh.shared.zsh` source 권장)

`~/.zshrc` 예시:
```bash
if [ -f "$HOME/.zsh.shared.zsh" ]; then
  source "$HOME/.zsh.shared.zsh"
fi
```

`zsh.shared.zsh` 포함 내용:
- 대용량 history(`HISTSIZE`, `SAVEHIST`) + 즉시 저장/공유 옵션
- 자주 쓰는 alias(`lg`, `ta`, `fd`, git 관련)
- `prompt skwp` 기본 적용
- `mise activate zsh --quiet` 및 PATH 초기화
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

## 3) Helix 도구 설치 (mise + uv 기준)
Node 기반 LSP/formatter:
```bash
npm i -g pyright vscode-langservers-extracted yaml-language-server prettier
```

Python 도구(uv):
```bash
uv tool install black
uv tool install ruff
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
- 중요: TPM/플러그인은 자동 설치되지 않으며, 최초 1회 수동 설치가 필요함
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
npm i -g dmux
```

dmux 실행 권장 방식:
- 가장 안전: `tmux 밖`에서 `dmux` 실행 (프로젝트별 `dmux-*` 세션 분리)
- 주의: 기존 non-dmux tmux 세션 안에서 실행하면 현재 레이아웃/워크플로우와 충돌 가능

## 5) 설정 파일 위치
- Helix 언어 설정: `helix/languages.toml`
- Helix 에디터 설정: `helix/config.toml`
- tmux 설정: `tmux.conf.user`
- mise 버전 정의: `mise.toml`
- zsh 공용 설정: `zsh.shared.zsh`
- git 공용 alias: `gitconfig.shared`

## 6) 검증 체크리스트
- `mise current`에 필요한 버전이 정확히 표시됨
- `command -v` 결과에 아래 바이너리가 보임:
  - `pyright-langserver`
  - `vscode-json-language-server`
  - `yaml-language-server`
  - `black`
  - `ruff`
  - `prettier`
  - `lazygit`
  - `yazi` (팝업 단축키 `prefix + y` 사용 시)
- `~/.config/helix`가 이 저장소의 `helix`를 가리킴
- `tmux show -g set-clipboard` 결과가 `on`
- `git co` / `git l`가 정상 동작

## 7) 트러블슈팅
- `command not found`:
  - 새 셸을 열거나 `exec zsh`
  - `~/.zshrc`에서 `source "$HOME/.zsh.shared.zsh"` 로드 확인
- `uv tool` 바이너리가 안 보임:
  - `~/.local/bin`이 `PATH`에 있는지 확인
  - 필요 시 `uv tool update-shell`
- Helix에서만 도구 누락:
  - `hx --health <language>`로 누락 바이너리 확인
- tmux 클립보드가 안 됨:
  - 로컬 터미널의 OSC52 지원 여부 확인
  - tmux 내부에서 `tmux show -g set-clipboard` 결과 확인
- `prefix + h/g/y` 눌렀는데 바로 닫히거나 메시지가 뜸:
  - `command -v hx`, `command -v lazygit`, `command -v yazi` 확인
  - 누락된 도구가 있으면 `mise install` 또는 해당 도구를 설치
