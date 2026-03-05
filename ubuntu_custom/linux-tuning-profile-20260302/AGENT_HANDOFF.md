# 에이전트 인수인계 (복구 중심)

작성일: 2026-03-02
소유자: <USER>
기준 환경:
- Ubuntu 24.04.4 LTS
- Linux 6.17.0-14-generic
- GNOME Shell 46.0
- Firefox (APT) 148.0

## 1) 최종 사용자 요구사항

사용자가 최종적으로 원한 상태:
- Firefox가 우회 없이 안정적으로 실행될 것
- 기존 Firefox 프로필/로그인/설정이 유지될 것
- GNOME은 Windows 스타일의 하단 단일 바일 것
- 하단 바는 낮은 높이 + 좁은 아이콘 간격일 것
- Firefox 탭은 내장 compact/density 설정만 사용할 것
- 재설치 후 다른 에이전트가 그대로 복구 가능할 것

## 2) 주요 장애와 최종 해결

### 장애 A: Firefox 실행 실패
증상:
- 실행 잠금/무응답 메시지
- Sandbox/Wayland/AppArmor 권한 오류

원인:
- Firefox AppArmor 정책에서 아래 경로 권한이 부족
  - `~/.config/mozilla/firefox`
  - `/run/user/*/wayland-proxy-*`

최종 해결:
- 로컬 AppArmor 오버라이드 추가
  - `/etc/apparmor.d/local/usr.bin.firefox`
- Firefox AppArmor 프로필 재적용

근거 파일:
- `apparmor/usr.bin.firefox.local.conf`

### 장애 B: "Firefox 설정이 날아간 것처럼 보임"
증상:
- 로그인 해제 상태
- 기존 UI/탭 관련 설정 미적용

원인:
- 기본 프로필 포인터가 신규/다른 프로필로 변경됨

최종 해결:
- 기본 프로필을 `clean.default-release`로 재지정
- 사용자 확인 후 정상 복구 확인
- 사용자 요청에 따라 다른 프로필은 삭제하고 `clean.default-release`만 유지

근거 파일:
- `firefox/profiles.ini`
- `firefox/installs.ini`
- `firefox/user.js`

### 장애 C: 도크/패널 중복 표시
증상:
- 하단 UI가 2줄로 중복 표시

원인:
- Ubuntu Dock + Dash to Panel 동시 동작

최종 해결:
- Dash to Panel 활성화 유지
- Ubuntu Dock 비활성 유지
- 패널 하단/컴팩트 크기 튜닝

근거 파일:
- `dconf/gnome-shell.ini`
- `dconf/dash-to-panel.ini`
- `dash-to-panel-v72.tar.gz`

## 3) 현재 최종 튜닝 상태 (핵심)

GNOME 확장 상태:
- `dash-to-panel@jderose9.github.com` 활성
- `ubuntu-dock@ubuntu.com` 비활성

Dash to Panel 핵심 값:
- `panel-position='BOTTOM'`
- `panel-size=30`
- `appicon-margin=4`
- `appicon-padding=2`
- `stockgs-keep-top-panel=false`

GNOME Terminal:
- 헤더바 비활성
- 메뉴바 숨김
- 프로필 폰트 `Cascadia Mono 12`

Firefox:
- 실행 경로 `/usr/bin/firefox` (APT 패키지)
- 활성 프로필 `clean.default-release` 단일 유지
- `user.js`에 성능 + compact 밀도 설정 포함
- AV1은 의도적으로 비활성 (`media.av1.enabled=false`)

## 4) 실제 시스템에서 변경된 경로

시스템 레벨(관리자 권한 필요):
- `/etc/apparmor.d/local/usr.bin.firefox`

사용자 레벨:
- `~/.mozilla/firefox/profiles.ini`
- `~/.mozilla/firefox/installs.ini`
- `~/.mozilla/firefox/clean.default-release/user.js`
- `~/.config/mozilla/firefox/clean.default-release/user.js`
- dconf 키 영역:
  - `/org/gnome/shell/`
  - `/org/gnome/shell/extensions/dash-to-panel/`
  - `/org/gnome/desktop/interface/`
  - `/org/gnome/terminal/`

## 5) 다음 에이전트 복구 절차

1. 실행:
   - `cd $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302`
   - `./restore_tuning.sh`
2. AppArmor 적용:
   - `sudo install -D -m 0644 apparmor/usr.bin.firefox.local.conf /etc/apparmor.d/local/usr.bin.firefox`
   - `sudo apparmor_parser -r /etc/apparmor.d/usr.bin.firefox`
3. 로그아웃/로그인 1회
4. 검증:
   - `./verify_state.sh`

## 6) 롤백(기본값 방향)

- `cd $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302`
- `./reset_to_defaults.sh`

참고:
- 롤백 스크립트는 튜닝값을 되돌리지만 Firefox 프로필 데이터는 삭제하지 않음
- AppArmor 로컬 파일은 자동 삭제하지 않음

## 7) 알려진 주의사항

- 제한된 샌드박스 터미널에서는 `dconf`/`gsettings`에 아래 오류가 보일 수 있음
  - `unable to create file '/run/user/1000/dconf/user': Permission denied`
- 이는 일반 GNOME 세션 자체의 설정 오류를 의미하지 않음
- 복구/검증은 데스크톱 사용자 세션의 일반 터미널에서 실행 권장
