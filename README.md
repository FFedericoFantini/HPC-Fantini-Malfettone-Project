# OpenMP-Driven Monte Carlo: Code Guide

This repository contains four Fortran implementations of the same three-dimensional Monte Carlo workload: sequential, OpenMP, MPI, and hybrid MPI+OpenMP. This README documents the source files and how to run them; the project report contains the theoretical background and performance analysis.

## Repository contents

```text
HPC-OpenMP-Project/
├── HPC_Project.pdf             # Project Report
├── input/input.dat             # Number of samples (one positive integer)
├── output/                     # Program result files (.dat)
├── output-job/                 # Destination for SLURM logs
├── job/                        # SLURM build-and-run scripts
├── mc_io.f90                   # Shared input routine
├── mc_rng1.f90                 # RNG used by all four final programs
├── mc_rng.f90                  # Earlier RNG module; not used by the final programs
├── mc_sequential.f90           # Sequential reference program
├── mc_openmp.f90               # OpenMP program
├── mc_mpi.f90                  # MPI program
├── mc_hybrid.f90               # Hybrid MPI+OpenMP program
└── results_N_10_10.xlsx        # Recorded experimental results; not needed to run
```

## Shared modules and input

- `mc_io.f90` reads the sample count from `input/input.dat` and rejects a missing file or a non-positive value. The programs use paths relative to the project root, so run them with the project root as the working directory.
- `mc_rng1.f90` provides `rng_seed` and `rng_uniform`. The latter returns three coordinates for each sample. Its generator state is an `integer(int64)` marked `!$omp threadprivate`, giving each OpenMP thread its own state. The seed combines the system clock with an identifier supplied by the calling program, so separate runs are not designed to reproduce an identical sequence.
- `mc_rng.f90` wraps Fortran's intrinsic `random_seed` and `random_number`. It is retained in the folder, but the current programs and SLURM scripts use `mc_rng1.f90` instead.
- `input/input.dat` initially contains `10000000000`. Change that value to run a different sample count.

## Program flow

| Source file | What it does |
| --- | --- |
| `mc_sequential.f90` | Runs the sampling loop once, accumulates the sum, and writes `output/output_sequential.dat`. It seeds the generator with the fixed identifier `base_seed`. |
| `mc_openmp.f90` | Divides the sampling loop among OpenMP threads and writes `output/output_openmp.dat`. |
| `mc_mpi.f90` | Distributes samples among MPI ranks and combines their partial sums; writes `output/output_mpi.dat`. |
| `mc_hybrid.f90` | Distributes samples among MPI ranks, then uses OpenMP threads within each rank; writes `output/output_hybrid.dat`. |

Each result file records the sample count, estimate, execution time, and the applicable process/thread counts. Running an implementation replaces its previous `.dat` result file. The SLURM log files have job IDs in their names and therefore remain separate across submissions.

## OpenMP implementation details

`mc_openmp.f90` uses one `parallel` region around the sampling work:

- `default(none)` requires explicit data-sharing choices. The sample count and recorded team size are shared; the thread ID, coordinates, and integrand value are private.
- `reduction(+:sum_value)` gives each thread a local accumulator and combines the partial sums when the parallel region finishes, avoiding concurrent updates to one shared sum.
- Each thread gets its ID with `omp_get_thread_num()` and calls `rng_seed(thread_id)`. Together with `threadprivate(rng_state)` in `mc_rng1.f90`, this keeps RNG updates separate between threads. Thread 0 records the team size with `omp_get_num_threads()`.
- `omp do schedule(static)` assigns the loop iterations to threads in static chunks. The iterations perform the same work, so this avoids repeated scheduling decisions in the main loop.

## Hybrid MPI+OpenMP implementation details

`mc_hybrid.f90` combines process-level distribution with the same thread-level loop used by `mc_openmp.f90`:

- The program starts MPI with `MPI_Init_thread`, requesting `MPI_THREAD_FUNNELED`, and stops with an error if the runtime provides a lower level. All MPI calls are made by the rank's master thread, outside the OpenMP parallel region.
- Rank 0 reads the total sample count and broadcasts it to the other ranks. Each rank calculates its local count from the quotient and remainder of `n_total / nprocs`; the first `remainder` ranks receive one extra sample. This ensures that all samples are assigned, even when the total is not divisible by the rank count.
- Within each rank, `parallel default(none)` creates an OpenMP team for the rank's local loop. `n_local`, `actual_threads`, and `rank` are shared; the thread ID, coordinates, and integrand value are private. The loop index is private by its OpenMP rules.
- Each thread initializes its own RNG state with `rng_seed(rank * 1000 + thread_id)`. Combining rank and thread ID distinguishes the threads across MPI processes; `threadprivate(rng_state)` then keeps each thread's generator state separate. Thread 0 records the team size for the output file.
- `omp do schedule(static)` divides each rank's local samples among its threads. `reduction(+:local_sum)` combines the thread partial sums into one sum for that rank. After the parallel region, `MPI_Reduce` with `MPI_SUM` combines rank sums to form the final estimate.
- The code synchronizes ranks before timing with `MPI_Barrier`. It records the maximum rank elapsed time with a second `MPI_Reduce`, using `MPI_MAX`, and writes the estimate, rank count, and thread count to `output/output_hybrid.dat`.

## Run on Lyra

The scripts in `job/` are configured for Lyra's SLURM scheduler and Intel oneAPI compiler/MPI modules. Each script compiles the relevant source files with `mpiifort` and then runs the program.

From the project root, create the SLURM log directory if it is not present, then submit a script from `job/`:

```bash
mkdir -p output-job
cd job
sbatch job_sequential.sh
sbatch job_openmp.sh
sbatch job_mpi.sh
sbatch job_hybrid.sh
```

Run only the submissions you need; each command creates an independent SLURM job. The scripts expect to be submitted while the current directory is `job/`; they then change to the project root to compile and execute. `output-job/` must exist before `sbatch` because SLURM opens the log file before the script starts.

The default resource allocations are:

| Script | SLURM allocation | OpenMP / MPI settings |
| --- | --- | --- |
| `job_sequential.sh` | 1 task, 1 CPU | No OpenMP region is enabled. |
| `job_openmp.sh` | 1 task, 20 CPUs | Uses the allocated CPUs as threads; sets `OMP_DYNAMIC=FALSE`, `OMP_PLACES=cores`, and `OMP_PROC_BIND=close`. |
| `job_mpi.sh` | 20 tasks | Runs 20 MPI ranks without OpenMP. |
| `job_hybrid.sh` | 4 tasks, 5 CPUs per task | Runs 4 MPI ranks with 5 OpenMP threads per rank; also sets `I_MPI_PIN_DOMAIN=omp`. |

The OpenMP and hybrid scripts compile with `-qopenmp`. They load the compiler and MPI modules, set the thread-affinity environment variables, and launch the resulting executable. Adjust the `#SBATCH` resource requests in the relevant script to change the default configuration.
