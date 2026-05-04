IMAGE ?= hpcq-gpu.sif
DEF ?= containers/apptainer-gpu-qiskit.def
OUT ?= results

.PHONY: test build run-gpu run-suite docker-build docker-run clean

test:
	python -m pytest

build:
	apptainer build $(IMAGE) $(DEF)

run-gpu:
	apptainer exec --nv --bind $(PWD):/workspace $(IMAGE) python -m hpcq.gpu_check --output $(OUT)/gpu_check.json

run-suite:
	apptainer exec --nv --bind $(PWD):/workspace $(IMAGE) python -m hpcq.run_suite --output-dir $(OUT) --device auto

docker-build:
	docker build -t hpcq-gpu:dev -f containers/Dockerfile.gpu .

docker-run:
	docker run --rm --gpus all -v $(PWD):/workspace hpcq-gpu:dev python -m hpcq.run_suite --output-dir results --device auto

clean:
	rm -rf results/*.json results/*.jsonl results/*.out results/*.err .pytest_cache build dist *.egg-info
