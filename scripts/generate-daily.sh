#!/bin/bash
# AI Daily Report 생성 스크립트
# launchd가 매일 07:30 KST에 호출.
# Mac이 잠자던 중이면 깨어날 때 자동 실행 (StartCalendarInterval 기본 동작).

set -u
REPO_DIR="$HOME/Claude/Claude-Core/ai-daily-report"
LOG_DIR="$HOME/Library/Logs/ai-daily-report"
LOG_FILE="$LOG_DIR/generate.log"
PROMPT_FILE="$REPO_DIR/scripts/daily-prompt.md"

mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
TODAY_KST=${TODAY_KST:-$(TZ=Asia/Seoul date +%Y-%m-%d)}

echo "" >> "$LOG_FILE"
echo "===== $TIMESTAMP — 보고서 생성 시작 =====" >> "$LOG_FILE"

cd "$REPO_DIR" || { echo "❌ repo 진입 실패" >> "$LOG_FILE"; exit 1; }

# 가드: 오늘(KST) 보고서를 이미 commit했으면 claude 재호출 없이 종료 (재시도 비용 컷).
# 파일명을 오늘/어제(백필) 어느 날짜로 쓰든 git 커밋 이력으로 판단 — 날짜 불일치 영향 안 받음.
# 단 미발행(push 안 됨) 상태면 push만 하고 종료 (HiL 게이트로 막혔던 경우 자동 복구).
COMMITTED_TODAY=$(/usr/bin/git log --since="today 00:00" --oneline -- '202*.md' 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')
UNPUSHED_NOW=$(/usr/bin/git log origin/main..HEAD --oneline 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')
if [ "$COMMITTED_TODAY" != "0" ]; then
  if [ "$UNPUSHED_NOW" != "0" ]; then
    PUSH_OUTPUT=$(/usr/bin/git push origin main 2>&1)
    echo "ℹ️  오늘 보고서 이미 commit됨 — 미발행 ${UNPUSHED_NOW}건 push 시도: $PUSH_OUTPUT" >> "$LOG_FILE"
  else
    echo "ℹ️  오늘 보고서 이미 발행됨 — 재시도 스킵 (정상)" >> "$LOG_FILE"
  fi
  echo "===== 종료: $(date +"%H:%M:%S") (guard) =====" >> "$LOG_FILE"
  exit 0
fi

# launchd는 PATH가 최소 — claude CLI 위치 명시
CLAUDE_BIN="/Users/jungmo/.local/bin/claude"
if [ ! -x "$CLAUDE_BIN" ]; then
  echo "❌ claude CLI 없음: $CLAUDE_BIN" >> "$LOG_FILE"
  /usr/bin/osascript -e "display notification \"claude CLI 경로 오류\" with title \"AI Daily Report\" sound name \"Basso\""
  exit 1
fi

# Claude 호출 (헤드리스, 권한 체크 우회, 비용 상한 $3)
# claude는 콘텐츠 생성만 담당. git commit/push는 아래 셸이 책임 (claude가 budget 초과로 죽어도 파일 있으면 push 가능)
"$CLAUDE_BIN" \
  -p "$(cat "$PROMPT_FILE")" \
  --permission-mode bypassPermissions \
  --max-budget-usd 3.0 \
  --model claude-sonnet-4-6 \
  >> "$LOG_FILE" 2>&1

CLAUDE_EXIT=$?
echo "" >> "$LOG_FILE"
echo "[claude exit code: $CLAUDE_EXIT]" >> "$LOG_FILE"

# 결과 검증 + 발행 (claude가 비정상 종료/HiL 게이트로 push 못 해도 셸이 책임)
# 파일명을 오늘/어제(백필) 어느 날짜로 쓰든 git 상태로 새 보고서를 탐지 — 날짜 의존 제거.
cd "$REPO_DIR"

# 1) 새로 생기거나 수정된 보고서 파일 탐지 (untracked + modified)
NEW_MD=$(/usr/bin/git status --porcelain -- '202*.md' 2>/dev/null | /usr/bin/awk '{print $NF}' | head -1)
# 2) 이미 commit됐지만 push 안 된 보고서(=claude가 commit만 함)도 발행 대상
UNPUSHED=$(/usr/bin/git log origin/main..HEAD --oneline 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')

if [ -n "$NEW_MD" ] || [ "$UNPUSHED" != "0" ]; then
  # 새/수정 파일이 있으면 add + commit (없으면 미발행 커밋만 push)
  /usr/bin/git add 202*.md INDEX.md 2>>"$LOG_FILE"
  if /usr/bin/git diff --cached --quiet; then
    echo "ℹ️  git: 새 변경 없음 — 미발행 커밋만 push" >> "$LOG_FILE"
  else
    CMSG_DATE=$(echo "$NEW_MD" | /usr/bin/sed 's/\.md$//; s/-rerun$//')
    [ -z "$CMSG_DATE" ] && CMSG_DATE="$TODAY_KST"
    /usr/bin/git -c user.email="jmjung950312@gmail.com" -c user.name="ai-daily-report-bot" commit -m "AI 일일 보고서 추가: ${CMSG_DATE}" >>"$LOG_FILE" 2>&1
  fi

  # 셸 직접 push — HiL 게이트는 claude 세션의 PreToolUse 훅이라 셸 git push엔 적용 안 됨
  PUSH_OUTPUT=$(/usr/bin/git push origin main 2>&1)
  PUSH_EXIT=$?
  echo "$PUSH_OUTPUT" >> "$LOG_FILE"
  if [ $PUSH_EXIT -eq 0 ]; then
    GIT_STATUS="GitHub push 완료"
  else
    GIT_STATUS="⚠️ push 실패 (commit은 로컬에 있음)"
  fi

  # 발행된 최신 보고서 파일명/단어수 (알림용)
  PUB_FILE=$(ls -t 202*.md 2>/dev/null | head -1)
  WORD_COUNT=$([ -n "$PUB_FILE" ] && /usr/bin/wc -w < "$PUB_FILE" | /usr/bin/tr -d ' ' || echo "0")
  /usr/bin/osascript -e "display notification \"${PUB_FILE} (${WORD_COUNT}단어) — ${GIT_STATUS}\" with title \"📰 AI Daily Report\" subtitle \"오늘의 AI 동향 준비\" sound name \"Glass\""
  echo "✅ ${PUB_FILE} 발행 ($WORD_COUNT 단어) — $GIT_STATUS" >> "$LOG_FILE"
elif [ -f "${TODAY_KST}.md" ]; then
  # 할 일이 안 남았는데 오늘 파일은 있다 = claude가 생성·커밋·push까지 스스로 끝낸 경우다 (2026-08-05 신설).
  # 이걸 실패로 신고하던 버그가 있었다. 검사가 "파일이 있나"가 아니라 "내가 할 일이 남았나"를 물었기 때문이다.
  # 실측 — 08-05 10시 회차는 보고서 19607바이트를 만들고 push까지 끝냈는데 종료 코드 1로 신고돼,
  # 대표 화면에 빨간 경보가 떴다. 멀쩡한 자동화를 매일 들여다보게 만드는 거짓 경보다.
  PUB_WORDS=$(/usr/bin/wc -w < "${TODAY_KST}.md" | /usr/bin/tr -d ' ')
  echo "✅ ${TODAY_KST}.md 발행 확인 ($PUB_WORDS 단어) — claude가 커밋·push까지 마침" >> "$LOG_FILE"
else
  /usr/bin/osascript -e "display notification \"보고서 생성 실패 (claude exit $CLAUDE_EXIT). 로그: $LOG_FILE\" with title \"AI Daily Report\" subtitle \"⚠️ 확인 필요\" sound name \"Basso\""
  echo "❌ $TODAY_KST 보고서 파일이 생성되지 않음 (claude exit $CLAUDE_EXIT)" >> "$LOG_FILE"
  exit 1
fi

echo "===== 종료: $(date +"%H:%M:%S") =====" >> "$LOG_FILE"
