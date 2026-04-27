#!/usr/bin/env python3
"""
GitHub Contents API로 파일 업로드/갱신.
git push가 막힌 환경(Anthropic CCR 프록시 등)에서 사용.

사용 예:
    python3 scripts/upload-via-api.py \\
      --token "$PAT" \\
      --repo jmjung950312-cmd/ai-daily-report \\
      --message "AI 일일 보고서 추가: 2026-04-28" \\
      --file 2026-04-28.md \\
      --file INDEX.md
"""

import argparse
import base64
import json
import sys
import urllib.error
import urllib.request
from typing import Optional


def get_existing_sha(repo: str, path: str, branch: str, token: str) -> Optional[str]:
    """기존 파일의 SHA 조회. 없으면 None."""
    url = f"https://api.github.com/repos/{repo}/contents/{path}?ref={branch}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
        },
    )
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())["sha"]
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def put_file(
    repo: str,
    local_path: str,
    remote_path: str,
    branch: str,
    token: str,
    message: str,
) -> bool:
    """파일을 PUT. 기존 파일이면 SHA 제공, 새 파일이면 SHA 생략."""
    sha = get_existing_sha(repo, remote_path, branch, token)

    with open(local_path, "rb") as f:
        content_b64 = base64.b64encode(f.read()).decode()

    payload = {
        "message": message,
        "content": content_b64,
        "branch": branch,
    }
    if sha:
        payload["sha"] = sha

    url = f"https://api.github.com/repos/{repo}/contents/{remote_path}"
    req = urllib.request.Request(
        url,
        method="PUT",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
        },
        data=json.dumps(payload).encode(),
    )
    try:
        with urllib.request.urlopen(req) as r:
            result = json.loads(r.read())
            commit_sha = result["commit"]["sha"][:7]
            action = "update" if sha else "create"
            print(f"✅ {remote_path}: {commit_sha} ({action})")
            return True
    except urllib.error.HTTPError as e:
        body = e.read().decode()[:300]
        print(f"❌ {remote_path}: HTTP {e.code} — {body}", file=sys.stderr)
        return False


def main() -> None:
    ap = argparse.ArgumentParser(description="GitHub Contents API로 파일 업로드")
    ap.add_argument("--token", required=True, help="GitHub PAT")
    ap.add_argument("--repo", required=True, help="owner/name 형식")
    ap.add_argument("--branch", default="main")
    ap.add_argument("--message", required=True, help="공통 commit 메시지")
    ap.add_argument(
        "--file",
        action="append",
        required=True,
        help="로컬 파일 경로. 'local:remote' 형식으로 원격 경로 다르게 지정 가능",
    )
    args = ap.parse_args()

    success = True
    for spec in args.file:
        if ":" in spec:
            local, remote = spec.split(":", 1)
        else:
            local = remote = spec
        if not put_file(args.repo, local, remote, args.branch, args.token, args.message):
            success = False

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
