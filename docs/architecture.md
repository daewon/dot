# 설치/정리/검증 아키텍처

## 목표
- 새 환경에서 반복 가능한 setup
- 사용자 데이터 손상 없는 cleanup
- 반복 실행에도 같은 결과를 보장하는 멱등성

## 구성
- 진입점: `setup.sh`, `cleanup.sh`, `verify.sh`
- 구현: `scripts/setup.sh`, `scripts/cleanup.sh`, `scripts/verify.sh`
- 공통 계약: `scripts/lib/toolset.sh`
- 공통 유틸: `scripts/lib/scriptlib.sh`
- 로컬 오버라이드 방지 placeholder: `mise.toml`
- 상태 경로: `${XDG_STATE_HOME:-$HOME/.local/state}/dot`

SSOT 원칙:
- 저장소(`dot`)가 단일 기준이며, 시스템 전역 설정은 setup/cleanup 실행 결과로 파생된다.
- 도구 정책 단일화:
  - 전역 설치 정책(required/optional): `scripts/lib/toolset.sh`
  - `mise.toml`은 로컬 툴체인 선언 없이 placeholder로 유지

## 핵심 계약
도구 계약(`scripts/lib/toolset.sh`):
- `DOT_REQUIRED_MISE_TOOLS`
- `DOT_OPTIONAL_MISE_TOOLS`
- `DOT_REQUIRED_CLI_COMMANDS`
- `DOT_OPTIONAL_CLI_COMMANDS`

manifest 계약:
- 파일: `setup-manifest.v1.tsv`
- 헤더: `version`, `repo_root`
- 엔트리: `symlink`, `managed_file_contains`, `git_clone_origin`, `git_include_path`

## 동작 흐름
setup:
1. 입력/환경 검증
2. global 도구 설치(`mise use -g`, required/optional)
3. (선택 도구 활성 시) `java 21`/`mill`/`pyright`/`typescript-language-server`/`typescript`/`dmux` 설치 후(기본 required `coursier(cs)` 사용) `metals` launcher 구성
4. zsh/prezto 준비
5. 관리 대상 symlink 연결
6. git include 정규화
7. manifest 기록

cleanup:
1. 입력/환경 검증
2. manifest 우선 정리
3. manifest 사용 불가 시 static fallback
4. 선택적으로 global tool 엔트리 정리

verify:
1. 스크립트 문법/정적 점검
2. dry-run 스모크
3. setup-only 반복 검증
4. cleanup→setup 반복 검증

## 안전 규칙
- 관리 대상 외 일반 파일은 삭제하지 않음
- 예상과 다른 symlink는 보존
- managed clone 경로가 예상과 다르면 삭제 대신 백업 후 재구성
- git include 중복은 정규화
- 실패 시 즉시 중단하고 원인 로그를 남김

## 변경 시 체크
- 도구/버전 변경: `scripts/lib/toolset.sh` + 관련 문서(`SETUP.md`, `README.md`)
- 상태 계약 변경: `scripts/*` + `docs/architecture.md`
- 최소 검증: `./verify.sh --profile fast`
