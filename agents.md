# AI 에이전트 작업 지침 (dot)

이 문서는 `dot` 레포에서 작업하는 에이전트를 위한 실무 지침입니다.
목표는 "설정 변경을 안전하게 적용하고, 재현 가능한 상태로 유지"하는 것입니다.

## 0) 기본 소통 원칙
- 사용자 응답은 기본적으로 한글로 작성합니다(사용자가 다른 언어를 요청하면 그 요청을 우선).
- 변경 내용은 "무엇을, 왜, 어떻게 검증했는지"를 짧고 명확하게 보고합니다.
- 사용자가 요청하지 않은 대규모 리팩터링/스타일 변경은 하지 않습니다.

## 1) 현재 레포 구조 (현실 기준)
- `config/tmux.conf.user`: tmux 핵심 설정
- `config/helix/config.toml`, `config/helix/languages.toml`: Helix 설정
- `config/lazygit/config.yml`, `config/lazygit/themes/*`: LazyGit 설정/테마
- `mise.toml`: 도구 버전 선언
- `scripts/lib/toolset.sh`: setup/cleanup/verify 공통 도구 목록 단일 소스
- `scripts/lib/scriptlib.sh`: setup/cleanup/verify 공통 셸 유틸 함수
- `docs/architecture.md`: 설치/복원/멱등성 아키텍처 문서
- `SETUP.md`: 실제 온보딩/설치 문서
- `config/zsh.shared.zsh`: zsh 공용 alias/history/prompt 설정
- `config/zpreztorc`: prezto 모듈 설정 (`git` 모듈 포함)
- `config/gitconfig.shared`: git 공용 alias 설정
- `setup.sh`, `cleanup.sh`, `verify.sh`: 설치/정리/멱등성 검증 진입점(래퍼)
- `scripts/setup.sh`, `scripts/cleanup.sh`, `scripts/verify.sh`: 실제 구현
- `scripts/difft-external.sh`, `scripts/difft-pager.sh`: `git dft*` wrapper 구현
- `scripts/lazygit-theme.sh`: LazyGit 테마 순환/적용 스크립트
- `config/emacs`: Emacs 설정 파일 (디렉터리 아님)
- `gemini.md`, `qwen.md`: `agents.md`로 연결된 심볼릭 링크(환경에 따라 없을 수 있음)

주의:
- `zsh/` 디렉터리는 이 레포에 없습니다.
- zprezto/zsh 운영 원칙은 `SETUP.md` 문서 기준으로 다룹니다.

## 2) 세션 시작 초기화 체크리스트 (필수)
작업 시작 시 아래 순서로 컨텍스트를 고정합니다.

1. 작업 위치/변경 상태 확인
```bash
pwd
git status --short
```

dirty 상태라면:
- 기존 변경 파일 목록을 먼저 고정해 두고(메모)
- 이번 요청 범위와 무관한 파일은 건드리지 않습니다.

2. 기준 문서/파일 읽기
```bash
sed -n '1,220p' agents.md
sed -n '1,260p' SETUP.md
```

3. 대상 파일 존재 확인
```bash
ls -la
```

4. 변경 대상별 빠른 점검
- tmux 작업이면: `config/tmux.conf.user` 우선 확인
- Helix 작업이면: `config/helix/config.toml`, `config/helix/languages.toml` 우선 확인
- 도구/버전 작업이면: `mise.toml`, `SETUP.md` 동시 확인
- shell/git alias 작업이면: `config/zsh.shared.zsh`, `config/gitconfig.shared`, `scripts/difft-*.sh`, `SETUP.md` 동시 확인
- lazygit 테마 작업이면: `config/lazygit/config.yml`, `config/lazygit/themes/*`, `scripts/lazygit-theme.sh`, `SETUP.md` 동시 확인

## 3) 변경 원칙
- 최소 변경: 요청 범위 밖 수정 금지
- 안전 우선: 사용자 워크플로우(키 바인딩, prefix, popup)를 깨지 않기
- 문서 동기화: 동작/설치/버전이 바뀌면 `SETUP.md` 같이 갱신
- 기존 변경 존중: 이미 dirty 상태인 다른 파일은 함부로 되돌리지 않기
- 검증 후 보고: "적용 + 확인 결과"까지 한 번에 제공
- Functional Core, Imperative Shell: 핵심 로직(판정/계산)은 순수 함수처럼 유지하고, 파일/네트워크/시스템 변경은 스크립트 가장자리(step/run)에서만 수행
- Immutable First: 관리 상태는 덮어쓰기보다 "새 상태 생성 후 원자적 교체(`tmp` + `mv`)"를 우선하고, 기존 사용자 파일은 백업/보존을 기본값으로 유지
- Railway Oriented: 단계별 성공/실패 경로를 분기해 실패 시 즉시 중단(`set -Eeuo pipefail`, `trap on_error`)하고, 부분 성공 상태를 묵살하지 않기
- Parse, Don’t Validate: 옵션/환경값은 초기에 도메인 값으로 파싱(예: `0|1`, 정수 loop, 절대경로)하고 이후 로직은 파싱된 값만 사용
- 계약 우선: 도구 목록/명령 검증/cleanup 대상은 단일 계약(`scripts/lib/toolset.sh`, setup manifest)에서만 정의
- Make Illegal States Unrepresentable: 허용되지 않는 상태 조합(예: 중복 include, 관리 외 대상 삭제)은 자료구조/계약 단계에서 표현 불가능하게 설계
- Single Source of Truth: 경로/도구/관리대상은 한 곳에서만 선언하고, 문서/코드/검증은 그 선언을 참조만 하도록 유지
- Idempotency by Default: 모든 setup/cleanup 단계는 재실행 시 추가 부작용이 없어야 하며, 반복 실행 안전성을 기본 전제로 구현
- Deterministic over Implicit: 같은 입력이면 같은 결과가 나오도록 하고, 시간/환경 의존 로직은 반드시 출력 로그로 근거를 남김
- Explicit Inputs, Explicit Outputs: 함수/스크립트는 숨은 전역 상태보다 명시적 입력과 반환(코드/로그/파일)으로 동작을 드러냄
- Fail Fast, Fail Loud: 복구 불가능하거나 계약 위반 상태는 조용히 진행하지 말고 즉시 실패 + 원인 로그를 출력
- Small Steps, Reversible Changes: 큰 변경은 단계로 쪼개고, 각 단계가 롤백/복원 가능한 상태를 유지하며 진행
- Observable by Design: 각 step은 사람이 추적 가능한 로그를 남기고, 검증 스크립트는 결과뿐 아니라 증거 경로(`log dir`)까지 보고

### 3.1 에이전트 반복 루프 (필수)
요청이 단순 조회가 아닌 변경 작업이라면 아래 루프를 기본으로 반복합니다.

1. Plan
   - 문제 정의, 성공 조건(관측 가능한 기준), 비목표를 먼저 고정
   - 영향 범위(파일/런타임/사용자 체감)를 명시
2. Critique
   - 계획을 바로 구현하지 말고 실패 시나리오를 먼저 반박
   - "무엇이 깨질 수 있는가?"를 경로/권한/호환성/비용 관점에서 점검
3. Eval Design
   - 구현 전에 검증 계약을 먼저 작성
   - 최소 3층 검증: 정적(`bash -n`, `shellcheck`) + 동적(`setup/cleanup/verify`) + 회귀(반복 루프)
   - 필요한 경우 가드레일/차단 조건(tripwire)과 중단 조건(max iteration)을 먼저 정의
4. Implement
   - 최소 변경으로 적용
   - 계약(도구 목록/manifest/문서)과 코드가 동시에 맞도록 수정
5. Verify
   - 빠른 검증(최소 프로파일) 후 강한 검증(반복 루프)로 확장
   - 실패 시 즉시 원인/증거(log path) 기록 후 재진입
6. Re-plan
   - 결과를 기준으로 계획을 업데이트하고 다시 1단계로 반복
   - "복잡도 추가"는 측정상 이득이 확인될 때만 허용

### 3.2 루프 운용 체크리스트
- Grounded Execution: 추정 대신 실행 결과(테스트/로그/트레이스)로 판단
- Tool-Interactive Critique: 자기평가만 믿지 말고 외부 도구 결과(컴파일러, 테스트, 린터, 검색 결과)로 교차검증
- Trace First Debugging: 재현 불가 이슈는 추측하지 말고 trace/log를 먼저 수집
- Guardrail by Cost: 고비용/고위험 단계 전에 입력 차단 검증을 먼저 실행(필요 시 blocking 모드)
- Stop Conditions: 무한 루프 방지를 위해 반복 횟수/시간/비용 상한을 명시

### 3.3 Eval Flywheel (지속 개선 루프)
기능 추가/리팩터링/회귀 수정 시 아래 플라이휠을 기본으로 돌립니다.

1. Failure Harvest
   - 실제 실패 로그/trace에서 재현 가능한 사례를 수집
   - "증상"이 아니라 "입력-기대-실제" 형태로 정규화
2. Eval Authoring
   - 수집된 실패를 평가 케이스로 고정(회귀 방지용)
   - 가능하면 유형별(경로/권한/도구 누락/호환성)로 분류
3. Patch
   - 최소 수정으로 원인 지점을 교정
   - 도구/경로 계약이 바뀌면 문서와 검증 계약 동시 수정
4. Regression Gate
   - 새 케이스 + 기존 핵심 케이스를 함께 실행
   - 기존 성공 시나리오를 깨뜨리면 변경 폐기 또는 재수정
5. Promote
   - 통과한 변경만 기본 흐름으로 반영
   - 로그 경로와 핵심 지표(성공/실패 수, 반복 루프 결과)를 기록

## 4) 영역별 실무 규칙

### 4.1 tmux (`config/tmux.conf.user`)
- 키 바인딩 변경 시 기존 충돌 여부를 먼저 확인합니다.
- popup 관련 바인딩(`h`, `g`, `y`)은 실제 도구 존재 여부와 같이 설명합니다.
- join/layout 바인딩(`j`, `S`, `V`, `Space`, `BSpace`, `=`) 변경 시 기존 워크플로우와 충돌 여부를 먼저 확인합니다.
- 클립보드/터미널 옵션 변경 시 호환성 옵션(버전 가드)을 유지합니다.
- `tmux-continuum` 저장/복원 값(`@continuum-restore`, `@continuum-save-interval`)을 문서와 함께 동기화합니다.
- 적용 후 최소 검증:
```bash
TMUX_SOCK="codexcheck-$RANDOM"
tmux -L "$TMUX_SOCK" -f "$PWD/config/tmux.conf.user" start-server \
  \; show-options -g set-clipboard \
  \; show-options -gqv @plugin \
  \; show-options -gqv @continuum-restore \
  \; show-options -gqv @continuum-save-interval \
  \; list-keys \
  | rg "bind-key\\s+-T prefix\\s+(j|S|V|Space|BSpace|=)"
tmux -L "$TMUX_SOCK" kill-server >/dev/null 2>&1 || true
```

### 4.2 Helix (`config/helix/*`)
- 언어 서버/formatter 변경 시 실제 설치 경로와 도구명을 맞춥니다.
- 변경 후 최소 검증:
```bash
hx --health python
hx --health json
hx --health yaml
```

### 4.3 mise/설치 문서 (`mise.toml`, `SETUP.md`)
- 도구 추가/버전 변경 시 `mise.toml`과 `SETUP.md`를 함께 수정합니다.
- setup/cleanup/verify에서 쓰는 도구 목록은 `scripts/lib/toolset.sh`를 기준으로 유지합니다.
- 도구 계약은 `required`/`optional` 명령 배열까지 동기화합니다.
  - `DOT_REQUIRED_MISE_TOOLS` 변경 시 `DOT_REQUIRED_CLI_COMMANDS` 검증 범위 확인
  - `DOT_OPTIONAL_MISE_TOOLS` 변경 시 `DOT_OPTIONAL_CLI_COMMANDS` 검증 범위 확인
- `verify.sh`는 최소 프로파일에서 required 명령, default 프로파일에서 required+optional 명령을 검증하므로, 도구 추가 시 두 프로파일 결과를 모두 확인합니다.
- 설치/복원 구조 변경 시 `docs/architecture.md`도 같이 갱신합니다.
- 재현성 기본 정책은 pin 버전입니다. 특별한 이유가 없으면 `latest`를 신규 도입하지 않습니다.
- 설치/실행 명령은 복붙 가능한 형태로 유지합니다.
- 경로 원칙: 레포 절대경로 하드코딩 대신 `REPO_ROOT` + symlink(`~/.local/bin/dot-*`) 구조를 유지합니다.
- `.dmux/`, `.dmux-hooks/` 같은 실행 중 생성 디렉터리는 설정 소스가 아니므로 수정/커밋 대상으로 취급하지 않습니다.
- 자동화 동기화: 검증 흐름이 바뀌면 `.github/workflows/quality.yml`도 함께 갱신합니다.

### 4.4 Emacs (`config/emacs`)
- 현재는 단일 파일 기반 설정입니다.
- Emacs 관련 변경은 기존 스타일과 로딩 영향(성능/초기화 순서)을 고려합니다.

## 5) 완료 전 최종 점검
```bash
git status --short
git diff -- <수정한 파일>
bash -n setup.sh cleanup.sh verify.sh
bash -n scripts/setup.sh scripts/cleanup.sh scripts/verify.sh scripts/difft-external.sh scripts/difft-pager.sh scripts/lazygit-theme.sh
mise x shellcheck@0.11.0 -- shellcheck setup.sh cleanup.sh verify.sh scripts/setup.sh scripts/cleanup.sh scripts/verify.sh scripts/lib/toolset.sh scripts/lib/scriptlib.sh scripts/difft-external.sh scripts/difft-pager.sh scripts/lazygit-theme.sh
./verify.sh --profile full
```

보고 시 포함:
- 변경 파일 목록
- 사용자 체감 동작 변화
- 실행한 검증 명령과 핵심 결과
- `verify.sh` 로그 디렉터리 경로(예: `/tmp/dot-verify-...`)
- 남은 리스크(있다면 1~2줄)

## 6) 금지/주의 사항
- 요청 없는 파괴적 명령(`reset --hard`, 대량 삭제 등) 금지
- 근거 없는 추정으로 문서/설정 확장 금지
- 확인되지 않은 경로(`zsh/` 등) 전제로 지침 작성 금지

## 7) 웹 근거 자료 (핵심)
- Anthropic, Building effective agents (단순/조합 패턴 우선, 측정 기반 복잡도 증가)
  - https://www.anthropic.com/engineering/building-effective-agents
- OpenAI, Agent evals (재현 가능한 평가, trace grading, eval flywheel)
  - https://developers.openai.com/api/docs/guides/agent-evals
- OpenAI Agents SDK, Tracing (실행 이벤트 관측/디버깅/모니터링)
  - https://openai.github.io/openai-agents-python/tracing/
- OpenAI Agents SDK, Guardrails (입출력 검증, parallel vs blocking, tripwire)
  - https://openai.github.io/openai-agents-python/guardrails/
- ReAct (reasoning + acting interleave)
  - https://arxiv.org/abs/2210.03629
- Reflexion (verbal feedback + episodic memory)
  - https://arxiv.org/abs/2303.11366
- Self-Refine (초안→피드백→정제 반복)
  - https://arxiv.org/abs/2303.17651
- CRITIC (도구 기반 비평/수정 루프)
  - https://arxiv.org/abs/2305.11738
- Tree of Thoughts (다중 경로 탐색/자기평가/백트래킹)
  - https://arxiv.org/abs/2305.10601
- Plan-and-Solve Prompting (선계획 후 해결로 누락 단계 감소)
  - https://arxiv.org/abs/2305.04091
