! Main program: iterate over SonicLib files, get their sonic part,
!               and save it in new FastSonic form.
!
! By: Mauri Favaron ("PM-F-62")
!
program SonicProcess

  use dflib

  implicit none

  ! Locals
  character(len=256)  :: sInputPath
  character(len=256)  :: sOutputPath
  integer             :: iRetCode
  real                :: rTimeBegin
  real                :: rTimeEnd
  character(len=256)  :: sSubdir
  type(file$info)     :: tFileInfo
  integer(4)          :: iHandle
  integer(4)          :: iFileHandle
  integer(4)          :: iLength
  character(len=256)  :: sInputFileName
  character(len=256)  :: sOutputFileName
  integer             :: iNumData
  integer(2), dimension(:), allocatable :: ivTimeStamp
  real, dimension(:), allocatable       :: rvU, rvV, rvW, rvT

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
  iHandle = file$first
  do
    iLength = getfileinfoqq(trim(sInputPath) // "\\*", tFileInfo, iHandle)
    if(iHandle == file$last .or. iHandle == file$error) exit
    if(iand(tFileInfo % permit, file$dir) == 0) then
      sInputFileName = trim(sInputPath) // '\\' // trim(tFileInfo % name)
      sOutputFileName = trim(sOutputPath) // '\\' // trim(tFileInfo % name)

      ! Get file
      ! -1- Try connecting
      open(10, file=sInputFileName, status='old', action='read', access='stream', iostat=iRetCode)
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

    end if
  end do

  ! Time elapsed counts
  call cpu_time(rTimeEnd)
  print *, "*** END JOB *** (Time elapsed:", rTimeEnd - rTimeBegin, ")"

end program SonicProcess
