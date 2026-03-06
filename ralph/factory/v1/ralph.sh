#!/bin/bash
# Ralph Dark Factory - Mission Control macOS App
# Usage: ./ralph/factory/v1/ralph.sh
# Monitor: tail -f ralph/factory/v1/activity.md

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$FACTORY_DIR/../../.." && pwd)"
PLAN_FILE="$FACTORY_DIR/plan.md"
PROMPT_FILE="$FACTORY_DIR/prompt.md"
ACTIVITY_FILE="$FACTORY_DIR/activity.md"

MAX_ITERATIONS=50
CONSECUTIVE_FAILURES=0
MAX_CONSECUTIVE_FAILURES=3
ITERATION=0

DEFAULT_MODEL="claude-sonnet-4-6"
OPUS_MODEL="claude-opus-4-6"
HAIKU_MODEL="claude-haiku-4-5-20251001"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

get_model_for_task() {
    local task_id="$1"
    local model_hint
    model_hint=$(python3 -c "
import json, sys
with open('$PLAN_FILE', 'r') as f:
    content = f.read()
# Extract JSON block from plan.md
import re
match = re.search(r'\`\`\`json\s*(\[.*?\])\s*\`\`\`', content, re.DOTALL)
if match:
    tasks = json.loads(match.group(1))
    for t in tasks:
        if t['id'] == '$task_id':
            print(t.get('model', 'sonnet'))
            sys.exit(0)
print('sonnet')
" 2>/dev/null || echo "sonnet")

    case "$model_hint" in
        opus)  echo "$OPUS_MODEL" ;;
        haiku) echo "$HAIKU_MODEL" ;;
        *)     echo "$DEFAULT_MODEL" ;;
    esac
}

get_next_task() {
    python3 -c "
import json, re
with open('$PLAN_FILE', 'r') as f:
    content = f.read()
match = re.search(r'\`\`\`json\s*(\[.*?\])\s*\`\`\`', content, re.DOTALL)
if match:
    tasks = json.loads(match.group(1))
    for t in tasks:
        if t['status'] == 'pending':
            print(t['id'])
            exit(0)
print('DONE')
" 2>/dev/null || echo "ERROR"
}

log "Ralph Dark Factory starting"
log "Project root: $PROJECT_ROOT"
log "Max iterations: $MAX_ITERATIONS"
log ""

cd "$PROJECT_ROOT"

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))

    NEXT_TASK=$(get_next_task)

    if [ "$NEXT_TASK" = "DONE" ]; then
        log "All tasks completed! Exiting."
        break
    fi

    if [ "$NEXT_TASK" = "ERROR" ]; then
        log "ERROR: Could not parse plan.md"
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
        if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
            log "FATAL: $MAX_CONSECUTIVE_FAILURES consecutive failures. Stopping."
            exit 1
        fi
        continue
    fi

    MODEL=$(get_model_for_task "$NEXT_TASK")
    log "=== Iteration $ITERATION | Task: $NEXT_TASK | Model: $MODEL ==="

    START_TIME=$(date +%s)

    if claude --model "$MODEL" --print --dangerously-skip-permissions \
        "$(cat "$PROMPT_FILE")

Current task to implement: $NEXT_TASK

Read the plan at $PLAN_FILE to get the full task description, then implement it following all instructions above." \
        2>&1 | tee "/tmp/ralph-iteration-$ITERATION.log"; then

        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))

        # Check if task was actually completed (status changed in plan)
        CURRENT_STATUS=$(python3 -c "
import json, re
with open('$PLAN_FILE', 'r') as f:
    content = f.read()
match = re.search(r'\`\`\`json\s*(\[.*?\])\s*\`\`\`', content, re.DOTALL)
if match:
    tasks = json.loads(match.group(1))
    for t in tasks:
        if t['id'] == '$NEXT_TASK':
            print(t['status'])
            exit(0)
print('unknown')
" 2>/dev/null || echo "unknown")

        if [ "$CURRENT_STATUS" = "completed" ]; then
            log "Task $NEXT_TASK completed in ${DURATION}s"
            echo "| $ITERATION | $NEXT_TASK | completed | ${DURATION}s | |" >> "$ACTIVITY_FILE"
            CONSECUTIVE_FAILURES=0
        else
            log "Task $NEXT_TASK did not complete (status: $CURRENT_STATUS)"
            echo "| $ITERATION | $NEXT_TASK | incomplete | ${DURATION}s | Agent did not mark complete |" >> "$ACTIVITY_FILE"
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
        fi
    else
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        log "Task $NEXT_TASK failed (exit code: $?)"
        echo "| $ITERATION | $NEXT_TASK | failed | ${DURATION}s | Non-zero exit |" >> "$ACTIVITY_FILE"
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    fi

    if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
        log "FATAL: $MAX_CONSECUTIVE_FAILURES consecutive failures. Stopping."
        exit 1
    fi

    log ""
done

log "Ralph Dark Factory finished after $ITERATION iterations"
