#!/bin/bash
#SBATCH --job-name=hpcq_full_gpu
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:30:00
#SBATCH --output=results/hpcq_full_gpu_%j.out
#SBATCH --error=results/hpcq_full_gpu_%j.err

set -euo pipefail
mkdir -p results/full_gpu_${SLURM_JOB_ID}
module load apptainer 2>/dev/null || true
IMAGE=${IMAGE:-hpcq-gpu.sif}
apptainer exec --nv --bind "$PWD":/workspace --pwd /workspace "$IMAGE" \
  python3 -m hpcq.run_suite \
    --output-dir results/full_gpu_${SLURM_JOB_ID} \
    --device auto \
    --matrix-size 2048 \
    --qiskit-qubits 18 \
    --qiskit-depth 6 \
    --include-pennylane \
    --include-energy
python3 -m hpcq.compare_results results/full_gpu_${SLURM_JOB_ID} \
  --csv results/full_gpu_${SLURM_JOB_ID}/summary.csv \
  --md results/full_gpu_${SLURM_JOB_ID}/summary.md || true
