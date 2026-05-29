#!/bin/bash
# AI Daily Report 자동 동기화 + 슬랙 발송 스크립트
# launchd가 매일 09:00 KST에 호출. Mac 잠자던 중이면 깨어날 때 자동 실행.
#
# 2026-05-29 4-3 세션 수정 (정모님 "제대로 붙여줘"):
#   1. 슬랙 발송 추가 — 기존엔 osascript(맥 데스크탑 알림)만 있고 슬랙은 미구현이었음.
#      "notify"라는 이름을 맥 알림으로 구현해놓고 슬랙으로 착각한 게 루트 cause.
#   2. 타이밍 09:00로 늦춤 — generate-daily(07:30 시작, 실제 완성 08:14)보다
#      pull(07:45)이 먼저 달려서 빈손이던 race condition fix.
#   3. STATUS 연동은 jarvis-session-start.py(4-1 신설)에 이미 있음 — 타이밍 fix로 최신 파일 참조됨.

set -u
REPO_DIR="$HOME/Claude/Claude-Core/ai-daily-report"
LOG_DIR="$HOME/Library/Logs/ai-daily-report"
LOG_FILE="$LOG_DIR/pull.log"
SLACK_NOTIFY="$HOME/.claude/slack/notify.sh"
SLACK_CHANNEL="ops"   # 매일 08:00 아침 할일과 같은 채널에 모음
TODAY_KST=$(TZ=Asia/Seoul date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")

mkdir -p "$LOG_DIR"
echo "===== $TIMESTAMP =====" >> "$LOG_FILE"

cd "$REPO_DIR" || { echo "❌ repo 디렉토리 진입 실패" >> "$LOG_FILE"; exit 1; }

# 슬랙 발송 헬퍼 — notify.sh 있으면 발송, 없으면 로그만
send_slack() {
  local msg="$1"
  if [ -x "$SLACK_NOTIFY" ]; then
    if "$SLACK_NOTIFY" "$SLACK_CHANNEL" "$msg" >> "$LOG_FILE" 2>&1; then
      echo "📨 슬랙 발송 성공 (#$SLACK_CHANNEL)" >> "$LOG_FILE"
    else
      echo "⚠️  슬랙 발송 실패 — notify.sh 로그 확인" >> "$LOG_FILE"
    fi
  else
    echo "⚠️  슬랙 notify.sh 없음/실행불가: $SLACK_NOTIFY" >> "$LOG_FILE"
  fi
}

# git pull (PATH 명시 — launchd 환경 대응)
PULL_OUTPUT=$(/usr/bin/git pull origin main 2>&1)
PULL_EXIT=$?
echo "$PULL_OUTPUT" >> "$LOG_FILE"

if [ $PULL_EXIT -ne 0 ]; then
  /usr/bin/osascript -e "display notification \"git pull 실패. 로그 확인: $LOG_FILE\" with title \"AI Daily Report\" sound name \"Basso\""
  send_slack "⚠️ AI Daily Report — git pull 실패 ($TODAY_KST). 로그 확인 필요: $LOG_FILE"
  exit 1
fi

# 오늘자 보고서 파일 존재 확인
TODAY_FILE="$REPO_DIR/$TODAY_KST.md"
if [ -f "$TODAY_FILE" ]; then
  WORD_COUNT=$(/usr/bin/wc -w < "$TODAY_FILE" | /usr/bin/tr -d ' ')

  # 리포트에서 "오늘의 한 줄" 요약 추출 (## 🎯 다음 비어있지 않은 줄)
  ONE_LINER=$(awk '/^## .*오늘의 한 줄/{f=1; next} f && NF {print; exit}' "$TODAY_FILE")
  # 헤드라인(## 섹션 제목) 상위 5개 추출
  HEADLINES=$(grep -E '^## ' "$TODAY_FILE" | head -5 | sed 's/^## /  • /')

  # 맥 데스크탑 알림
  /usr/bin/osascript -e "display notification \"$TODAY_KST.md 도착 (${WORD_COUNT} 단어)\" with title \"📰 AI Daily Report\" subtitle \"오늘의 AI 동향이 준비되었습니다\" sound name \"Glass\""

  # 슬랙 발송 (제목 + 한 줄 요약 + 헤드라인)
  SLACK_MSG="📰 *AI Daily — ${TODAY_KST}* (${WORD_COUNT} 단어)

${ONE_LINER}

${HEADLINES}

전문: ~/Claude/Claude-Core/ai-daily-report/${TODAY_KST}.md"
  send_slack "$SLACK_MSG"

  echo "✅ $TODAY_KST.md 동기화 + 슬랙 발송 완료 ($WORD_COUNT 단어)" >> "$LOG_FILE"
else
  # 보고서가 아직 없는 경우 (cloud routine 지연 또는 실패)
  /usr/bin/osascript -e "display notification \"오늘 보고서가 아직 도착하지 않음. routine 로그 확인 필요\" with title \"AI Daily Report\" subtitle \"⏳ 대기 중\""
  send_slack "⏳ AI Daily Report — $TODAY_KST 보고서가 아직 안 왔어요. generate 로그 확인 필요: $LOG_DIR/generate.log"
  echo "⚠️  $TODAY_KST.md 아직 없음 — cloud routine 미완료 가능성" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
