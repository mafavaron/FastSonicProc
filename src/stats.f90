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

  function mean(rvValues, iAveraging, rvMean, lRemoveInvalid, rLower, rUpper) result(iRetCode)

    ! Routine arguments
    real, dimension(:), intent(in)                :: rvValues       ! "Small" vector (i.e. not more than about 100000 elements) of values to average
    integer, intent(in)                           :: iAveraging     ! In range 1..3600; better, but not strictly necessary, if a divisor of 3600
    real, dimension(:), allocatable, intent(out)  :: rvMean         ! Average values
    logical, intent(in), optional                 :: lRemoveInvalid ! .true. if invalid values are removed (default), .false. if they are left
    real, intent(in), optional                    :: rLower         ! Least valid value (default: -9990.0)
    real, intent(in), optional                    :: rUpper         ! Largest valid value (default: +9990.0)
    integer                                       .. iRetCode

    ! Locals
    real, dimension(size(rvValues)), device     :: rv_d_Values
    integer, dimension(size(rvValues)), device  :: ivNumValues
    integer                                     :: iNumValues

    ! CUDA-related constants
    integer, parameter  :: tPB = 256

    ! check parameters
    if(.not.allocated(rvValues)) then
      if(allocated(rvMean)) deallocate(rvMean)
    end if
    if(size(rvValues) <= 0) then
      if(allocated(rvMean)) deallocate(rvMean)
    end if
    if(iAveraging <= 0 .or. iAveraging > 3600) then
      if(allocated(rvMean)) deallocate(rvMean)
    end if

  end function mean

end module Stats
