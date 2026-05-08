#!/usr/bin/env bash
set -u

BASE_URL="${1:-http://localhost:8000}"
PASS=0
FAIL=0
FAILED_TESTS=()

log_pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
log_fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); FAILED_TESTS+=("$1"); }
log_info() { echo "[INFO] $1"; }

log_info "Waiting for API at $BASE_URL ..."
for i in $(seq 1 30); do
  if curl -fsS "$BASE_URL/health" > /dev/null 2>&1; then
    log_info "API is reachable"
    break
  fi
  sleep 2
done

TEST="GET /health returns 200 with status=healthy"
RESP=$(curl -s -o /tmp/body -w "%{http_code}" "$BASE_URL/health")
BODY=$(cat /tmp/body)
if [ "$RESP" = "200" ] && echo "$BODY" | grep -q '"status":"healthy"'; then
  log_pass "$TEST"
else
  log_fail "$TEST (got HTTP $RESP, body: $BODY)"
fi

TEST="POST /services creates a service"
SVC_NAME="testsvc-$(date +%s)"
RESP=$(curl -s -o /tmp/body -w "%{http_code}" -X POST "$BASE_URL/services" -H "Content-Type: application/json" -d "{\"name\":\"$SVC_NAME\",\"url\":\"https://example.com\"}")
BODY=$(cat /tmp/body)
if [ "$RESP" = "200" ] && echo "$BODY" | grep -q '"id"'; then
  log_pass "$TEST"
else
  log_fail "$TEST (got HTTP $RESP, body: $BODY)"
fi

TEST="POST /services duplicate returns 409"
RESP=$(curl -s -o /tmp/body -w "%{http_code}" -X POST "$BASE_URL/services" -H "Content-Type: application/json" -d "{\"name\":\"$SVC_NAME\",\"url\":\"https://example.com\"}")
BODY=$(cat /tmp/body)
if [ "$RESP" = "409" ]; then
  log_pass "$TEST"
else
  log_fail "$TEST (got HTTP $RESP, body: $BODY)"
fi

TEST="GET /services returns array including our service"
RESP=$(curl -s -o /tmp/body -w "%{http_code}" "$BASE_URL/services")
BODY=$(cat /tmp/body)
if [ "$RESP" = "200" ] && echo "$BODY" | grep -q "$SVC_NAME"; then
  log_pass "$TEST"
else
  log_fail "$TEST (got HTTP $RESP, body: $BODY)"
fi

TEST="POST /incidents creates an incident"
RESP=$(curl -s -o /tmp/body -w "%{http_code}" -X POST "$BASE_URL/incidents" -H "Content-Type: application/json" -d "{\"service_name\":\"$SVC_NAME\",\"title\":\"Test outage\",\"description\":\"sim\",\"severity\":\"minor\"}")
BODY=$(cat /tmp/body)
if [ "$RESP" = "200" ] && echo "$BODY" | grep -q '"status":"investigating"'; then
  log_pass "$TEST"
else
  log_fail "$TEST (got HTTP $RESP, body: $BODY)"
fi

TEST="GET /incidents returns array including our incident"
RESP=$(curl -s -o /tmp/body -w "%{http_code}" "$BASE_URL/incidents")
BODY=$(cat /tmp/body)
if [ "$RESP" = "200" ] && echo "$BODY" | grep -q "Test outage"; then
  log_pass "$TEST"
else
  log_fail "$TEST (got HTTP $RESP, body: $BODY)"
fi

echo ""
echo "=========================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "=========================================="

if [ "$FAIL" -ne 0 ]; then
  echo "Failed tests:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "  - $t"
  done
  exit 1
fi

exit 0