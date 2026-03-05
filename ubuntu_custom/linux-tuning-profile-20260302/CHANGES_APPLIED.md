# 적용 변경 내역 (무엇을 어떻게 수정했는지)

작성일: 2026-03-02
범위: Linux 데스크톱 튜닝, Firefox 실행 안정화/프로필 복구, GNOME 패널 레이아웃

## 1) Firefox 실행 안정화

문제:
- Firefox 시작 시 잠금/샌드박스/AppArmor 관련 실패

조치:
- Firefox 프로필 경로 + Wayland proxy 소켓 접근을 위한 AppArmor 로컬 허용 규칙 추가

변경 파일(시스템):
- `/etc/apparmor.d/local/usr.bin.firefox`

번들 파일:
- `apparmor/usr.bin.firefox.local.conf`

## 2) Firefox 프로필 복구 및 정리

문제:
- 잘못된 프로필로 열려 설정/로그인이 사라진 것처럼 보임

조치:
- 기본 프로필을 `clean.default-release`로 재지정
- 사용자 확인 후 복구 완료
- 사용자 요청에 따라 다른 프로필 삭제, `clean.default-release`만 유지

변경 파일(사용자):
- `~/.mozilla/firefox/profiles.ini`
- `~/.mozilla/firefox/installs.ini`
- 삭제: `clean.default-release` 외 프로필 디렉터리

번들 파일:
- `firefox/profiles.ini`
- `firefox/installs.ini`

## 3) Firefox 성능/UI 튜닝

조치:
- 재적용 가능하도록 `user.js`에 설정 고정
- compact UI 유지 (`browser.compactmode.show`, `browser.uidensity=1`)
- AV1 비활성 유지(사용자 선택)

변경 파일(사용자):
- `~/.mozilla/firefox/clean.default-release/user.js`
- `~/.config/mozilla/firefox/clean.default-release/user.js`

번들 파일:
- `firefox/user.js`

## 4) GNOME 패널/도크 레이아웃

문제:
- 하단 바 중복(단일 Windows형 하단 바 필요)

조치:
- Dash to Panel 활성화
- Ubuntu Dock 비활성화
- 패널 크기/아이콘 간격 컴팩트 튜닝

변경 dconf 영역:
- `/org/gnome/shell/enabled-extensions`
- `/org/gnome/shell/disabled-extensions`
- `/org/gnome/shell/extensions/dash-to-panel/*`

번들 파일:
- `dconf/gnome-shell.ini`
- `dconf/dash-to-panel.ini`
- `dash-to-panel-v72.tar.gz`
- `gnome-extensions-list.txt`
- `enabled-extensions.txt`
- `disabled-extensions.txt`

## 5) GNOME Terminal + 인터페이스

조치:
- 터미널 헤더바/메뉴바 표시 방식 조정
- 터미널 폰트/색상 프로필 반영
- 인터페이스 값을 재복원 가능하도록 저장

변경 dconf 영역:
- `/org/gnome/terminal/*`
- `/org/gnome/desktop/interface/*`

번들 파일:
- `dconf/gnome-terminal.ini`
- `dconf/desktop-interface.ini`
- `fontconfig/66-cascadia-korean-fallback.conf.disabled`

## 6) 운용 스크립트

포함 항목:
- `restore_tuning.sh` (튜닝 상태 복원)
- `reset_to_defaults.sh` (기본값 방향 복귀)
- `verify_state.sh` (복원 후 자동 점검)

## 7) 빠른 재적용 순서

1. `./restore_tuning.sh`
2. 스크립트가 안내하는 AppArmor `sudo` 명령 실행
3. 로그아웃/로그인 1회
4. `./verify_state.sh`
