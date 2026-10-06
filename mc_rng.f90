module mc_rng
    use iso_fortran_env, only : real64
    implicit none
    private
    integer, parameter :: seed_spacing = 37
    public :: rng_seed, rng_uniform

contains
    subroutine rng_seed(seed_value)

        integer, intent(in) :: seed_value
        integer :: seed_size
        integer :: i
        integer, allocatable :: seed(:)
        integer :: clock_time

        call random_seed(size=seed_size)
        allocate(seed(seed_size))

        call system_clock(count=clock_time)
        seed = clock_time + seed_spacing * (/ (i+seed_value, i=1, seed_size) /)

        call random_seed(put=seed)
        deallocate(seed)
    end subroutine rng_seed

    function rng_uniform() result(values)

        real(real64) :: values(3)
        call random_number(values)

    end function rng_uniform

end module mc_rng