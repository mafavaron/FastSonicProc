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
    real(4), dimension(:), allocatable, public      :: rvTimeStamp
    real(4), dimension(:), allocatable, public      :: rvU
    real(4), dimension(:), allocatable, public      :: rvV
    real(4), dimension(:), allocatable, public      :: rvW
    real(4), dimension(:), allocatable, public      :: rvT
    real(4), dimension(:,:), allocatable, public    :: rmQuantity
    character(8), dimension(:), allocatable, public :: svQuantity
  end type FastSonicData

  ! Public constants
  integer, parameter  :: PATH$FLAT  = 1
  integer, parameter  :: PATH$METEK = 2

  ! Public interface
  public  :: FindDataFiles
  Public  :: PATH$FLAT
  Public  :: PATH$METEK
  public  :: FastSonicData
  public  :: fsClean
  public  :: fsGet

contains

  ! Map FastSonic files in a user-given directory
  function FindDataFiles(sInputPath, svFiles, iPathType, lUnixDelimiter) result(iRetCode)

    ! Routine arguments
    character(len=*), intent(in)                                :: sInputPath
    character(len=256), dimension(:), allocatable, intent(out)  :: svFiles
    integer, optional, intent(in)                               :: iPathType      ! Default: PATH$METEK
    logical, optional, intent(in)                               :: lUnixDelimiter ! Default: .TRUE.
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
        cDelim = char(92) ! Backslash, assuming "non-UNIX" actually means "Microsoft Windows"
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
              if(iand(tFileInfo % permit, file$dir) == 0) then
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
              if(iand(tFileInfo % permit, file$dir) == 0) then
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


  function fsGet(this, sFileName) result(iRetCode)

    ! Routine arguments
    type(FastSonicData), intent(inout) :: this
    character(len=*), intent(in)        :: sFileName
    integer                             :: iRetCode

    ! Locals
    integer     :: iLUN
    integer     :: iErrCode
    integer     :: iNumData
    integer(2)  :: iNumQuantities
    integer     :: iQuantity

    ! Assume success (will falsify on failure)
    iRetCode = 0

    ! Try accessing file
    open(newunit=iLUN, file=sFileName, status='old', action='read', access='stream', iostat=iErrCode)
    if(iErrCode /= 0) then
      iRetCode = 1
      return
    end if

    ! Get number of data and use it to reserve workspace
    read(iLUN, iostat=iErrCode) iNumData
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 2
      return
    end if
    if(iNumData <= 0) then
      close(iLUN)
      iRetCode = 3
      return
    end if
    read(iLUN, iostat=iErrCode) iNumQuantities
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 4
      return
    end if
    iErrCode = fsClean(this)
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 5
      return
    end if
    allocate(this % rvTimeStamp(iNumData))
    allocate(this % rvU(iNumData))
    allocate(this % rvV(iNumData))
    allocate(this % rvW(iNumData))
    allocate(this % rvT(iNumData))
    allocate(this % rmQuantity(iNumData, iNumQuantities))
    allocate(this % svQuantity(iNumQuantities))

    ! Gather quantity names
    do iQuantity = 1, iNumQuantities
      read(iLUN, iostat=iErrCode) this % svQuantity(iQuantity)
      if(iErrCode /= 0) then
        close(iLUN)
        iRetCode = 6
        return
      end if
    end do

    ! Get actual data
    read(iLUN, iostat=iErrCode) this % rvTimeStamp
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 7
      return
    end if
    read(iLUN, iostat=iErrCode) this % rvU
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 8
      return
    end if
    read(iLUN, iostat=iErrCode) this % rvV
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 9
      return
    end if
    read(iLUN, iostat=iErrCode) this % rvW
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 10
      return
    end if
    read(iLUN, iostat=iErrCode) this % rvT
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 11
      return
    end if
    read(iLUN, iostat=iErrCode) this % rmQuantity
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 12
      return
    end if
    print *, minval(this % rmQuantity(:,1)), maxval(this % rmQuantity(:,1))
    print *, minval(this % rmQuantity(:,2)), maxval(this % rmQuantity(:,2))
    print *, minval(this % rmQuantity(:,3)), maxval(this % rmQuantity(:,3))

     ! Leave
    close(iLUN)

  end function fsGet


  function fsClean(this) result(iRetCode)

        ! Routine arguments
        type(FastSonicData), intent(inout) :: this
        integer                             :: iRetCode

        ! Locals
        integer :: iLUN
        integer :: iErrCode
        integer :: iNumData

        ! Assume success (will falsify on failure)
        iRetCode = 0

        ! Release workspace, if any
        if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
        if(allocated(this % rvU))         deallocate(this % rvT)
        if(allocated(this % rvV))         deallocate(this % rvV)
        if(allocated(this % rvW))         deallocate(this % rvW)
        if(allocated(this % rvT))         deallocate(this % rvT)
        if(allocated(this % rmQuantity))  deallocate(this % rmQuantity)
        if(allocated(this % svQuantity))  deallocate(this % svQuantity)

  end function fsClean

end module files
