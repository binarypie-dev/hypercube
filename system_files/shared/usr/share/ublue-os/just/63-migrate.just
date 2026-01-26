# vim: set ft=make :
# Hypercube system migration commands

# Run all pending system migrations
migrate:
    #!/usr/bin/bash
    set -uo pipefail

    MIGRATIONS_DIR="/usr/share/hypercube/migrations"
    STATE_DIR="/var/lib/hypercube/migrations"
    COMPLETED_FILE="$STATE_DIR/completed"

    log() { echo "[migrate] $*"; }
    warn() { echo "[migrate] WARNING: $*" >&2; }

    mkdir -p "$STATE_DIR"
    touch "$COMPLETED_FILE"

    if [[ ! -d "$MIGRATIONS_DIR" ]]; then
        log "No migrations directory found"
        exit 0
    fi

    shopt -s nullglob
    migrations=("$MIGRATIONS_DIR"/*.sh)

    if [[ ${#migrations[@]} -eq 0 ]]; then
        log "No migrations found"
        exit 0
    fi

    failed=0
    for migration in "${migrations[@]}"; do
        name=$(basename "$migration")

        if grep -qxF "$name" "$COMPLETED_FILE" 2>/dev/null; then
            continue
        fi

        log "Running: $name"
        if bash "$migration"; then
            echo "$name" >> "$COMPLETED_FILE"
            log "$name completed"
        else
            warn "$name FAILED - will retry next boot"
            ((failed++)) || true
        fi
    done

    if [[ $failed -gt 0 ]]; then
        warn "$failed migration(s) failed"
    fi

# List all migrations and their status
migrate-status:
    #!/usr/bin/bash
    set -euo pipefail

    MIGRATIONS_DIR="/usr/share/hypercube/migrations"
    STATE_DIR="/var/lib/hypercube/migrations"
    COMPLETED_FILE="$STATE_DIR/completed"

    mkdir -p "$STATE_DIR"
    touch "$COMPLETED_FILE"

    echo "Hypercube Migrations"
    echo "===================="
    echo ""

    pending=0
    completed=0

    shopt -s nullglob
    for migration in "$MIGRATIONS_DIR"/*.sh; do
        name=$(basename "$migration")
        if grep -qxF "$name" "$COMPLETED_FILE" 2>/dev/null; then
            echo "  [done]    $name"
            ((completed++)) || true
        else
            echo "  [pending] $name"
            ((pending++)) || true
        fi
    done

    echo ""
    echo "Total: $completed completed, $pending pending"

# Mark a migration as completed (after manual fix)
migrate-mark-done NAME:
    #!/usr/bin/bash
    set -euo pipefail

    MIGRATIONS_DIR="/usr/share/hypercube/migrations"
    STATE_DIR="/var/lib/hypercube/migrations"
    COMPLETED_FILE="$STATE_DIR/completed"
    NAME="{{ NAME }}"

    if [[ ! -f "$MIGRATIONS_DIR/$NAME" ]]; then
        echo "Error: Migration '$NAME' not found" >&2
        echo "Run 'ujust migrate-status' to see available migrations"
        exit 1
    fi

    mkdir -p "$STATE_DIR"
    touch "$COMPLETED_FILE"

    if grep -qxF "$NAME" "$COMPLETED_FILE" 2>/dev/null; then
        echo "Migration '$NAME' already marked as done"
    else
        echo "$NAME" >> "$COMPLETED_FILE"
        echo "Migration '$NAME' marked as done"
    fi

# Reset a migration to pending (will re-run on next boot)
migrate-reset NAME:
    #!/usr/bin/bash
    set -euo pipefail

    MIGRATIONS_DIR="/usr/share/hypercube/migrations"
    STATE_DIR="/var/lib/hypercube/migrations"
    COMPLETED_FILE="$STATE_DIR/completed"
    NAME="{{ NAME }}"

    if [[ ! -f "$MIGRATIONS_DIR/$NAME" ]]; then
        echo "Error: Migration '$NAME' not found" >&2
        echo "Run 'ujust migrate-status' to see available migrations"
        exit 1
    fi

    if grep -qxF "$NAME" "$COMPLETED_FILE" 2>/dev/null; then
        tmp=$(mktemp)
        grep -vxF "$NAME" "$COMPLETED_FILE" > "$tmp" || true
        sudo mv "$tmp" "$COMPLETED_FILE"
        echo "Migration '$NAME' reset to pending"
    else
        echo "Migration '$NAME' is already pending"
    fi

# Force re-run a specific migration now
migrate-rerun NAME:
    #!/usr/bin/bash
    set -euo pipefail

    MIGRATIONS_DIR="/usr/share/hypercube/migrations"
    STATE_DIR="/var/lib/hypercube/migrations"
    COMPLETED_FILE="$STATE_DIR/completed"
    NAME="{{ NAME }}"

    if [[ ! -f "$MIGRATIONS_DIR/$NAME" ]]; then
        echo "Error: Migration '$NAME' not found" >&2
        echo "Run 'ujust migrate-status' to see available migrations"
        exit 1
    fi

    mkdir -p "$STATE_DIR"
    touch "$COMPLETED_FILE"

    echo "Running migration: $NAME"
    if sudo bash "$MIGRATIONS_DIR/$NAME"; then
        if ! grep -qxF "$NAME" "$COMPLETED_FILE" 2>/dev/null; then
            echo "$NAME" >> "$COMPLETED_FILE"
        fi
        echo "Migration '$NAME' completed"
    else
        echo "Migration '$NAME' FAILED" >&2
        exit 1
    fi
