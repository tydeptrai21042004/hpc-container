#!/bin/bash
#SBATCH --job-name=hpcq_mpi_bench
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --output=results/hpcq_mpi_%j.out
#SBATCH --error=results/hpcq_mpi_%j.err

set -euo pipefail
mkdir -p results/mpi_${SLURM_JOB_ID}
module load apptainer 2>/dev/null || true
IMAGE=${IMAGE:-hpcq-gpu.sif}
srun apptainer exec --bind "$PWD":/workspace --pwd /workspace "$IMAGE" \
  python3 -m hpcq.mpi_bench --iterations 100 --payload-bytes 1048576 \
  --output results/mpi_${SLURM_JOB_ID}/mpi_microbench.json
