! Main program: iterate over SonicLib files, get their sonic part,
!               and save it in new FastSonic form.
!
! By: Mauri Favaron ("PM-F-62")
!
program SonicProcess

  use files
  use stats

  implicit none

  ! Locals
  character(len=256)  :: sInputPath
  character(len=256)  :: sOutputPath
  integer             :: iRetCode
  real                :: rTimeBegin
  real                :: rTimeEnd
  integer             :: i
  integer             :: j
  character(len=256), dimension(:), allocatable :: svFiles
  real(4), dimension(:), allocatable            :: rvTimeStamp
  real(4), dimension(:), allocatable            :: rvU
  real(4), dimension(:), allocatable            :: rvV
  real(4), dimension(:), allocatable            :: rvW
  real(4), dimension(:), allocatable            :: rvT
  real(4), dimension(:,:), allocatable          :: rmQuantity
  character(8), dimension(:), allocatable       :: svQuantity
  integer             :: iDateStart
  character(len=4)    :: sYear
  character(len=2)    :: sMonth
  character(len=2)    :: sDay
  character(len=2)    :: sHour
  character(len=32)   :: sDateTime

  ! Get command arguments
  if(command_argument_count() /= 2) then
    print *, "fsr - Ultrasonic anemometer raw data processing procedure"
    print *
    print *, "error:: Invalid command line"
    print *
    print *, "Usage:"
    print *
    print *, "  ./fsr <Input_Path> <Output_Path>"
    print *
    print *, "Copyright 2019 by Servizi Territorio srl"
    print *, "                  This software is open source, covered by the MIT license"
    print *
    stop
  end if
  call get_command_argument(1, sInputPath)
  call get_command_argument(2, sOutputPath)

  ! Time elapsed counts
  call cpu_time(rTimeBegin)

  ! Identify sub-directories in input path
  iRetCode = FindDataFiles(sInputPath, svFiles, PATH$FLAT, .FALSE.)
  if(iRetCode /= 0) then
    print *, 'error:: Invalid directory structure type'
    stop
  end if

  ! Main loop: process files in turn
  do i = 1, size(svFiles)

    ! Get file
    iRetCode = fsGet(svFiles(i), rvTimeStamp, rvU, rvV, rvW, rvT, rmQuantity, svQuantity)
    if(iRetCode /= 0) then
      print *, 'error:: File termination before completing data read'
      stop
    end if

    ! Compute crude hourly statistics
    iDateStart = len_trim(svFiles(i)) - 14
    sYear  = svFiles(i)(iDateStart:iDateStart+3)
    sMonth = svFiles(i)(iDateStart+4:iDateStart+5)
    sDay   = svFiles(i)(iDateStart+6:iDateStart+7)
    sHour  = svFiles(i)(iDateStart+8:iDateStart+9)
    sDateTime = sYear / "-" / sMonth / "-" / sDay / " " / sHour / ":00:00"

    print "(a,)", trim(sDateTime), minval(rvTimeStamp), maxval(rvTimeStamp)
    print *, 'V>  ', minval(rvU), maxval(rvU)
    print *, 'V>  ', minval(rvV), maxval(rvV)
    print *, 'W>  ', minval(rvW), maxval(rvW)
    print *, 'T>  ', minval(rvT), maxval(rvT)
    if(allocated(svQuantity)) then
      do j = 1, size(svQuantity)
        print *, svQuantity(j)
        print *, minval(rmQuantity(:,j)), maxval(rmQuantity(:,j))
      end do
    end if

  end do

  ! Time elapsed counts
  call cpu_time(rTimeEnd)
  print *, "*** END JOB *** (Time elapsed:", rTimeEnd - rTimeBegin, ")"

end program SonicProcess
