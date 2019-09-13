! files.f90 - Module, incorporating directory scans and access to FastSonic files
!
! Copyright 2019 by Servizi Territorio srl
!                   This is open-source code, covered by the MIT license
!
! Written by: PM-62
!
module files

  use dflib

  implicit none

  private

  ! Public constants
  integer, parameter  :: PATH$FLAT  = 1
  integer, parameter  :: PATH$METEK = 2

  ! Public interface
  public  :: FindDataFiles
  Public  :: PATH$FLAT
  Public  :: PATH$METEK
  public  :: ReadFastSonicFile

contains

  ! Map FastSonic files in a user-given directory
  function FindDataFiles(sInputPath, svFiles, iPathType, lUnixDelimiter) result(iRetCode)

    ! Routine arguments
    character(len=*), intent(in)                                :: sInputPath
    character(len=256), dimension(:), allocatable, intent(out)  :: svFiles
    integer, optional, intent(in)                               :: iPathType      ! Default: PATH$METEK
    character, optional, intent(in)                             :: lUnixDelimiter ! Default: .TRUE.
    integer                                                     :: iRetCode

    ! Locals
    integer   :: iPathStructure
    integer   :: iHandle
    integer   :: iLength
    character :: cDelim
    integer   :: iNumFiles
    integer   :: iFile

    ! Assume success (will falsify on failure)
    iRetCode = 0

    ! Set path structure based on 'iPathType'
    if(present(iPathType)) then
      iPathStructure = iPathType
    else
      iPathStructure = PATH$METEK
    end if

    ! Set path delimiter based on 'lUnixDelimiter'
    if(present(lUnixDelimiter)) then
      if(lUnixDelimiter) then
        cDelim = '/'
      else
        cDelim = '\\' ! Single-char \\, assuming "non-UNIX" actually means "Microsoft Windows"
      end if
    else
      cDelim = '/'
    end if

    ! Dispatch execution based on 'iPathStructure'
    select case(iPathStructure)
    case(PATH$FLAT)

      ! First pass: count files in directory, and reserve workspace based on result
      iNumFiles = 0
      iHandle = file$first
      do
        iLength = getfileinfoqq(trim(sInputPath) // "\\*", tFileInfo, iHandle)
        if(iHandle == file$last .or. iHandle == file$error) exit
        if(iand(tFileInfo % permit, file$dir) == 0) then
          iNumFiles = iNumFiles + 1
        end if
      end do
      if(allocated(svFiles)) deallocate(svFiles)
      allocate(svFiles(iNumFiles))

      ! Second pass: et file names
      iFile = 0
      iHandle = file$first
      do
        iLength = getfileinfoqq(trim(sInputPath) // "\\*", tFileInfo, iHandle)
        if(iHandle == file$last .or. iHandle == file$error) exit
        if(iand(tFileInfo % permit, file$dir) == 0) then
          iFile = iFile + 1
          svFiles(iFile) = trim(sInputPath) // '\\' // trim(tFileInfo % name)
        end if
      end do

    case(PATH$METEK)
    case default
    end select

  end function FindDataFiles

end module files
