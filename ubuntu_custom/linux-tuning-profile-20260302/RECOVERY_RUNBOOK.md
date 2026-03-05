# 복구 런북 (증상 -> 원인 -> 조치)

작성일: 2026-03-02

## 1) Firefox가 실행되지 않음 / 잠금 오류

증상:
- "Firefox is already running, but is not responding"
- Wayland/AppArmor 권한 오류

가능 원인:
- AppArmor가 `~/.config/mozilla/firefox` 또는 `wayland-proxy` 소켓 접근을 차단

조치:
```bash
cd $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302
sudo install -D -m 0644 apparmor/usr.bin.firefox.local.conf /etc/apparmor.d/local/usr.bin.firefox
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.firefox
```

검증:
```bash
grep -n "wayland-proxy" /etc/apparmor.d/local/usr.bin.firefox
```

## 2) Firefox 설정/로그인이 사라진 것처럼 보임

증상:
- 구글 로그인 해제 상태
- 탭/밀도 등 기존 설정 미적용

가능 원인:
- Firefox 기본 프로필 포인터가 다른 프로필로 바뀜

조치:
```bash
cd $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302
cp firefox/profiles.ini ~/.mozilla/firefox/profiles.ini
cp firefox/installs.ini ~/.mozilla/firefox/installs.ini
mkdir -p ~/.mozilla/firefox/clean.default-release ~/.config/mozilla/firefox/clean.default-release
cp firefox/user.js ~/.mozilla/firefox/clean.default-release/user.js
cp firefox/user.js ~/.config/mozilla/firefox/clean.default-release/user.js
```

검증:
```bash
grep -n "clean.default-release" ~/.mozilla/firefox/profiles.ini ~/.mozilla/firefox/installs.ini
```

## 3) 하단 바가 2개 보임(패널 + 도크 중복)

증상:
- 하단에 바가 두 줄로 표시됨

가능 원인:
- Ubuntu Dock과 Dash to Panel이 동시에 동작

조치:
```bash
gsettings set org.gnome.shell disabled-extensions "['ubuntu-dock@ubuntu.com']"
gnome-extensions enable dash-to-panel@jderose9.github.com
gnome-extensions disable ubuntu-dock@ubuntu.com
```

검증:
```bash
gsettings get org.gnome.shell enabled-extensions
gsettings get org.gnome.shell disabled-extensions
```

## 4) 하단 패널 크기/아이콘 간격이 다름

목표:
- 하단 패널 크기 `30`
- 아이콘 간격 컴팩트

조치:
```bash
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-position "'BOTTOM'"
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-size 30
dconf write /org/gnome/shell/extensions/dash-to-panel/appicon-margin 4
dconf write /org/gnome/shell/extensions/dash-to-panel/appicon-padding 2
```

검증:
```bash
dconf read /org/gnome/shell/extensions/dash-to-panel/panel-size
dconf read /org/gnome/shell/extensions/dash-to-panel/appicon-margin
dconf read /org/gnome/shell/extensions/dash-to-panel/appicon-padding
```

## 5) 터미널 상단 영역이 두껍거나 폰트가 다름

목표:
- 헤더바 비활성
- 폰트 `Cascadia Mono 12`

조치:
```bash
dconf load /org/gnome/terminal/ < dconf/gnome-terminal.ini
```

검증:
```bash
dconf read /org/gnome/terminal/legacy/headerbar
dconf dump /org/gnome/terminal/ | grep -n "font='Cascadia Mono 12'"
```

## 6) 한 번에 복구/검증

복구:
```bash
cd $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302
./restore_tuning.sh
```

검증:
```bash
./verify_state.sh
```

## 7) 기본값 방향으로 되돌리기

```bash
cd $HOME/dot/ubuntu_custom/linux-tuning-profile-20260302
./reset_to_defaults.sh
```
