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
  integer                                       :: iNumData
  integer(2), dimension(:), allocatable         :: ivTimeStamp
  real, dimension(:), allocatable               :: rvU, rvV, rvW, rvT

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
    ! -1- Try connecting
    open(10, file=svFiles(i), status='old', action='read', access='stream', iostat=iRetCode)
    if(iRetCode /= 0) then
      print *, 'error:: Input file not opened - Return code = ', iRetCode
      stop
    end if
    ! -1- Get data size, and reserve workspace based on it
    read(10, iostat=iRetCode) iNumData
    if(iRetCode /= 0) then
      print *, 'error:: Input file not read - Return code = ', iRetCode
      stop
    end if
    if(allocated(ivTimeStamp)) deallocate(ivTimeStamp)
    allocate(ivTimeStamp(iNumData))
    if(allocated(rvU)) deallocate(rvU)
    allocate(rvU(iNumData))
    if(allocated(rvV)) deallocate(rvV)
    allocate(rvV(iNumData))
    if(allocated(rvW)) deallocate(rvW)
    allocate(rvW(iNumData))
    if(allocated(rvT)) deallocate(rvT)
    allocate(rvT(iNumData))
    ! -1- Read, and release file
    read(10) ivTimeStamp
    read(10) rvU
    read(10) rvV
    read(10) rvW
    read(10) rvT
    close(10)

  end do

  ! Time elapsed counts
  call cpu_time(rTimeEnd)
  print *, "*** END JOB *** (Time elapsed:", rTimeEnd - rTimeBegin, ")"

end program SonicProcess
