#!/bin/bash

#SBATCH -p gpu
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH -t 00:59:00

#SBATCH --output=GROMACS.GPU.%j.out
#SBATCH --error=GROMACS.GPU.%j.err
#SBATCH --job-name=GROMACS.GPU

module load 2022
module load GROMACS/2021.6-foss-2022a-CUDA-11.7.0

# ENV variable needed to report "loops" to the EARDB
# export EARL_REPORT_LOOPS=1

# location of the binaries for the course
PROJECT_DIR=/projects/0/energy-course

# The different simulation domains available

# 20K atom system  --> Crambin_benchmark.tpr
# 1.4M atom system --> hEGFRDimer_benchmark.tpr
# 3M atom system   --> hEGFRDimerSmallerPL_benchmark.tpr

#GPU run
srun --ntasks=3 --cpus-per-task=6 gmx_mpi mdrun -s $PROJECT_DIR/GROMACS/hEGFRDimerSmallerPL_benchmark.tpr -nb gpu