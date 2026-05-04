#!/bin/bash
#SBATCH --job-name=hpcq_nccl
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=00:15:00
#SBATCH --output=results/hpcq_nccl_%j.out
#SBATCH --error=results/hpcq_nccl_%j.err

set -euo pipefail
mkdir -p results/nccl_${SLURM_JOB_ID}
module load apptainer 2>/dev/null || true
IMAGE=${IMAGE:-hpcq-gpu.sif}
MASTER_PORT=${MASTER_PORT:-29501}
srun apptainer exec --nv --bind "$PWD":/workspace --pwd /workspace "$IMAGE" \
  python3 -m torch.distributed.run \
    --nnodes=1 \
    --nproc_per_node=2 \
    --master_port=${MASTER_PORT} \
    -m hpcq.nccl_bench \
    --backend nccl \
    --elements 1000000 \
    --iterations 20 \
    --output results/nccl_${SLURM_JOB_ID}/nccl_rank0.json
