#!/usr/bin/env bash
set -euo pipefail
python -m pytest
python -m hpcq.run_suite --dry-run --output-dir results/validate_dry_run
python -m hpcq.hybrid_vqe --steps 40 --learning-rate 0.15 --output results/validate_dry_run/vqe.json
python -m hpcq.sysinfo --output results/validate_dry_run/system_report.json
python -m hpcq.compare_results results/validate_dry_run --csv results/validate_dry_run/summary.csv --md results/validate_dry_run/summary.md
