#!/usr/bin/env bash
# Last stage: summary and exit status. Sourced after every other stage.

echo
if ((failures == 0)); then
    echo "All smoke checks passed"
else
    echo "${failures} smoke check(s) failed"
fi
exit $((failures > 0))
