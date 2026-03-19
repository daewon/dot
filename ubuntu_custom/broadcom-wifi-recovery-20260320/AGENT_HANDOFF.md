# 에이전트 인수인계 (Broadcom Wi-Fi 복구)

작성일: 2026-03-20
소유자: <USER>
기준 환경:
- Ubuntu 24.04.4 LTS
- Linux `6.17.0-19-generic`
- 모델 `MacBookPro8,2` (2011)
- 무선 칩셋 `Broadcom BCM43224` (`14e4:4353`, Apple AirPort Extreme)
- AP: 5 GHz 네트워크 (channel 157)

관련 파일:
- `README.md`
- `RECOVERY_RUNBOOK.md`
- `repair_broadcom_wl.sh`

## 1) 최종 사용자 요구사항

사용자가 원한 상태:
- 같은 공유기에서 폰은 빠른데, 이 노트북만 유독 느린 문제를 해결할 것
- 다음 LLM이 원인과 복구 절차를 그대로 재현할 수 있게 `dot`에 기록을 남길 것

## 2) 실제 증상과 진단 근거

2026-03-19 ~ 2026-03-20에 확인한 증상:
- 같은 공유기의 휴대폰은 정상 속도
- 이 노트북만 인터넷이 매우 느림
- 원인은 회선/공유기보다 노트북 쪽 Wi-Fi 링크 불안정으로 판명

핵심 진단 근거:
- 기존 드라이버: `brcmsmac`
- `iwconfig wlp2s0b1`
  - `Signal level=-64 dBm`
  - `Tx excessive retries: 157`
- 공유기 핑이 비정상적으로 튐:
  - `ping -c 8 <gateway-ip>`
  - 평균 `102.260 ms`, 최대 `354.316 ms`
- 외부 핑도 크게 흔들림:
  - `ping -c 4 1.1.1.1`
  - 평균 `132.588 ms`, 최대 `398.791 ms`
- 휴대폰은 같은 AP에서 정상이라 공유기/회선 불량 가능성은 낮음

결론:
- 병목은 `노트북 <-> 공유기` 구간
- 특히 `Broadcom BCM43224 + brcmsmac + Linux 6.17` 조합이 불안정

## 3) 중간 장애와 최종 해결

### 장애 A: `brcmsmac` 링크 품질 불량

증상:
- 공유기 핑이 수십~수백 ms로 튐
- 재전송이 많고 체감 속도가 매우 느림

원인:
- 이 호스트에서 `brcmsmac` 드라이버가 현재 커널/환경에서 불안정

조치:
- Ubuntu 권장 드라이버 `broadcom-sta-dkms`로 전환 시도

### 장애 B: Ubuntu 기본 `broadcom-sta-dkms`가 커널 `6.17.0-19`에서 빌드 실패

증상:
- `apt-get install -y broadcom-sta-dkms`가 실패
- `/var/lib/dkms/broadcom-sta/6.30.223.271/build/make.log` 핵심 에러:
  - `fatal error: typedefs.h: No such file or directory`

원인:
- 설치된 패키지 버전 `6.30.223.271-23ubuntu1.1`은 Linux `6.15`~`6.17` 대응 패치가 빠져 있음
- 특히 Kbuild의 `EXTRA_CFLAGS` 제거와 `cfg80211` API 변경 대응이 없음

최종 해결:
- Ubuntu source repo `https://git.launchpad.net/ubuntu/+source/broadcom-sta`
- 기준 커밋: `84a67de558f3c0e82154cc4631195bf85559e7c1`
- 기준 패키지 상태: `6.30.223.271-23ubuntu1.2` (`noble-proposed`, 2025-08-17 changelog)
- 위 커밋의 `amd64/` 최종 파일을 현재 DKMS 소스(`/usr/src/broadcom-sta-6.30.223.271`)에 복사
- 그 후 `dkms build/install`, `modprobe wl`

적용한 수정 범위:
- `Makefile`
- `src/include/linuxver.h`
- `src/wl/sys/wl_linux.c`
- `src/wl/sys/wl_cfg80211_hybrid.c`
- `src/include/bcmutils.h`
- `src/include/wlioctl.h`
- `src/wl/sys/wl_cfg80211_hybrid.h`
- `src/wl/sys/wl_iw.c`

추가 조치:
- Wi-Fi 절전 비활성
  - `nmcli connection modify '<wifi-connection>' 802-11-wireless.powersave 2`

## 4) 현재 최종 상태

드라이버/모듈:
- 로드 모듈: `wl`
- 비활성 모듈: `brcmsmac`, `b43`, `ssb`, `bcma`
- DKMS 상태:
  - `broadcom-sta/6.30.223.271, 6.17.0-19-generic, x86_64: installed`

연결 상태:
- 인터페이스 이름이 `wlp2s0b1` -> `wlp2s0` 로 변경됨
- 활성 연결 예시: `"<ssid> 2"` 형태로 재생성될 수 있음
- `802-11-wireless.powersave: 2 (disable)`

실측 개선치 (2026-03-20):
- 공유기 핑:
  - 전: 평균 `102.260 ms`, 최대 `354.316 ms`
  - 후: 평균 `1.838 ms`, 최대 `2.191 ms`
- 외부 `1.1.1.1` 핑:
  - 전: 평균 `132.588 ms`, 최대 `398.791 ms`
  - 후: 평균 `5.415 ms`, 최대 `6.462 ms`

## 5) 다음 에이전트 우선 절차

1. 이 문제가 다시 보이면 먼저 `RECOVERY_RUNBOOK.md`의 진단 명령으로 같은 증상인지 확인
2. 설치 패키지 버전이 여전히 `23ubuntu1.1` 계열이고 커널이 `6.17` 계열이면:
   - `sudo ./repair_broadcom_wl.sh`
3. 패키지 버전이 `23ubuntu1.2` 이상이면:
   - 로컬 패치보다 먼저 배포판 수정본 반영 여부를 확인
4. 재현 후에는 반드시:
   - `lsmod | grep '^wl'`
   - `dkms status`
   - `ping -c 4 <gateway>`
   - `ping -c 4 1.1.1.1`

## 6) 알려진 주의사항

- 이 복구는 `Broadcom BCM43224` + Ubuntu 24.04 + Linux `6.17`에서 확인한 사례다
- `noble-proposed` 브랜치는 시간이 지나면 이동할 수 있으므로, 문서 안의 커밋 해시를 기준으로 삼는다
- Wi-Fi가 너무 느려서 네트워크 fetch가 어려우면 유선 또는 휴대폰 테더링을 먼저 확보한 뒤 실행한다
- 패키지 업데이트가 `broadcom-sta-dkms`를 다시 덮으면, 로컬 소스 보정이 사라질 수 있다
