# AI 일일 보고서 생성 작업

당신은 매일 아침 자동 트리거되는 비대화형 에이전트입니다. 아래 작업을 처음부터 끝까지 자율적으로 완수하고 종료하세요.

## 환경
- 작업 디렉토리: `~/Desktop/Claude-Core/ai-daily-report`
- 이 디렉토리는 GitHub repo (`jmjung950312-cmd/ai-daily-report`)에 이미 연결됨 (로컬 git 인증 됨, push 가능)
- 사용 가능 도구: WebSearch, WebFetch, Bash, Read, Write, Edit, Glob, Grep

## 절차

### Step 1. 날짜·이전 결과 확인
```bash
date -u +%Y-%m-%dT%H:%M:%SZ
TZ=Asia/Seoul date +%Y-%m-%d
```
KST 기준 오늘 날짜를 `YYYY-MM-DD`로 산출. 보고서 파일명: `YYYY-MM-DD.md` (이미 존재 시 `YYYY-MM-DD-rerun.md`).

검색 윈도우는 **KST 기준 어제** (00:00 ~ 23:59).

### Step 2. 작성 가이드 숙지
`~/Desktop/Claude-Core/ai-daily-report/PROMPT_TEMPLATE.md`를 Read. 이게 마스터 사양이며 보고서 구조·톤·규칙을 정의함.

톤·구조 예시: `2026-04-27.md` 참고.

### Step 3. 검색 (병렬)
WebSearch 6개 쿼리를 한 번에 병렬 실행 (PROMPT_TEMPLATE.md Step 2 참조). 그 후 WebFetch로 공식 출처 직접 조회:
- https://www.anthropic.com/news
- https://releasebot.io/updates/anthropic/claude-code
- https://platform.claude.com/docs/en/release-notes/overview
- https://ai.google.dev/gemini-api/docs/changelog
- https://gemini.google/release-notes/

### Step 4. 보고서 작성
PROMPT_TEMPLATE.md의 8개 섹션 구조를 엄격히 준수하여 `YYYY-MM-DD.md` 작성:
1. 🎯 오늘의 한 줄
2. ⭐ 핵심 변화 TOP 3 (각 [무슨 일/왜 중요/너에게 영향])
3. 🔶 Anthropic / Claude Code 깊이 분석 (전체의 30~40%)
4. 🟢 Major AI (OpenAI · Google · Meta)
5. 🟡 Rising AI (Manus · xAI · DeepSeek · Kimi · Qwen)
6. 🔬 트렌드 한 컷 (비유로 설명)
7. 💡 활용 아이디어 (⏱️15분/🕐1시간/📅하루)
8. 📎 출처 (모든 사실에 URL)

### Step 5. INDEX.md 갱신
`INDEX.md`의 "최근 보고서" 표 **맨 위에** 새 행 추가:
```
| YYYY-MM-DD | [전일 동향](./YYYY-MM-DD.md) | {핵심 키워드 3개} |
```

### Step 6. Git commit & push
```bash
cd ~/Desktop/Claude-Core/ai-daily-report
git add YYYY-MM-DD.md INDEX.md
git commit -m "AI 일일 보고서 추가: YYYY-MM-DD"
git push origin main
```

### Step 7. 완료 보고
한 줄로 요약하고 종료:
```
✅ {파일명} 생성 ({단어수}단어), commit {sha}, push 성공
```

또는 실패 시:
```
❌ {단계}에서 실패: {사유}
```

## 핵심 규칙
- 한국어, 비개발자 친화 톤 (전문용어는 비유로 풀이)
- 분량: 1.5~3페이지 (1500~3000단어)
- 모든 사실에 출처 URL, 추측은 `[unverified]` 태그
- 사용자 컨텍스트: Claude Code 터미널 메인 사용자, 무료 원칙
- '솔직히 말하면', '다시 보니' 같은 수행적 솔직함 표현 금지
- 검색 빈약한 날: '조용한 하루' 명시, 1페이지 축약
- 같은 날짜 파일이 이미 존재하면 `-rerun.md`로 저장

자율적으로 실행하고 종료하세요.
