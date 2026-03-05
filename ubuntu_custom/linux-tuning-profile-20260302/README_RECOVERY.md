# 복구 시작 안내

이 디렉터리는 다음 에이전트가 동일한 튜닝 상태를 빠르게 복구할 수 있도록 구성되어 있습니다.

## 빠른 시작

1. `AGENT_HANDOFF.md`를 먼저 읽고 배경(무엇이 깨졌고 왜 이렇게 맞췄는지)을 확인합니다.
2. `./restore_tuning.sh`를 실행합니다.
3. 스크립트가 출력하는 AppArmor `sudo` 명령을 실행합니다.
4. 로그아웃 후 다시 로그인합니다.
5. `./verify_state.sh`로 최종 상태를 점검합니다.

## 문제가 있을 때

- 변경 항목 상세: `CHANGES_APPLIED.md`
- 증상별 복구 절차: `RECOVERY_RUNBOOK.md`
- 요약 보고서: `REPORT.md`
- 기본값 방향 복귀: `./reset_to_defaults.sh`

## 빠른 점검 체크리스트

- Firefox가 기존 프로필/로그인 상태로 열림
- GNOME 하단 바가 1개만 보임(Dash to Panel)
- Ubuntu Dock 비활성 상태
- 패널 크기 `30`, 아이콘 간격 컴팩트
- GNOME Terminal 헤더바 비활성 + `Cascadia Mono 12`
