#!/bin/bash

#SBATCH -p gpu
#SBATCH --gpus-per-node=1
#SBATCH -t 00:15:00
#SBATCH --cpus-per-task=4
#SBATCH --exclusive

#SBATCH --output=PyTorch.%j.out
#SBATCH --error=PyTorch.%j.err
#SBATCH --job-name=PT

module load 2023
module load PyTorch/2.1.2-foss-2023a-CUDA-12.1.1

# ENV variable needed to report "loops" to the EARDB
# export EARL_REPORT_LOOPS=1

# location of the binaries for the course
PROJECT_DIR=/projects/0/energy-course

# Options for Benchmark
# --fp16-allreduce      use fp16 compression during allreduce (default: False)
# --model MODEL         model to benchmark (default: resnet50)
# --batch-size BATCH_SIZE
#                       input batch size (default: 32)
# --num-warmup-batches NUM_WARMUP_BATCHES
#                       number of warm-up batches that don't count towards benchmark (default: 10)
# --num-batches-per-iter NUM_BATCHES_PER_ITER
#                       number of batches per benchmark iteration (default: 10)
# --num-iters NUM_ITERS
#                       number of benchmark iterations (default: 10)
# --no-cuda             disables CUDA training (default: False)
# --use-adasum          use adasum algorithm to do reduction (default: False)
# --use-horovod
# --use-ddp
# --use-amp             Use PyTorch Automatic Mixed Precision (AMP) (default: False)


# Resnet50 
srun python $PROJECT_DIR/PyTorch/pytorch_syntethic_benchmark.py --batch-size=32 --model=resnet50

# Resnet50 with mixed precision
srun python $PROJECT_DIR/PyTorch/pytorch_syntethic_benchmark.py --batch-size=32 --model=resnet50 --use-amp

# Resnet101 (larger model) 
srun python $PROJECT_DIR/PyTorch/pytorch_syntethic_benchmark.py --batch-size=32 --model=resnet101

# Resnet101 (larger model) with mixed precision
srun python $PROJECT_DIR/PyTorch/pytorch_syntethic_benchmark.py --batch-size=32 --model=resnet101 --use-amp
