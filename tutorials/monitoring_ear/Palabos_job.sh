#!/bin/bash

#SBATCH -p rome
#SBATCH -t 00:15:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --exclusive

#SBATCH --output=Palabos.%j.out
#SBATCH --error=Palabos.%j.err
#SBATCH --job-name=Palabos

module load 2023
module load foss/2023a

# ENV variable needed to report "loops" to the EARDB
# export EARL_REPORT_LOOPS=1

# location of the binaries for the course
PROJECT_DIR=/projects/0/energy-course

# 1 node case
INPUT_FILE=input_1_node_XL.xml
# 4 node case (!! You need to change #SBATCH --nodes=4 !!)
#INPUT_FILE=input_4_node.xml

srun $PROJECT_DIR/palabos/aneurysm $PROJECT_DIR/palabos/$INPUT_FILE
