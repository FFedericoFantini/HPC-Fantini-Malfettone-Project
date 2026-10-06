#!/bin/bash
#SBATCH -A dida-hpc
#SBATCH -p hpc-q
#SBATCH --time=00:05:00
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=40g
#SBATCH --job-name=mc_openmp
#SBATCH --output=../output-job/out_openmp_%j.out

module purge
module load slurm
module load oneapi/compiler
module load oneapi/mkl
module load oneapi/mpi

cd "$SLURM_SUBMIT_DIR/.."

mkdir -p output

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OMP_DYNAMIC=FALSE
export OMP_PLACES=cores
export OMP_PROC_BIND=close

mpiifort -O2 -qopenmp mc_io.f90 mc_rng1.f90 mc_openmp.f90 -o mc_openmp
./mc_openmp
