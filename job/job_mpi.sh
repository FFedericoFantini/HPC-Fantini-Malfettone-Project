#!/bin/bash
#SBATCH -A dida-hpc
#SBATCH -p hpc-q
#SBATCH --time=00:05:00
#SBATCH -N 1
#SBATCH --ntasks=20
#SBATCH --mem=40g
#SBATCH --job-name=mc_mpi
#SBATCH --output=../output-job/out_mpi_%j.out

module purge
module load slurm
module load oneapi/compiler
module load oneapi/mkl
module load oneapi/mpi

cd "$SLURM_SUBMIT_DIR/.."

mkdir -p output

mpiifort -O0 mc_io.f90 mc_rng1.f90 mc_mpi.f90 -o mc_mpi
mpiexec -n "$SLURM_NTASKS" ./mc_mpi
