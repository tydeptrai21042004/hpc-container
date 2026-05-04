from __future__ import annotations

import argparse
from pathlib import Path

from hpcq.gpu_check import run_gpu_check
from hpcq.qiskit_bench import run_qiskit_benchmark
from hpcq.result import BenchmarkResult, append_jsonl, write_json
from hpcq.torch_bench import run_torch_matmul_benchmark


def run_suite(
    output_dir: str | Path = "results",
    device: str = "auto",
    matrix_size: int = 2048,
    qiskit_qubits: int = 18,
    qiskit_depth: int = 6,
    dry_run: bool = False,
) -> list[BenchmarkResult]:
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)
    if dry_run:
        result = BenchmarkResult(
            name="dry_run",
            ok=True,
            metrics={
                "output_dir": str(out),
                "device": device,
                "matrix_size": matrix_size,
                "qiskit_qubits": qiskit_qubits,
                "qiskit_depth": qiskit_depth,
            },
        )
        write_json(result, out / "dry_run.json")
        append_jsonl(result, out / "suite.jsonl")
        return [result]

    results = [
        run_gpu_check(),
        run_torch_matmul_benchmark(size=matrix_size, iterations=5, warmup=1, device_choice="auto" if device == "auto" else ("cuda" if device == "gpu" else "cpu")),
        run_qiskit_benchmark(n_qubits=qiskit_qubits, depth=qiskit_depth, shots=512, device_choice="auto" if device == "auto" else ("gpu" if device == "gpu" else "cpu")),
    ]
    for result in results:
        write_json(result, out / f"{result.name}.json")
        append_jsonl(result, out / "suite.jsonl")
    return results


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the basic HPC GPU Quantum benchmark suite.")
    parser.add_argument("--output-dir", default="results")
    parser.add_argument("--device", choices=["auto", "cpu", "gpu"], default="auto")
    parser.add_argument("--matrix-size", type=int, default=2048)
    parser.add_argument("--qiskit-qubits", type=int, default=18)
    parser.add_argument("--qiskit-depth", type=int, default=6)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    results = run_suite(
        output_dir=args.output_dir,
        device=args.device,
        matrix_size=args.matrix_size,
        qiskit_qubits=args.qiskit_qubits,
        qiskit_depth=args.qiskit_depth,
        dry_run=args.dry_run,
    )
    for result in results:
        print(result.to_json())
    return 0 if all(r.ok for r in results) else 2


if __name__ == "__main__":
    raise SystemExit(main())
