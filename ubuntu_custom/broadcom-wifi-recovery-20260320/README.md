# Broadcom Wi-Fi Recovery

Broadcom `BCM43224` (`14e4:4353`) 기반 구형 MacBook에서 Ubuntu 24.04 + Linux 6.17 조합으로 Wi-Fi가 비정상적으로 느릴 때 사용하는 복구 자료입니다.

대상 증상:
- 같은 공유기에서 휴대폰은 빠른데 이 노트북만 느림
- `brcmsmac` 사용 중 공유기 핑이 수십~수백 ms로 튐
- `broadcom-sta-dkms` 기본 패키지가 `6.17` 커널에서 DKMS 빌드 실패

빠른 시작:
```bash
cd $HOME/dot/ubuntu_custom/broadcom-wifi-recovery-20260320
sudo ./repair_broadcom_wl.sh
```

파일 설명:
- `README.md`: 가장 먼저 볼 요약/진입점
- `RECOVERY_RUNBOOK.md`: 증상 판별, 원인, 복구, 검증, 롤백 절차
- `AGENT_HANDOFF.md`: 실제 발생 사례, 측정값, 적용한 패치셋, 주의사항
- `repair_broadcom_wl.sh`: `wl` 드라이버 복구 자동화 스크립트

우선 읽는 순서:
1. `README.md`
2. `RECOVERY_RUNBOOK.md`
3. 필요 시 `AGENT_HANDOFF.md`

핵심 사실:
- 원인은 회선보다 `노트북 <-> 공유기` 링크 불안정이었다.
- `brcmsmac` 대신 `wl`로 전환하되, Ubuntu `23ubuntu1.1` 패키지는 Linux `6.17`에서 바로 안 빌드된다.
- 그래서 Launchpad `broadcom-sta`의 `23ubuntu1.2` 패치셋 커밋 `84a67de558f3c0e82154cc4631195bf85559e7c1` 기준 `amd64/` 파일을 로컬 DKMS 소스에 반영했다.

복구 후 기대 결과:
- `wl` 모듈 로드
- 공유기 핑이 한 자릿수 ms 수준으로 안정
- 외부 핑 스파이크가 크게 줄어듦
