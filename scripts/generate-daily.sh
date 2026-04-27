#!/bin/bash
# AI Daily Report 생성 스크립트
# launchd가 매일 07:30 KST에 호출.
# Mac이 잠자던 중이면 깨어날 때 자동 실행 (StartCalendarInterval 기본 동작).

set -u
REPO_DIR="$HOME/Desktop/Claude-Core/ai-daily-report"
LOG_DIR="$HOME/Library/Logs/ai-daily-report"
LOG_FILE="$LOG_DIR/generate.log"
PROMPT_FILE="$REPO_DIR/scripts/daily-prompt.md"

mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
TODAY_KST=$(TZ=Asia/Seoul date +%Y-%m-%d)

echo "" >> "$LOG_FILE"
echo "===== $TIMESTAMP — 보고서 생성 시작 =====" >> "$LOG_FILE"

cd "$REPO_DIR" || { echo "❌ repo 진입 실패" >> "$LOG_FILE"; exit 1; }

# launchd는 PATH가 최소 — claude CLI 위치 명시
CLAUDE_BIN="/Users/jungmo/.local/bin/claude"
if [ ! -x "$CLAUDE_BIN" ]; then
  echo "❌ claude CLI 없음: $CLAUDE_BIN" >> "$LOG_FILE"
  /usr/bin/osascript -e "display notification \"claude CLI 경로 오류\" with title \"AI Daily Report\" sound name \"Basso\""
  exit 1
fi

# Claude 호출 (헤드리스, 권한 체크 우회, 비용 상한 $1)
"$CLAUDE_BIN" \
  -p "$(cat "$PROMPT_FILE")" \
  --permission-mode bypassPermissions \
  --max-budget-usd 1.0 \
  --model claude-sonnet-4-6 \
  >> "$LOG_FILE" 2>&1

CLAUDE_EXIT=$?
echo "" >> "$LOG_FILE"
echo "[claude exit code: $CLAUDE_EXIT]" >> "$LOG_FILE"

# 결과 검증
TODAY_FILE="$REPO_DIR/${TODAY_KST}.md"
RERUN_FILE="$REPO_DIR/${TODAY_KST}-rerun.md"

if [ -f "$TODAY_FILE" ] || [ -f "$RERUN_FILE" ]; then
  ACTUAL_FILE=$([ -f "$RERUN_FILE" ] && echo "$RERUN_FILE" || echo "$TODAY_FILE")
  WORD_COUNT=$(/usr/bin/wc -w < "$ACTUAL_FILE" | /usr/bin/tr -d ' ')
  /usr/bin/osascript -e "display notification \"$(basename "$ACTUAL_FILE") 생성 완료 (${WORD_COUNT} 단어)\" with title \"📰 AI Daily Report\" subtitle \"오늘의 AI 동향이 준비되었습니다\" sound name \"Glass\""
  echo "✅ $(basename "$ACTUAL_FILE") 생성 ($WORD_COUNT 단어)" >> "$LOG_FILE"
else
  /usr/bin/osascript -e "display notification \"보고서 생성 실패. 로그: $LOG_FILE\" with title \"AI Daily Report\" subtitle \"⚠️ 확인 필요\" sound name \"Basso\""
  echo "❌ $TODAY_KST 보고서 파일이 생성되지 않음" >> "$LOG_FILE"
  exit 1
fi

echo "===== 종료: $(date +"%H:%M:%S") =====" >> "$LOG_FILE"
