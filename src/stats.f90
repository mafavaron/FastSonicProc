! stats.f90 - statistics, computed "efficiently" using CUDA hardware (in simple
!             way)
!
! Copyright 2019 by Servizi Territorio srl
!                   This is open-source software, covered by the MIT license
!
! Written by: Mauri Favaron
!
module Stats

  implicit none

  private

  ! Public interface
  public  :: mean

continue

  function mean(rvValues) result(rMean)

    ! Routine arguments
    real, dimension(:), intent(in)  :: rvValues
    real                            :: rMean

    ! Locals
    real, dimension(size(rvValues)), device :: rv_d_Values

    ! CUDA-related constants
    integer, parameter  :: tPB = 256

  end function mean

end module Stats
