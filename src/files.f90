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


  function fsGet(sFileName, rvTimeStamp, rvU, rvV, rvW, rvT, rmQuantity, svQuantity) result(iRetCode)

    ! Routine arguments
    real(4), dimension(:), allocatable, intent(inout)       :: rvTimeStamp
    real(4), dimension(:), allocatable, intent(inout)       :: rvU
    real(4), dimension(:), allocatable, intent(inout)       :: rvV
    real(4), dimension(:), allocatable, intent(inout)       :: rvW
    real(4), dimension(:), allocatable, intent(inout)       :: rvT
    real(4), dimension(:,:), allocatable, intent(inout)     :: rmQuantity
    character(8), dimension(:), allocatable, intent(inout)  :: svQuantity
    character(len=*), intent(in)                            :: sFileName
    integer                                                 :: iRetCode

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
    iErrCode = fsClean(rvTimeStamp, rvU, rvV, rvW, rvT, rmQuantity, svQuantity)
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 5
      return
    end if
    allocate(rvTimeStamp(iNumData))
    allocate(rvU(iNumData))
    allocate(rvV(iNumData))
    allocate(rvW(iNumData))
    allocate(rvT(iNumData))
    allocate(rmQuantity(iNumData, iNumQuantities))
    allocate(svQuantity(iNumQuantities))

    ! Gather quantity names
    do iQuantity = 1, iNumQuantities
      read(iLUN, iostat=iErrCode) svQuantity(iQuantity)
      if(iErrCode /= 0) then
        close(iLUN)
        iRetCode = 6
        return
      end if
    end do

    ! Get actual data
    read(iLUN, iostat=iErrCode) rvTimeStamp
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 7
      return
    end if
    read(iLUN, iostat=iErrCode) rvU
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 8
      return
    end if
    read(iLUN, iostat=iErrCode) rvV
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 9
      return
    end if
    read(iLUN, iostat=iErrCode) rvW
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 10
      return
    end if
    read(iLUN, iostat=iErrCode) rvT
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 11
      return
    end if
    read(iLUN, iostat=iErrCode) rmQuantity
    if(iErrCode /= 0) then
      close(iLUN)
      iRetCode = 12
      return
    end if

     ! Leave
    close(iLUN)

  end function fsGet


  function fsClean(rvTimeStamp, rvU, rvV, rvW, rvT, rmQuantity, svQuantity) result(iRetCode)

        ! Routine arguments
        real(4), dimension(:), allocatable, intent(inout)       :: rvTimeStamp
        real(4), dimension(:), allocatable, intent(inout)       :: rvU
        real(4), dimension(:), allocatable, intent(inout)       :: rvV
        real(4), dimension(:), allocatable, intent(inout)       :: rvW
        real(4), dimension(:), allocatable, intent(inout)       :: rvT
        real(4), dimension(:,:), allocatable, intent(inout)     :: rmQuantity
        character(8), dimension(:), allocatable, intent(inout)  :: svQuantity
        integer                                                 :: iRetCode

        ! Locals
        integer :: iLUN
        integer :: iErrCode
        integer :: iNumData

        ! Assume success (will falsify on failure)
        iRetCode = 0

        ! Release workspace, if any
        if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
        if(allocated(rvU))         deallocate(rvU)
        if(allocated(rvV))         deallocate(rvV)
        if(allocated(rvW))         deallocate(rvW)
        if(allocated(rvT))         deallocate(rvT)
        if(allocated(rmQuantity))  deallocate(rmQuantity)
        if(allocated(svQuantity))  deallocate(svQuantity)

  end function fsClean

end module files
