# Linux 튜닝 보고서 (복원용)

생성일: 2026-03-02
대상 사용자: <USER>
목적: 재설치 후 동일 환경 복원

추가 인수인계 문서:
- `README_RECOVERY.md` (복구 시작 안내)
- `RECOVERY_RUNBOOK.md` (증상별 즉시 복구 절차)
- `AGENT_HANDOFF.md` (무엇을 왜 바꿨는지, 장애 원인/해결/복구 포인트)
- `CHANGES_APPLIED.md` (최종 변경 항목과 적용 파일 목록)
- `verify_state.sh` (복구 후 상태 자동 점검)

## 1) 이번 세션에서 유지 중인 핵심 튜닝값

### GNOME Shell / 패널
- 확장 활성 상태
  - 활성: `ding@rastersoft.com`, `tiling-assistant@ubuntu.com`, `ubuntu-appindicators@ubuntu.com`, `dash-to-panel@jderose9.github.com`
  - 비활성: `ubuntu-dock@ubuntu.com`
- Dash to Panel (v72) 핵심 값
  - `panel-position='BOTTOM'`
  - `panel-size=30`
  - `appicon-margin=4`
  - `appicon-padding=2`
  - `intellihide=false`
  - `stockgs-keep-top-panel=false` (상단 기본 패널 유지 안 함)

### GNOME 인터페이스 / 폰트
- `gtk-theme='Yaru-dark'`
- `color-scheme='prefer-dark'`
- `font-name='Ubuntu Sans 11'`
- `document-font-name='Sans 11'`
- `monospace-font-name='Ubuntu Mono 13'`
- `show-battery-percentage=true`
- `text-scaling-factor=1.0`

### GNOME Terminal
- `headerbar=false`
- `default-show-menubar=false`
- 프로필 `b1dcc9dd-5262-4d8d-a863-c897e6d979b9`
  - `font='Cascadia Mono 12'`
  - `use-system-font=false`
  - `use-theme-colors=false`
  - `background-color='rgb(0,0,0)'`
  - `foreground-color='rgb(255,255,255)'`

### Firefox
- 실행 바이너리: `/usr/bin/firefox` (APT 패키지)
- 버전: `Mozilla Firefox 148.0`
- 고정 프로필: `clean.default-release`
- 사용자 튜닝(`user.js`)
  - `gfx.webrender.all=true`
  - `layers.gpu-process.enabled=true`
  - `widget.dmabuf.enabled=true`
  - `media.hardware-video-decoding.enabled=true`
  - `media.rdd-ffmpeg.enabled=true`
  - `media.rdd-vpx.enabled=true`
  - `network.http.http3.enable=true`
  - `browser.sessionstore.interval=60000`
  - `dom.ipc.processCount=4`
  - `media.av1.enabled=false`
  - `browser.compactmode.show=true`
  - `browser.uidensity=1`

### AppArmor (Firefox 실행 안정화)
- 파일: `/etc/apparmor.d/local/usr.bin.firefox`
- 핵심 허용 규칙
  - `~/.config/mozilla/firefox/** rwk`
  - `/run/user/*/wayland-proxy-* rwc`

## 2) 참고: 남아있는 비활성/레거시 흔적

- `~/.config/fontconfig/conf.d/66-cascadia-korean-fallback.conf.disabled`
  - 비활성 파일(`.disabled`) 상태
- dconf 내 `dash-to-dock` 값은 남아 있으나 `ubuntu-dock` 확장은 비활성
- dconf 내 `just-perfection` 섹션 값은 남아 있으나 확장 자체는 현재 미사용

## 3) 복원 파일 목록

백업 폴더: `$HOME/dot/ubuntu_custom/linux-tuning-profile-20260302`

- `restore_tuning.sh` : 현재 튜닝 복원 스크립트
- `reset_to_defaults.sh` : 기본값에 가깝게 되돌리는 스크립트
- `verify_state.sh` : 복원 후 자동 점검
- `dconf/gnome-shell.ini`
- `dconf/dash-to-panel.ini`
- `dconf/desktop-interface.ini`
- `dconf/gnome-terminal.ini`
- `firefox/user.js`
- `firefox/profiles.ini`
- `firefox/installs.ini`
- `apparmor/usr.bin.firefox.local.conf`
- `dash-to-panel-v72.tar.gz`

## 4) 재설치 후 복원 절차

1. 로그인 후 터미널에서 실행
   - `cd $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302`
   - `./restore_tuning.sh`
2. AppArmor 복원(필요 시)
   - `sudo install -D -m 0644 $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302/apparmor/usr.bin.firefox.local.conf /etc/apparmor.d/local/usr.bin.firefox`
   - `sudo apparmor_parser -r /etc/apparmor.d/usr.bin.firefox`
3. 로그아웃/로그인 1회(또는 재부팅)

## 5) 기본값으로 되돌리기

- `cd $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302`
- `./reset_to_defaults.sh`
