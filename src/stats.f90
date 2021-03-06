! stats.f90 - statistics, computed "efficiently" using CUDA hardware (in simple
!             way)
!
! Copyright 2019 by Servizi Territorio srl
!                   This is open-source software, covered by the MIT license
!
! Written by: Mauri Favaron
!
module Stats

  use cudafor

  implicit none

  private

  ! Public interface
  public  :: mean

contains

  function mean(rvTimeStamp, rvValues, iAveraging, rvMean, lRemoveInvalid, rLower, rUpper) result(iRetCode)

    ! Routine arguments
    real, dimension(:), intent(in)                :: rvTimeStamp    ! "Small" vector (i.e. not more than about 100000 elements) of time stamps (secs within hour)
    real, dimension(:), intent(in)                :: rvValues       ! "Small" vector (i.e. not more than about 100000 elements) of values to average
    integer, intent(in)                           :: iAveraging     ! In range 1..3600; better, but not strictly necessary, if a divisor of 3600
    real, dimension(:), allocatable, intent(out)  :: rvMean         ! Average values
    logical, intent(in), optional                 :: lRemoveInvalid ! .true. if invalid values are removed (default), .false. if they are left
    real, intent(in), optional                    :: rLower         ! Least valid value (default: -9990.0)
    real, intent(in), optional                    :: rUpper         ! Largest valid value (default: +9990.0)
    integer                                       :: iRetCode

    ! Locals
    real, dimension(size(rvValues)), device     :: rv_d_TimeStamp
    real, dimension(size(rvValues)), device     :: rv_d_Values
    integer, dimension(size(rvValues)), device  :: iv_d_TimeIndex

    ! CUDA-related constants
    integer, parameter  :: tPB = 256

    ! Assume success (will falsify on failure)
    iRetCode = 0

    ! check parameters
    if(size(rvValues) <= 0) then
      if(allocated(rvMean)) deallocate(rvMean)
      iRetCode = 1
      return
    end if
    if(iAveraging <= 0 .or. iAveraging > 3600) then
      if(allocated(rvMean)) deallocate(rvMean)
      iRetCode = 2
      return
    end if

    ! First step: generate the time index of all values
    rv_d_TimeStamp = rvTimeStamp
    rv_d_Values = rvValues
    call setTimeIndex<<<size(rvTimeStamp)/tPB+1,tPB>>>(iv_d_TimeIndex, rv_d_TimeStamp, iAveraging)

  end function mean


  attributes(global) subroutine setTimeIndex(iv_d_TimeIndex, rv_d_TimeStamp, iAveraging)

    ! Routine arguments
    integer, dimension(:), intent(out)  :: iv_d_TimeIndex
    real, dimension(:), intent(in)      :: rv_d_TimeStamp
    integer, value, intent(in)          :: iAveraging

    ! Locals
    integer   :: i

    ! Convert real-valued time stamp to integer-valued time indices, CUDA style
    i = (blockIdx%x - 1)*blockDim%x + threadIdx%x
    if(i <= size(rv_d_TimeStamp)) then
      iv_d_TimeIndex(i) = floor(rv_d_TimeStamp(i) / iAveraging)
    end if

  end subroutine setTimeIndex


  attribute(global) subroutine 

end module Stats
