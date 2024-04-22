#!/bin/bash

#SBATCH -p rome
#SBATCH -t 00:35:00
#SBATCH --nodes=1
#SBATCH --exclusive

#SBATCH --output=NPB.%j.out
#SBATCH --error=NPB.%j.err
#SBATCH --job-name=NPB

module load 2023
module load foss/2023a

# ENV variable needed to report "loops" to the EARDB
# export EARL_REPORT_LOOPS=1

# location of the binaries for the course
PROJECT_DIR=/projects/0/energy-course

# Two Class sizes available 

# | Class | Mesh size (x)  | Mesh size (y)  | Mesh size (z)  |
# |   C   |       240      |       320      |       28       |
# |   D   |      1632      |      1216      |       34       |

srun --ear=on --ear-policy=monitoring --ntasks=128 /projects/0/energy-course/NPB3.4-MZ-MPI/sp-mz.D.x
srun --ear=on --ear-policy=min_time --ntasks=128 /projects/0/energy-course/NPB3.4-MZ-MPI/sp-mz.D.x
srun --ear=on --ear-policy=min_energy --ntasks=128 /projects/0/energy-course/NPB3.4-MZ-MPI/sp-mz.D.x
