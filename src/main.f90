! Main program: iterate over MeteoFlux Core V2 files, get their sonic part,
!               and process it in some simple ways.
!
program SonicProcess

  use dflib

  implicit none

  ! Locals
  character(len=256)  :: sInputPath
  character(len=256)  :: sOutputPath
  integer             :: iRetCode
  character(len=256)  :: sSubdir
  type(file$info)     :: tFileInfo
  integer(4)          :: iHandle
  integer(4)          :: iFileHandle
  integer(4)          :: iLength
  character(len=256)  :: sFileName

  ! Get command arguments
  if(command_argument_count() /= 2) then
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
          print *,trim(sSubDir) // "\\*"
          iLength = getfileinfoqq(trim(sSubDir) // "\\*", tFileInfo, iFileHandle)
          print *, iFileHandle, trim(sSubDir) // '\\' // trim(tFileInfo % name)
          if(iFileHandle == file$last .or. iFileHandle == file$error) exit
          if((tFileInfo % permit .and. file$dir) == 0) then
            print *, trim(sSubDir) // '\\' // trim(tFileInfo % name)
          end if
        end do

      end if
    end if
  end do

end program SonicProcess
