program mc_mpi

    use iso_fortran_env, only : error_unit, int64, real64
    use mpi
    use mc_io, only : input_filename, read_sample_count
    use mc_rng1, only : rng_seed, rng_uniform

    implicit none

    integer, parameter :: output_unit = 20

    character(len=64) :: output_filename

    integer :: ierr , rank , nprocs, io_status
    integer(int64) :: n_total , n_local , base_points , remainder , sample

    real(real64) :: x , y , z , value
    real(real64) :: local_sum  , global_sum , estimate
    real(real64) :: start_time , end_time , local_elapsed , maximum_elapsed

    output_filename = 'output/output_mpi.dat'

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    n_total = 0_int64

    if (rank == 0) then
        call read_sample_count(n_total, io_status)

        if (io_status /= 0) then
            write(error_unit, '(A)') &
                'Input error: unable to read input/input.dat or invalid sample count.'
            call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
        end if
    end if

    call MPI_Bcast(n_total, 1, MPI_INTEGER8, 0, MPI_COMM_WORLD, ierr)

    base_points = n_total / int(nprocs, int64)
    remainder = mod(n_total, int(nprocs, int64))

    n_local = base_points
    
    if (int(rank, int64) < remainder) then
        n_local = n_local + 1_int64
    end if

    call rng_seed(rank)

    local_sum = 0.0_real64

    call MPI_Barrier(MPI_COMM_WORLD, ierr)
    start_time = MPI_Wtime()

    do sample = 1_int64, n_local
        call rng_uniform(x, y, z)

        value = exp(-(x*x + y*y + z*z))
        local_sum = local_sum + value
    end do

    call MPI_Reduce(local_sum, global_sum, 1, MPI_DOUBLE_PRECISION, &
                    MPI_SUM, 0, MPI_COMM_WORLD, ierr)

    end_time = MPI_Wtime()
    local_elapsed = end_time - start_time

    call MPI_Reduce(local_elapsed, maximum_elapsed, 1, &
                    MPI_DOUBLE_PRECISION, MPI_MAX, 0, MPI_COMM_WORLD, ierr)

    if (rank == 0) then
        estimate = global_sum / real(n_total, real64)

        open(unit=output_unit, file=output_filename, status='replace', &
             action='write', iostat=io_status)

        if (io_status /= 0) then
            write(error_unit, '(A)') &
                'Output error: unable to open output/output_mpi.dat.'
            call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
        end if

        write(output_unit, '(A)') 'Implementation = MPI'
        write(output_unit, '(A,1X,A)') 'Input file     =', trim(input_filename)
        write(output_unit, '(A,1X,A)') 'Output file    =', trim(output_filename)
        write(output_unit, '(A,1X,I0)') 'Samples        =', n_total
        write(output_unit, '(A,1X,I0)') 'MPI processes  =', nprocs
        write(output_unit, '(A,1X,ES24.16)') 'Estimate       =', estimate
        write(output_unit, '(A,1X,F12.6)') 'Execution time =', maximum_elapsed
        close(output_unit)
    end if

    call MPI_Finalize(ierr)

end program mc_mpi
