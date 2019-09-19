! Main program: iterate over SonicLib files, get their sonic part,
!               and save it in new FastSonic form.
!
! By: Mauri Favaron ("PM-F-62")
!
program SonicProcess

  use files

  implicit none

  ! Locals
  character(len=256)  :: sInputPath
  character(len=256)  :: sOutputPath
  integer             :: iRetCode
  real                :: rTimeBegin
  real                :: rTimeEnd
  integer             :: i
  character(len=256), dimension(:), allocatable :: svFiles
  type(FastSonicData)                           :: tData

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
    iRetCode = tData % get(svFiles(i))
    if(iRetCode /= 0) then
      print *, 'error:: File termination before completing data read'
      stop
    end if

  end do

  ! Time elapsed counts
  call cpu_time(rTimeEnd)
  print *, "*** END JOB *** (Time elapsed:", rTimeEnd - rTimeBegin, ")"

end program SonicProcess
