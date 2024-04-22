#!/bin/bash

#SBATCH -p rome
#SBATCH -t 00:55:00
#SBATCH --nodes=1
#SBATCH --exclusive

#SBATCH --output=NPB_dfvs.%j.out
#SBATCH --error=NPB_dfvs.%j.err
#SBATCH --job-name=NPB_dvfs

#SBATCH --ear=on

module load 2023
module load foss/2023a

# Two Class sizes available 

# | Class | Mesh size (x)  | Mesh size (y)  | Mesh size (z)  |
# |   C   |       240      |       320      |       28       |
# |   D   |      1632      |      1216      |       34       |

# 2600000 is the nominal freq
# you can choose from Freq from 1500000 to 2600000 in increments of 100000
# in a more readable way (1.5 GHz, to 2.6 GHz in increments of 0.1 GHz)
frequency=2000000

echo "Launching NPB @ Freq=$frequency"

srun --ear-cpufreq=$frequency --ear-policy=monitoring --ear-verbose=1 --ntasks=128 /projects/0/energy-course/NPB3.4-MZ-MPI/sp-mz.D.x