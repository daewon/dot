# 복구 런북 (Broadcom BCM43224 / Ubuntu 24.04 / Linux 6.17)

작성일: 2026-03-20

빠른 시작:
```bash
cd $HOME/dot/ubuntu_custom/broadcom-wifi-recovery-20260320
sudo ./repair_broadcom_wl.sh
```

## 1) 이 런북을 써야 하는 경우

조건:
- 호스트가 `Broadcom BCM43224` 계열 (`14e4:4353`)
- 같은 공유기에서 다른 기기(특히 휴대폰)는 빠른데, 이 노트북만 매우 느림
- `brcmsmac` 사용 중이고 공유기 핑이 크게 튐
- Ubuntu의 `broadcom-sta-dkms` 기본판(`23ubuntu1.1`)이 커널 `6.17`에서 빌드 실패

## 2) 먼저 진단

칩셋/드라이버 확인:
```bash
lspci -nnk | rg -i -A3 -B1 'network|wireless|broadcom'
ethtool -i "$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="wifi"{print $1; exit}')"
```

링크 품질/지연 확인:
```bash
iface="$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="wifi"{print $1; exit}')"
iwconfig "$iface"
gateway="$(nmcli -g IP4.GATEWAY device show "$iface" | sed -n '1p')"
ping -c 8 "$gateway"
ping -c 8 1.1.1.1
```

권장 드라이버 확인:
```bash
ubuntu-drivers devices
```

`broadcom-sta-dkms` 빌드 실패 여부 확인:
```bash
sudo apt-get install -y broadcom-sta-dkms || true
sudo sed -n '1,120p' /var/lib/dkms/broadcom-sta/6.30.223.271/build/make.log
```

이 런북의 대상 증상일 때 보이는 대표 에러:
- `fatal error: typedefs.h: No such file or directory`

## 3) 원인 요약

원인 체인:
1. `brcmsmac`가 이 환경에서 심한 재전송/지연 변동을 일으킴
2. 대체 드라이버 `broadcom-sta-dkms`가 필요함
3. 그런데 Ubuntu `6.30.223.271-23ubuntu1.1` 패키지는 Linux `6.17` 대응이 덜 되어 있어 DKMS 빌드 실패
4. Ubuntu `noble-proposed`의 `23ubuntu1.2` 패치셋(커밋 `84a67de558f3c0e82154cc4631195bf85559e7c1`)을 로컬 DKMS 소스에 반영해야 함

## 4) 실제 복구 절차

실행:
```bash
cd $HOME/dot/ubuntu_custom/broadcom-wifi-recovery-20260320
sudo ./repair_broadcom_wl.sh
```

스크립트가 수행하는 일:
- `broadcom-sta-dkms`, `dkms`, `git` 설치/정리
- Launchpad의 `broadcom-sta` 소스를 커밋 `84a67de558f3c0e82154cc4631195bf85559e7c1` 기준으로 checkout
- `amd64/`의 수정된 파일들을 `/usr/src/broadcom-sta-6.30.223.271`에 복사
- `dkms build/install`
- `brcmsmac`, `b43`, `ssb`, `bcma` 제거 후 `wl` 로드
- 활성 Wi-Fi 연결의 powersave 비활성
- 마지막에 상태/핑 검증 출력

## 5) 복구 후 검증

모듈:
```bash
lsmod | rg '^(wl|brcmsmac|b43|ssb|bcma)\b'
dkms status | sed -n '1,20p'
```

연결:
```bash
nmcli device status
iface="$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="wifi"{print $1; exit}')"
iwconfig "$iface"
nmcli -f 802-11-wireless.powersave connection show "$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="802-11-wireless"{print $1; exit}')"
```

지연:
```bash
gateway="$(nmcli -g IP4.GATEWAY device show "$iface" | sed -n '1p')"
ping -c 4 "$gateway"
ping -c 4 1.1.1.1
```

기대 상태:
- `wl` 모듈 로드
- `brcmsmac` 비활성
- 공유기 핑이 대략 한 자릿수 ms 이내에서 안정
- 외부 핑이 큰 스파이크 없이 안정

## 6) 롤백

`wl`이 더 나쁜 경우:
```bash
sudo modprobe -r wl
sudo modprobe bcma
sudo modprobe brcmsmac
nmcli connection up "$(nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="802-11-wireless"{print $1; exit}')"
```

주의:
- `wl` 적용 후 인터페이스 이름이 바뀔 수 있다 (`wlp2s0b1` -> `wlp2s0`)
- 연결 프로파일 이름도 `"<ssid>"` -> `"<ssid> 2"`처럼 달라질 수 있다

## 7) 재발 시 판단 기준

다시 느려졌을 때:
- `wl`가 이미 로드돼 있고 핑도 안정적이면, 이번 이슈가 아니라 AP/간섭/회선 문제일 수 있음
- `brcmsmac`로 되돌아갔거나 `broadcom-sta-dkms`가 half-configured 상태면 이 런북을 다시 적용
- 패키지 버전이 `23ubuntu1.2` 이상이면, 로컬 패치보다 배포판 수정본 상태를 먼저 재확인
