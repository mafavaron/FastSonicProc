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

  ! Data types

  type FastSonicData
    real(4), dimension(:), allocatable      :: rvTimeStamp
    real(4), dimension(:), allocatable      :: rvU
    real(4), dimension(:), allocatable      :: rvV
    real(4), dimension(:), allocatable      :: rvW
    real(4), dimension(:), allocatable      :: rvT
    real(4), dimension(:,:), allocatable    :: rmQuantity
    character(8), dimension(:), allocatable :: svQuantity
  contains
    procedure, public :: get    => fsGet
  end type FastSonicData

  ! Public constants
  integer, parameter  :: PATH$FLAT  = 1
  integer, parameter  :: PATH$METEK = 2

  ! Public interface
  public  :: FindDataFiles
  Public  :: PATH$FLAT
  Public  :: PATH$METEK
  public  :: FastSonicData

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
    integer           :: iPathStructure
    integer           :: iHandlePath
    integer           :: iHandle
    integer           :: iLength
    character         :: cDelim
    integer           :: iNumFiles
    integer           :: iFile
    type(file$info)   :: tPathInfo
    type(file$info)   :: tFileInfo

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
        iLength = getfileinfoqq(trim(sInputPath) // cDelim // "*.fsr", tFileInfo, iHandle)
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
        iLength = getfileinfoqq(trim(sInputPath) // cDelim // "*.fsr", tFileInfo, iHandle)
        if(iHandle == file$last .or. iHandle == file$error) exit
        if(iand(tFileInfo % permit, file$dir) == 0) then
          iFile = iFile + 1
          svFiles(iFile) = trim(sInputPath) // cDelim // trim(tFileInfo % name)
        end if
      end do

    case(PATH$METEK)

      ! First pass: count files in directory, and reserve workspace based on result
      iNumFiles = 0
      iHandlePath = file$first
      do
        iLength = getfileinfoqq(trim(sInputPath) // cDelim // "*", tPathInfo, iHandlePath)
        if(iHandlePath == file$last .or. iHandlePath == file$error) exit
        if(iand(tPathInfo % permit, file$dir) > 0) then
          if(len_trim(tPathInfo % name) == 6) then
            iHandle = 0
            do
              iLength = getfileinfoqq( &
                trim(sInputPath) // cDelim // trim(tPathInfo % name) // cDelim // "*.fsr", &
                tFileInfo, &
                iHandle &
              )
              if(iHandle == file$last .or. iHandle == file$error) exit
              if(iand(tInfo % permit, file$dir) == 0) then
                iNumFiles = iNumFiles + 1
              end if
            end do
          end if
        end if
      end do
      if(allocated(svFiles)) deallocate(svFiles)
      allocate(svFiles(iNumFiles))

      ! Second pass: et file names
      iFile = 0
      iHandlePath = file$first
      do
        iLength = getfileinfoqq(trim(sInputPath) // cDelim // "*", tPathInfo, iHandlePath)
        if(iHandlePath == file$last .or. iHandlePath == file$error) exit
        if(iand(tPathInfo % permit, file$dir) > 0) then
          if(len_trim(tPathInfo % name) == 6) then
            iHandle = 0
            do
              iLength = getfileinfoqq( &
                trim(sInputPath) // cDelim // trim(tPathInfo % name) // cDelim // "*.fsr", &
                tFileInfo, &
                iHandle &
              )
              if(iHandle == file$last .or. iHandle == file$error) exit
              if(iand(tInfo % permit, file$dir) == 0) then
                iFile = iFile + 1
                svFiles(iFile) = trim(sInputPath) // cDelim // trim(tPathInfo % name) // cDelim // trim(tFileInfo % name)
              end if
            end do
          end if
        end if
      end do

    case default

      iRetCode = 1

    end select

  end function FindDataFiles


  function fsGet(this) result(iRetCode)

    ! Routine arguments
    class(FastSonicData), intent(inout) :: fsGet
    integer                             :: iRetCode

    ! Locals
    integer :: iLUN
    integer :: iErrCode
    integer :: iNumData

    ! Assume success (will falsify on failure)
    iRetCode = 0

    ! Try accessing file
    open(newunit=iLUN, status='old', action='read', access='stream', iostat=iErrCode)
    if(iErrCode /= 0) then
      iRetCode = 1
      return
    end if
    close(iLUN)

  end function fsGet

end module files
