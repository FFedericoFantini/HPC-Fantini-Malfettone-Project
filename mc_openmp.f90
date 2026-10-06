program mc_openmp

    use iso_fortran_env, only : error_unit, int64, real64
    use omp_lib
    use mc_io, only : input_filename, read_sample_count
    use mc_rng1, only : rng_seed, rng_uniform

    implicit none

    integer, parameter :: base_seed = 12345
    integer, parameter :: output_unit = 20

    character(len=64) :: output_filename

    integer :: io_status
    integer :: thread_id , actual_threads
    integer(int64) :: n_samples , sample

    real(real64) :: x , y , z , value
    real(real64) :: sum_value , estimate
    real(real64) :: start_time , end_time

    output_filename = 'output/output_openmp.dat'

    call read_sample_count(n_samples, io_status)

    if (io_status /= 0) then
        write(error_unit, '(A)') &
            'Input error: unable to read input/input.dat or invalid sample count.'
        error stop 1
    end if

    sum_value = 0.0_real64
    actual_threads = 0

    start_time = omp_get_wtime()

    !$omp parallel default(none) &
    !$omp& shared(n_samples, actual_threads) &
    !$omp& private(thread_id, x, y, z, value) &
    !$omp& reduction(+:sum_value)

        thread_id = omp_get_thread_num()

        call rng_seed(thread_id)

        if (thread_id == 0) then
            actual_threads = omp_get_num_threads()
        end if

        !$omp do schedule(static)
        do sample = 1_int64, n_samples
            call rng_uniform(x, y, z)

            value = exp(-(x*x + y*y + z*z))
            sum_value = sum_value + value
        end do
        !$omp end do

    !$omp end parallel

    end_time = omp_get_wtime()

    estimate = sum_value / real(n_samples, real64)

    open(unit=output_unit, file=output_filename, status='replace', &
         action='write', iostat=io_status)

    if (io_status /= 0) then
        write(error_unit, '(A)') &
            'Output error: unable to open output/output_openmp.dat.'
        error stop 1
    end if

    write(output_unit, '(A)') 'Implementation = OpenMP'
    write(output_unit, '(A,1X,A)') 'Input file     =', trim(input_filename)
    write(output_unit, '(A,1X,A)') 'Output file    =', trim(output_filename)
    write(output_unit, '(A,1X,I0)') 'Samples        =', n_samples
    write(output_unit, '(A,1X,I0)') 'Threads        =', actual_threads
    write(output_unit, '(A,1X,ES24.16)') 'Estimate       =', estimate
    write(output_unit, '(A,1X,F12.6)') 'Execution time =', end_time -start_time
    close(output_unit)

end program mc_openmp

