# HPC GPU Quantum Container Reference Project

This repository is a complete starter implementation for the thesis topic:

> Research of container solutions for HPC systems supporting GPU and Quantum (hybrid classical-quantum)

The project focuses on a practical stack:

```text
Slurm scheduler
    -> Apptainer container
        -> CUDA / PyTorch / Qiskit Aer GPU / PennyLane Lightning GPU / MPI
            -> GPU and quantum benchmark scripts
```

Docker is included only as a development/comparison path. The main HPC-native path is Apptainer.

---

## 1. Repository structure

```text
hpc-gpu-quantum-container/
├── containers/
│   ├── apptainer-gpu-qiskit.def
│   ├── apptainer-cudaq.def
│   └── Dockerfile.gpu
├── src/hpcq/
│   ├── gpu_check.py
│   ├── torch_bench.py
│   ├── qiskit_bench.py
│   ├── pennylane_bench.py
│   ├── mpi_hello.py
│   ├── run_suite.py
│   └── result.py
├── tests/
├── slurm/
├── benchmarks/
├── docs/
├── requirements-cpu.txt
├── requirements-gpu-cu12.txt
├── pyproject.toml
└── Makefile
```

---

## 2. What this code proves

This project demonstrates that a containerized HPC workflow can:

1. Detect NVIDIA GPUs inside the container.
2. Run a PyTorch CUDA benchmark.
3. Run a Qiskit Aer quantum-circuit simulation.
4. Run an optional PennyLane Lightning GPU benchmark.
5. Run a simple MPI job inside a container.
6. Submit the workflow through Slurm using `sbatch`.
7. Export benchmark outputs as JSON/JSONL for later report writing.

---

## 3. Local CPU test first

Use this step even if you do not have GPU yet.

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements-cpu.txt
python -m pip install -e .
python -m pytest
python -m hpcq.run_suite --dry-run --output-dir results/dry_run
```

Optional CPU benchmark:

```bash
bash benchmarks/run_local_cpu.sh
```

---

## 4. Build Apptainer image

On an HPC login/build node with Apptainer:

```bash
apptainer build hpcq-gpu.sif containers/apptainer-gpu-qiskit.def
```

If the cluster does not allow local builds, use a build server or ask the admin for the recommended Apptainer build method.

---

## 5. Run Apptainer with GPU

```bash
apptainer exec --nv --bind "$PWD":/workspace --pwd /workspace hpcq-gpu.sif \
  python3 -m hpcq.gpu_check --output results/gpu_check.json
```

Run the full suite:

```bash
bash benchmarks/run_local_apptainer.sh hpcq-gpu.sif results/local_apptainer
```

Expected sign of success:

```text
"cuda_available": true
"device": "cuda"
"qiskit_aer": ok
```

---

## 6. Run through Slurm

Edit the Slurm partition names in `slurm/run_gpu_qiskit.sbatch` if your cluster does not use `gpu`.

```bash
mkdir -p results
sbatch slurm/run_gpu_qiskit.sbatch
```

Check output:

```bash
ls results/
cat results/hpcq_gpu_qiskit_<JOBID>.out
```

For MPI:

```bash
sbatch slurm/run_mpi_apptainer.sbatch
```

---

## 7. Docker comparison path

Build:

```bash
docker build -t hpcq-gpu:dev -f containers/Dockerfile.gpu .
```

Run:

```bash
docker run --rm --gpus all -v "$PWD":/workspace hpcq-gpu:dev \
  python3 -m hpcq.run_suite --output-dir results/docker --device auto
```

Docker requires the NVIDIA Container Toolkit on the host for GPU access.

---

## 8. Important compatibility notes

1. `qiskit-aer-gpu` is intended for CUDA-capable environments. If GPU installation fails, use CPU mode with `qiskit-aer` for development.
2. `pennylane-lightning-gpu` requires CUDA/cuQuantum-compatible libraries.
3. The container uses CUDA 12.4.1. If your cluster driver is old, choose a CUDA image compatible with the host driver.
4. In real HPC, the NVIDIA kernel driver is normally on the host. The container holds user-space libraries and Python packages.
5. Do not assume your cluster partition is named `gpu`; check with `sinfo`.

---

## 9. Minimal experimental plan for the thesis

| Experiment | Command | Output |
|---|---|---|
| GPU visibility | `python -m hpcq.gpu_check` | `gpu_check.json` |
| AI workload | `python -m hpcq.torch_bench` | `torch_matmul.json` |
| Quantum workload | `python -m hpcq.qiskit_bench` | `qiskit_aer.json` |
| Slurm integration | `sbatch slurm/run_gpu_qiskit.sbatch` | Slurm log + JSON |
| MPI container | `sbatch slurm/run_mpi_apptainer.sbatch` | `mpi_hello.json` |
| Docker comparison | `docker run --gpus all ...` | Docker benchmark JSON |

---

## 10. Suggested report claim

A safe claim for the thesis is:

> This project implements and evaluates a reproducible Apptainer-based container workflow for GPU-accelerated AI and quantum simulation workloads on an HPC-style environment. The workflow integrates CUDA, Python scientific libraries, Qiskit/PennyLane quantum simulators, MPI, and Slurm batch execution. Docker is provided as a comparison/development path, while Apptainer is used as the main HPC-native runtime.

---

## 11. Troubleshooting

### `cuda_available` is false

Check:

```bash
nvidia-smi
apptainer exec --nv hpcq-gpu.sif nvidia-smi
```

If host `nvidia-smi` fails, the issue is host driver or GPU allocation, not the container.

### Slurm says no GPU available

Check:

```bash
sinfo
scontrol show nodes
```

Your cluster may use a different partition or GRES name.

### Qiskit GPU fails but CPU works

Run:

```bash
python3 -m hpcq.qiskit_bench --device cpu --n-qubits 8 --depth 2
```

Then debug the CUDA/Qiskit package compatibility separately.

### Apptainer cannot find your code

Use the bind mount:

```bash
apptainer exec --bind "$PWD":/workspace --pwd /workspace hpcq-gpu.sif python3 -m hpcq.run_suite --dry-run
```

---

## 12. References to read before writing the report

- Apptainer User Guide: GPU support and definition files.
- Slurm documentation: containers, `sbatch`, and GPU/GRES scheduling.
- NVIDIA Container Toolkit documentation.
- Qiskit Aer documentation for GPU/MPI simulation.
- PennyLane Lightning GPU documentation.
- NVIDIA CUDA-Q documentation.
