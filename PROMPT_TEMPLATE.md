# AI Daily Report — 에이전트 작성 지침

이 파일은 매일 07:30 KST(22:30 UTC)에 트리거되는 원격 routine이 참조하는 작성 가이드입니다.

---

## 🎯 미션

**전일(어제, KST 기준) 발생한 AI 업계 동향을 한국어로 요약하여 신규 보고서 파일을 생성하고 INDEX.md를 갱신한 뒤, git commit/push로 저장합니다.**

---

## 📋 단계별 절차

### Step 1. 날짜 계산
- 현재 UTC 시각을 `date -u +%Y-%m-%dT%H:%M:%SZ`로 확인
- 그 시점 KST(=UTC+9) 기준으로 **오늘 날짜 YYYY-MM-DD**를 산출 (보고서 파일명)
- **검색 윈도우**: KST 기준 어제 00:00 ~ 23:59 (= UTC 어제 15:00 ~ 오늘 14:59)

### Step 2. 검색 (병렬)
다음 쿼리를 WebSearch로 병렬 실행:

1. `Anthropic Claude Code release notes [어제 날짜]`
2. `Anthropic news announcement [어제 날짜]`
3. `OpenAI ChatGPT GPT release [어제 날짜]`
4. `Google Gemini update release [어제 날짜]`
5. `DeepSeek Qwen Kimi Manus xAI Grok new model [어제 날짜]`
6. `AI agent trends paper benchmark [어제 날짜]`

WebSearch가 부족하면 다음 사이트를 WebFetch로 직접 조회:
- https://www.anthropic.com/news
- https://releasebot.io/updates/anthropic/claude-code
- https://platform.claude.com/docs/en/release-notes/overview
- https://ai.google.dev/gemini-api/docs/changelog
- https://gemini.google/release-notes/
- https://releasebot.io/updates/openai
- https://futuretools.io/news
- https://aiweekly.co/

### Step 3. 보고서 작성
파일명: `YYYY-MM-DD.md` (KST 기준 오늘)
저장 위치: 리포 루트

**구조 (반드시 이 순서)**:

```markdown
# AI Daily — YYYY-MM-DD (전일 동향)

## 🎯 오늘의 한 줄
{한 문장으로 핵심 요약. 안 읽어도 될 수준이면 "조용한 하루" 명시}

## ⭐ 핵심 변화 TOP 3
### 1. {제목}
**📌 무슨 일?**
{쉬운 말로 풀어 설명. 전문용어는 비유 사용}

**🤔 왜 중요?**
{1-2문장 컨텍스트}

**👉 너에게 영향**
{Claude Code 터미널 사용자 + 사이드 프로젝트 운영자 관점에서 구체적 영향}

(2, 3도 동일 구조)

## 🔶 Anthropic / Claude Code 깊이 분석
- 가장 큰 비중 (전체의 30~40%)
- Claude Code 신규 버전이 있으면 **버전별 변화 표** (버전/출시일/핵심 변화)
- 즉시 적용할 수 있는 5가지 팁 (구체적 명령어/설정 포함)
- Anthropic 사업·제품 동향 표
- 모든 항목에 **"기존 워크플로우와의 차이"** 언급

## 🟢 Major AI: OpenAI · Google · Meta
- 각 회사별 1-3개 항목
- 각 항목 1-2문장 + 화살표 (👉)로 사용자 영향

## 🟡 Rising AI: Manus · xAI · DeepSeek · Kimi · Qwen
- 비교표 (모델/회사 / 핵심 뉴스 / 너에게 의미) 권장
- 오픈소스/중국계 동향에 한 단락

## 🔬 트렌드 한 컷
- 1개 주제만 깊이 (논문/벤치마크/정책/에이전트 패턴)
- **반드시 비유로 설명** (전문용어 → 일상어)

## 💡 이번 주 활용 아이디어
- ⏱️ 15분으로 시도: 2~3개
- 🕐 1시간으로 시도: 1~2개
- 📅 하루로 시도: 1개

## 📎 출처
- 모든 주장에 URL 첨부
- 카테고리별로 분류 (Anthropic / Major AI / Rising / 트렌드)
- 추측·소문은 [unverified] 태그
```

### Step 4. INDEX.md 갱신
- `INDEX.md`를 읽고 "최근 보고서" 표 **맨 위에** 새 행 추가
- 형식: `| YYYY-MM-DD | [전일 동향](./YYYY-MM-DD.md) | {핵심 키워드 3개} |`
- 7일 이상 지난 행은 그대로 두되, 표 길이가 너무 길어지면 (15개 초과) 가장 오래된 행 5개 정리 — 단, 파일은 삭제하지 말 것

### Step 5. Git 커밋 및 푸시
```bash
git add YYYY-MM-DD.md INDEX.md
git commit -m "AI 일일 보고서 추가: YYYY-MM-DD"
git push origin main
```

---

## ✍️ 톤 & 스타일 규칙

1. **언어**: 한국어 (코드 블록 내부 명령어/URL은 영문 유지)
2. **타겟 독자**: 비개발자도 이해 가능한 수준. 전문용어는 반드시 풀어쓰기 또는 비유.
3. **분량**: 마크다운 1.5~3페이지 (대략 1500~3000단어)
4. **객관성**: 모든 사실에 출처 URL. 추측/소문은 `[unverified]` 명시.
5. **사용자 컨텍스트**:
   - Claude Code 터미널 메인 사용자
   - 가끔 VS Code IDE 통합
   - 사이드 프로젝트는 PRD/Sprint 방법론으로 운영
   - **무료 원칙**: 유료 도구 추천 금지. 추천 시 반드시 무료 대안 병기.
6. **금지**:
   - 수행적 솔직함 ("솔직히 말하면", "다시 보니" 등)
   - 출처 없는 단정
   - 매일 같은 패턴의 반복 — 그날의 가장 임팩트 있는 변화에 비중 조정

---

## 🔄 예외 처리

- **검색 결과가 빈약한 날**: "조용한 하루" 명시 후 1페이지 분량으로 축약. TOP 3 대신 TOP 1로.
- **WebFetch 실패**: 다른 출처로 우회. 모두 실패 시 해당 섹션을 "1차 출처 접근 실패 — 다음 보고에서 보강" 명시.
- **git push 실패**: 푸시 실패 사유를 보고서 마지막에 `[ROUTINE_ERROR]` 섹션으로 기록.
- **중복 실행**: 같은 날짜 파일이 이미 존재하면 덮어쓰지 말고 `YYYY-MM-DD-rerun.md`로 저장.

---

## 📂 참조 파일

- 보고서 톤·구조 예시: `2026-04-27.md` (첫 7일 종합본)
- 인덱스: `INDEX.md`

---

*이 템플릿은 routine과 분리되어 있어, 향후 구조 개선 시 이 파일만 수정하면 됩니다.*
