#!/bin/bash
SCRIPT_DIR="/opt/gray_scan_project"
python3 "$SCRIPT_DIR/gray.py" "$@"


"$SCRIPT_DIR/run.sh" "$@"