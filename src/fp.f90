! Main program: iterate over SonicLib files, get their sonic part,
!               and save it in new FastSonic form.
!
program SonicEncode

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
  character(len=256)  :: sBuffer
  integer             :: iPos
  integer             :: iNumData
  integer             :: iData
  integer             :: iTimeStamp
  integer             :: iU, iV, iW, iT
  real                :: rU, rV, rW, rT
  integer(2)          :: zero = 0
  real, dimension(:), allocatable       :: rvTimeStamp, rvU, rvV, rvW, rvT

  ! Get command arguments
  if(command_argument_count() /= 2) then
    print *, "fp - Ultrasonic anemometer raw data encoding procedure"
    print *
    print *, "error:: Invalid command line"
    print *
    print *, "Usage:"
    print *
    print *, "  ./fp <Input_Path> <Output_Path>"
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
      sOutputFileName = sOutputFileName(1:len_trim(sOutputFileName)-3) // 'fsr'

      ! Process file
      ! -1- Count lines
      print *, "Encoding to ", trim(sOutputFileName)
      open(10, file=sInputFileName, status='old', action='read', iostat=iRetCode)
      if(iRetCode /= 0) then
        print *,trim(sInputFileName)
        print *, 'error:: Input file not opened - ', iRetCode
        stop
      end if
      ! -1- Count data in file
      read(10, "(a)", iostat=iRetCode) sBuffer
      if(iRetCode /= 0) then
        print *, 'error:: Empty input file'
        stop
      end if
      iNumData = 0
      do
        read(10, "(a)", iostat=iRetCode) sBuffer
        if(iRetCode /= 0) exit
        iNumData = iNumData + 1
      end do
      if(iNumData <= 0) then
        print *, 'error:: No data in input file'
        stop
      end if
      ! -1- Reserve workspace
      if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
      allocate(rvTimeStamp(iNumData))
      if(allocated(rvU)) deallocate(rvU)
      allocate(rvU(iNumData))
      if(allocated(rvV)) deallocate(rvV)
      allocate(rvV(iNumData))
      if(allocated(rvW)) deallocate(rvW)
      allocate(rvW(iNumData))
      if(allocated(rvT)) deallocate(rvT)
      allocate(rvT(iNumData))
      ! -1- Really read data
      rewind(10)
      read(10, "(a)") sBuffer
      do iData = 1, iNumData
        read(10, *) iTimeStamp, rU, rV, rW, rT
        rvTimeStamp(iData) = iTimeStamp
        rvU(iData) = rU
        rvV(iData) = rV
        rvW(iData) = rW
        rvT(iData) = rT
      end do
      close(10)

      ! Write data in binary form
      open(11, file=sOutputFileName, status='unknown', action='write', access='stream')
      write(11) iNumData
      write(11) zero
      write(11) rvTimeStamp
      write(11) rvU
      write(11) rvV
      write(11) rvW
      write(11) rvT
      close(11)

    end if
  end do

  ! Time elapsed counts
  call cpu_time(rTimeEnd)
  print *, "*** END JOB *** (Time elapsed:", rTimeEnd - rTimeBegin, ")"

end program SonicEncode
