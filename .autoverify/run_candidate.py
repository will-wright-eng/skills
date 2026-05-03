#!/usr/bin/env python3
"""Project-specific verifier wrapper.

Implement this file after copying `.autoverify/` into a target repo.

The script must evaluate the current working tree and print JSON matching
`.autoverify/result.schema.json`.
"""

from __future__ import annotations

import json
import sys
from typing import Any


def result(
    *,
    valid: bool,
    score: float | None,
    metric_name: str,
    objective: str,
    status: str,
    metrics: dict[str, Any] | None = None,
    artifacts: dict[str, str] | None = None,
) -> dict[str, Any]:
    return {
        "valid": valid,
        "score": score,
        "metric_name": metric_name,
        "objective": objective,
        "status": status,
        "metrics": metrics or {},
        "artifacts": artifacts or {},
    }


def main() -> int:
    # TODO: Replace this stub with the target repo's verifier.
    # Typical implementation:
    # 1. Run tests and benchmarks with a timeout.
    # 2. Capture logs under `.autoverify/runs/`.
    # 3. Parse the primary metric.
    # 4. Print normalized JSON.
    payload = result(
        valid=False,
        score=None,
        metric_name="TODO",
        objective="minimize",
        status="unimplemented",
        metrics={},
        artifacts={},
    )
    print(json.dumps(payload, sort_keys=True))
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
