module mc_rng1
    use iso_fortran_env, only : real64, int64
    implicit none
    private
    public :: rng_seed, rng_uniform
    integer(int64) :: rng_state
    !$omp threadprivate(rng_state)

contains
    subroutine rng_seed(seed_value)
        
        integer, intent(in) :: seed_value
        integer :: clock_time

        call system_clock(count=clock_time)

        rng_state = modulo( &
            int(clock_time, int64) + int(seed_value, int64) * 987654321_int64, &
            2147483648_int64)
    end subroutine rng_seed

    subroutine rng_uniform(x, y, z)
        real(real64), intent(out) :: x, y, z

        x = get_random()
        y = get_random()
        z = get_random()
    end subroutine rng_uniform

    function get_random() result(r)
        real(real64) :: r
        rng_state = modulo( &
            rng_state * 1103515245_int64 + 12345_int64, &
            2147483648_int64)
        r = real(rng_state, real64) / 2147483648.0_real64
    end function get_random

end module mc_rng1