module mc_io

    use iso_fortran_env, only : int64

    implicit none

    private

    character(len=15), parameter, public :: input_filename = 'input/input.dat'

    public :: read_sample_count

contains

    subroutine read_sample_count(n_samples, status)

        integer(int64), intent(out) :: n_samples
        integer, intent(out) :: status

        integer :: input_unit

        n_samples = 0_int64
        status = 0

        open(newunit=input_unit, file=input_filename, status='old', &
             action='read', iostat=status)

        if (status /= 0) return

        read(input_unit, *, iostat=status) n_samples
        close(input_unit)

        if (status == 0 .and. n_samples <= 0_int64) then
            status = 1
        end if

    end subroutine read_sample_count

end module mc_io
