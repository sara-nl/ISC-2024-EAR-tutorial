#!/bin/bash


#SBATCH -p gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=8
#SBATCH --gpus-per-node=4
#SBATCH -t 00:59:00

#SBATCH --output=GROMACS.GPU.SING.%j.out
#SBATCH --error=GROMACS.GPU.SING.%j.err
#SBATCH --job-name=GROMACS.GPU.SING

module load ear

#Benchmarlk taken from NVIDIA's site 
# https://catalog.ngc.nvidia.com/orgs/hpc/containers/gromacs

## Export EAR env to GROMACS image
# BIND EAR paths
export APPTAINER_BIND="$EAR_INSTALL_PATH:$EAR_INSTALL_PATH:ro,$EAR_TMP:$EAR_TMP:rw"

# Define APPTAINER/EAR env vars
export APPTAINERENV_EAR_INSTALL_PATH=$EAR_INSTALL_PATH
export APPTAINERENV_EAR_TMP=$EAR_TMP
export APPTAINERENV_EAR_ETC=$EAR_ETC
export APPTAINERENV_EARL_REPORT_LOOPS=1

# USE GPU DIRECT
export GMX_ENABLE_DIRECT_GPU_COMM=1

# SINGULARITY COMMAND
SINGULARITY="singularity run --nv -B ${PWD}:/host_pwd --pwd /host_pwd docker://nvcr.io/hpc/gromacs:2022.3"

# Run using erun command 
${SINGULARITY} $EAR_INSTALL_PATH/bin/erun --ear=on --program="gmx mdrun -ntmpi 8 -ntomp 9 -nb gpu -pme gpu -npme 1 -update gpu -bonded gpu -nsteps 100000 -resetstep 90000 -noconfout -dlb no -nstlist 300 -pin on -v -gpu_id 0123"

rm *ener.edr.*
rm *md.log.*

