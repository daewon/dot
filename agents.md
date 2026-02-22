# 에이전트 작업 지침 (dot)

이 문서는 `dot` 저장소 작업 시 필요한 최소 운영 규칙을 정의합니다.

## 1) 소통 규칙
- 기본 응답 언어는 한국어
- 보고 형식: 무엇을 바꿨는지, 왜 바꿨는지, 어떻게 검증했는지
- 요청 없는 대규모 리팩터링/스타일 변경 금지

## 2) 작업 시작 체크
```bash
pwd
git status --short
ls -la
```

추가 확인:
- 설치/도구 변경: `SETUP.md`, `mise.toml`, `scripts/lib/toolset.sh`
- 구조/동작 변경: `docs/architecture.md`, `scripts/setup.sh`, `scripts/cleanup.sh`, `scripts/verify.sh`
- 셸/터미널 변경: `config/zsh.shared.zsh`, `config/tmux.conf.user`

## 3) 변경 원칙
- 최소 변경: 요청 범위 밖 수정 금지
- 안전 우선: 기존 워크플로우(키 바인딩, 경로, alias) 유지
- 계약 우선: 도구 목록/검증 대상은 `scripts/lib/toolset.sh`를 단일 소스로 사용
- 멱등성 기본: setup/cleanup은 반복 실행 시 상태가 수렴해야 함
- 문서 동기화: 동작이 바뀌면 `README.md`, `SETUP.md`, `docs/architecture.md` 함께 갱신

## 4) 영역별 규칙
`tmux` (`config/tmux.conf.user`):
- 키 바인딩 충돌 여부 확인
- 변경 후 `tmux -f ...`로 옵션/바인딩 확인

`Helix` (`config/helix/*`):
- LSP/formatter 변경 시 실제 도구 설치 상태 확인
- 변경 후 `hx --health <lang>`로 확인

`mise/toolset` (`mise.toml`, `scripts/lib/toolset.sh`):
- 도구 추가/삭제 시 required/optional 명령 검증 범위까지 함께 수정
- 신규 버전은 가능한 pin 사용

## 5) 완료 전 검증
```bash
git status --short
git diff -- <수정한 파일>
bash -n setup.sh cleanup.sh verify.sh
bash -n scripts/setup.sh scripts/cleanup.sh scripts/verify.sh scripts/lib/toolset.sh scripts/lib/scriptlib.sh scripts/difft-external.sh scripts/difft-pager.sh scripts/lazygit-theme.sh
./verify.sh --profile fast
```

가능하면 추가:
```bash
mise x shellcheck@0.11.0 -- shellcheck setup.sh cleanup.sh verify.sh scripts/setup.sh scripts/cleanup.sh scripts/verify.sh scripts/lib/toolset.sh scripts/lib/scriptlib.sh scripts/difft-external.sh scripts/difft-pager.sh scripts/lazygit-theme.sh
```

## 6) 금지 사항
- 요청 없는 파괴적 명령(`git reset --hard`, 대량 삭제 등)
- 근거 없는 추정으로 문서/설정 확장
- 존재 확인 없이 경로/파일을 전제로 수정

## 7) 참고 링크
- Anthropic: Building effective agents  
  https://www.anthropic.com/engineering/building-effective-agents
- OpenAI: Agent evals  
  https://developers.openai.com/api/docs/guides/agent-evals
- OpenAI Agents SDK Tracing  
  https://openai.github.io/openai-agents-python/tracing/
- OpenAI Agents SDK Guardrails  
  https://openai.github.io/openai-agents-python/guardrails/
