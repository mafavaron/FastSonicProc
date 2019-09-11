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
  character(len=256)  :: sSubdir
  type(file$info)     :: tFileInfo
  type(file$info)     :: tFileInfo2
  integer(4)          :: iHandle
  integer(4)          :: iFileHandle
  integer(4)          :: iLength
  character(len=256)  :: sInputFileName
  character(len=256)  :: sFileName
  character(len=256)  :: sBuffer
  integer             :: iPos
  integer             :: iNumData
  integer             :: iData
  integer             :: iTimeStamp
  integer             :: iU, iV, iW, iT
  real                :: rU, rV, rW, rT
  integer(2), dimension(:), allocatable :: ivTimeStamp, ivU, ivV, ivW, ivT

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

  ! Identify sub-directories in input path
  iHandle = file$first
  do
    iLength = getfileinfoqq(trim(sInputPath) // "\\*", tFileInfo, iHandle)
    if(iHandle == file$last .or. iHandle == file$error) exit
    if((tFileInfo % permit .and. file$dir) /= 0) then
      if(len_trim(tFileInfo % name) == 6) then
        sSubDir = trim(sInputPath) // '\\' // trim(tFileInfo % name)

        ! Identify files in sub-directories
        iFileHandle = file$first
        do

          ! Get input and output file names
          iLength = getfileinfoqq(trim(sSubDir) // "\\*", tFileInfo2, iFileHandle)
          if(iFileHandle == file$last .or. iFileHandle == file$error) exit
          if(len_trim(tFileInfo2 % name) /= 11) cycle
          sInputFileName = trim(sSubDir) // '\\' // trim(tFileInfo2 % name)
          sFileName = trim(sOutputPath) // '\\' // trim(tFileInfo2 % name) // '.slb'

          ! Process file
          ! -1- Count lines
          print *, "Encoding ", trim(sInputFileName)
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
          if(allocated(ivTimeStamp)) deallocate(ivTimeStamp)
          allocate(ivTimeStamp(iNumData))
          if(allocated(ivU)) deallocate(ivU)
          allocate(ivU(iNumData))
          if(allocated(ivV)) deallocate(ivV)
          allocate(ivV(iNumData))
          if(allocated(ivW)) deallocate(ivW)
          allocate(ivW(iNumData))
          if(allocated(ivT)) deallocate(ivT)
          allocate(ivT(iNumData))
          ! -1- Really read data
          rewind(10)
          read(10, "(a)") sBuffer
          do iData = 1, iNumData
            read(10, *) iTimeStamp, rU, rV, rW, rT
            ivTimeStamp(iData) = iTimeStamp
            ivU(iData) = nint(rU * 100.0)
            ivV(iData) = nint(rV * 100.0)
            ivW(iData) = nint(rW * 100.0)
            ivT(iData) = nint(rT * 100.0)
          end do
          close(10)

        end do

      end if
    end if
  end do

end program SonicEncode
