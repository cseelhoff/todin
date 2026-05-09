#!/usr/bin/env bash
# Run all 52 snapshot tests sequentially, one at a time.
#
# Each snap runs as its own `odin test` invocation with FILTER_SNAP set,
# so:
#   - You see live progress (N/52, elapsed seconds, PASS/FAIL/SEGV) without
#     waiting for the whole 30+ min batch to complete.
#   - One failing snap doesn't stop the rest (the existing batch run halts
#     after the first segfault).
#   - Each snap's full log goes to /tmp/snap-NNNN.log for post-mortem.
#
# Usage:
#   ./run_all_snaps.sh                    # snaps 0001..0052
#   ./run_all_snaps.sh 0010 0020          # only snaps 0010..0020
#   FAIL_FAST=1 ./run_all_snaps.sh        # stop on first non-PASS
#
# Summary line goes to stdout; per-snap timing goes to /tmp/run-all-snaps-summary.txt.

set -u

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
RUN_SNAP="${REPO_ROOT}/run_snap.sh"
SUMMARY="/tmp/run-all-snaps-summary.txt"

START="${1:-1}"
END="${2:-52}"

if [[ ! -x "${RUN_SNAP}" ]]; then
    echo "ERROR: ${RUN_SNAP} not found or not executable" >&2
    exit 1
fi

# Truncate summary only on a "fresh full run" (start at 1). Subset
# invocations append so multi-batch runs (5 at a time) accumulate.
if [[ "${START}" == "1" || "${START}" == "0001" ]]; then
    : > "${SUMMARY}"
fi
total=$((END - START + 1))
pass=0
fail=0
segv=0
errors=0

# zero-pad %04d
for n in $(seq "${START}" "${END}"); do
    snap=$(printf "%04d" "$n")
    log="/tmp/snap-${snap}.log"
    printf "[%2d/%d] snap %s ... " "$((n - START + 1))" "${total}" "${snap}"
    SECONDS=0
    "${RUN_SNAP}" "${snap}" >"${log}" 2>&1
    status=$?
    elapsed=${SECONDS}

    # Classify outcome from the log.
    if grep -q "Segmentation_Fault\|Signal caught: Segmentation" "${log}"; then
        outcome="SEGV"
        segv=$((segv + 1))
    elif grep -qE "^Finished .*The test was successful|Results: 1 passed, 0 failed" "${log}"; then
        outcome="PASS"
        pass=$((pass + 1))
    elif grep -qE "FAILED:" "${log}"; then
        outcome="FAIL"
        fail=$((fail + 1))
    else
        outcome="ERROR(exit=${status})"
        errors=$((errors + 1))
    fi

    # First-line failure detail (truncated).
    detail=""
    if [[ "${outcome}" != "PASS" ]]; then
        detail=$(grep -oE "FAILED:.{0,120}|Signal caught:.{0,80}|Error:.{0,120}" "${log}" \
                 | head -1 | tr '\n' ' ')
    fi

    printf "%-4s  %3ds  %s\n" "${outcome}" "${elapsed}" "${detail}"
    printf "%s  %-4s  %3ds  %s\n" "${snap}" "${outcome}" "${elapsed}" "${detail}" >> "${SUMMARY}"

    if [[ -n "${FAIL_FAST:-}" && "${outcome}" != "PASS" ]]; then
        echo
        echo "FAIL_FAST: stopping after snap ${snap} (${outcome}). See ${log}."
        break
    fi
done

echo
echo "=================================================================="
echo "SUMMARY: ${pass} pass / ${fail} fail / ${segv} segv / ${errors} other"
echo "Range: ${START}..${END} (${total} snaps)"
echo "Per-snap timing in ${SUMMARY}"
echo "=================================================================="
