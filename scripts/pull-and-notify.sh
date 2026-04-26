#!/bin/bash
# AI Daily Report 자동 동기화 스크립트
# launchd가 매일 07:45 KST에 호출. Mac 잠자던 중이면 깨어날 때 자동 실행.

set -u
REPO_DIR="$HOME/Desktop/Claude-Core/ai-daily-report"
LOG_DIR="$HOME/Library/Logs/ai-daily-report"
LOG_FILE="$LOG_DIR/pull.log"
TODAY_KST=$(TZ=Asia/Seoul date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")

mkdir -p "$LOG_DIR"
echo "===== $TIMESTAMP =====" >> "$LOG_FILE"

cd "$REPO_DIR" || { echo "❌ repo 디렉토리 진입 실패" >> "$LOG_FILE"; exit 1; }

# git pull (PATH 명시 — launchd 환경 대응)
PULL_OUTPUT=$(/usr/bin/git pull origin main 2>&1)
PULL_EXIT=$?
echo "$PULL_OUTPUT" >> "$LOG_FILE"

if [ $PULL_EXIT -ne 0 ]; then
  /usr/bin/osascript -e "display notification \"git pull 실패. 로그 확인: $LOG_FILE\" with title \"AI Daily Report\" sound name \"Basso\""
  exit 1
fi

# 오늘자 보고서 파일 존재 확인
TODAY_FILE="$REPO_DIR/$TODAY_KST.md"
if [ -f "$TODAY_FILE" ]; then
  WORD_COUNT=$(/usr/bin/wc -w < "$TODAY_FILE" | /usr/bin/tr -d ' ')
  /usr/bin/osascript -e "display notification \"$TODAY_KST.md 도착 (${WORD_COUNT} 단어)\" with title \"📰 AI Daily Report\" subtitle \"오늘의 AI 동향이 준비되었습니다\" sound name \"Glass\""
  echo "✅ $TODAY_KST.md 동기화 완료 ($WORD_COUNT 단어)" >> "$LOG_FILE"
else
  # 보고서가 아직 없는 경우 (cloud routine 지연 또는 실패)
  /usr/bin/osascript -e "display notification \"오늘 보고서가 아직 도착하지 않음. 잠시 후 재시도되거나 routine 로그 확인 필요\" with title \"AI Daily Report\" subtitle \"⏳ 대기 중\""
  echo "⚠️  $TODAY_KST.md 아직 없음 — cloud routine 미완료 가능성" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
