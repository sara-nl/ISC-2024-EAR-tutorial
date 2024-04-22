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

#for frequency in {1300000..2400000..100000} #Intel(R) Xeon(R) Platinum 8360Y CPU @ 2.40GHz
for frequency in {1500000..2600000..100000} #AMD (Rome) EPYC 7H12 64-Core Processor
#for frequency in {1500000..2400000..100000} #AMD (Genoa) EPYC 9654 96-Core Processor
do

    echo "Launching NPB @ Freq=$frequency"

    srun --ear-cpufreq=$frequency --ear-policy=monitoring --ear-verbose=1 --ntasks=128  /projects/0/energy-course/NPB3.4-MZ-MPI/sp-mz.D.x

done
