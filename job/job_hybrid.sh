#!/bin/bash
#SBATCH -A dida-hpc
#SBATCH -p hpc-q
#SBATCH --time=00:05:00
#SBATCH -N 1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=5
#SBATCH --mem=40g
#SBATCH --job-name=mc_hybrid
#SBATCH --output=../output-job/out_hybrid_%j.out

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
export I_MPI_PIN_DOMAIN=omp

mpiifort -O0 -qopenmp mc_io.f90 mc_rng1.f90 mc_hybrid.f90 -o mc_hybrid
mpiexec -n "$SLURM_NTASKS" ./mc_hybrid
