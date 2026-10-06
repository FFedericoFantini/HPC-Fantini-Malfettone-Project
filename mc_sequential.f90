program mc_sequential

    use iso_fortran_env, only : error_unit, int64, real64
    use mc_io, only : input_filename, read_sample_count
    use mc_rng1, only : rng_seed, rng_uniform

    implicit none

    integer, parameter :: base_seed = 12345
    integer, parameter :: output_unit = 20

    character(len=64) :: output_filename

    integer :: io_status
    integer(int64) :: n_samples , sample

    real(real64) :: x , y , z , value
    real(real64) :: sum_value , estimate
    real(real64) :: start_time , end_time

    output_filename = 'output/output_sequential.dat'

    call read_sample_count(n_samples, io_status)

    if (io_status /= 0) then
        write(error_unit, '(A)') &
            'Input error: unable to read input/input.dat or invalid sample count.'
        error stop 1
    end if

    call rng_seed(base_seed)

    sum_value = 0.0_real64

    call cpu_time(start_time)

    do sample = 1_int64, n_samples
        call rng_uniform(x, y, z)

        value = exp(-(x*x + y*y + z*z))
        sum_value = sum_value + value
    end do

    call cpu_time(end_time)

    estimate = sum_value / real(n_samples, real64)

    open(unit=output_unit, file=output_filename, status='replace', &
         action='write', iostat=io_status)

    if (io_status /= 0) then
        write(error_unit, '(A)') &
            'Output error: unable to open output/output_sequential.dat.'
        error stop 1
    end if

    write(output_unit, '(A)') 'Implementation = sequential'
    write(output_unit, '(A,1X,A)') 'Input file     =', trim(input_filename)
    write(output_unit, '(A,1X,A)') 'Output file    =', trim(output_filename)
    write(output_unit, '(A,1X,I0)') 'Samples        =', n_samples
    write(output_unit, '(A,1X,ES24.16)') 'Estimate       =', estimate
    write(output_unit, '(A,1X,F12.6)') 'Execution time =', end_time - start_time
    close(output_unit)

end program mc_sequential
