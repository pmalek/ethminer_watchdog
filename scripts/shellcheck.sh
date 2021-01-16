#!/usr/bin/env bash

set -e

echo "Checking bash scripts with shellcheck..."

for file in 'scripts/shellcheck.sh' 'ethminer_watchdog.sh'; do
    # Run tests in their own context
    echo "Checking ${file} with shellcheck"
    shellcheck --enable all "${file}"
done

