! Main program: iterate over FastSonic files, get their sonic part,
!               and compute some diagnostic statistics on them. Write
!               a report from results.
!
! By: Patrizia M. Favaron
!
program SonicDiagnostics

	use files
	use stats_dia

	implicit none

	! Locals
	character(len=256)  :: sInputPath
	character(len=256)  :: sOutputPath
	integer             :: iRetCode
	real                :: rTimeBegin
	real                :: rTimeEnd
	real                :: rMaxSec
	integer             :: i
	integer             :: iMinute, iSecond
	character(len=256), dimension(:), allocatable :: svFiles
	real(4), dimension(:), allocatable            :: rvTimeStamp
	real(4), dimension(:), allocatable            :: rvU
	real(4), dimension(:), allocatable            :: rvV
	real(4), dimension(:), allocatable            :: rvW
	real(4), dimension(:), allocatable            :: rvT
	real(4), dimension(:), allocatable            :: rvVel
	real(4), dimension(:), allocatable            :: rvAvgTime
	real(4), dimension(:), allocatable            :: rvAvgVel
	real(4), dimension(:,:), allocatable          :: rmQuantity
	character(8), dimension(:), allocatable       :: svQuantity
	integer, dimension(1)                         :: ivPos
	integer             :: iDateStart
	character(len=4)    :: sYear
	character(len=2)    :: sMonth
	character(len=2)    :: sDay
	character(len=2)    :: sHour
	character(len=32)   :: sDateTime

	! Get command arguments
	if(command_argument_count() /= 2) then
		print *, "wdia - Ultrasonic anemometer raw data diagnostic procedure"
		print *
		print *, "error:: Invalid command line"
		print *
		print *, "Usage:"
		print *
		print *, "  ./wdia <Input_Path> <Output_File>"
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

		! Get date and hour from file name
		iDateStart = len_trim(svFiles(i)) - 14
		sYear  = svFiles(i)(iDateStart:iDateStart+3)
		sMonth = svFiles(i)(iDateStart+4:iDateStart+5)
		sDay   = svFiles(i)(iDateStart+6:iDateStart+7)
		sHour  = svFiles(i)(iDateStart+8:iDateStart+9)
		write(sDateTime, "(a4,2('-',a2),1x,a2,':00:00')") sYear, sMonth, sDay, sHour

		! Get file
		iRetCode = fsGet(svFiles(i), rvTimeStamp, rvU, rvV, rvW, rvT, rmQuantity, svQuantity)
		if(iRetCode /= 0) then
			print *, 'error:: File termination before completing data read'
			stop
		end if
		
		! Combine horizontal components into a unique wind speed
		if(allocated(rvVel)) deallocate(rvVel)
		allocate(rvVel(size(rvU)))
		rvVel = sqrt(rvU**2 + rvV**2)
		
		! Compute the 3s mean of wind speed (max of 3s moving average would be the WMO definition of wind gust)
		iRetCode = mean(rvTimeStamp, rvVel, 3., rvAvgTime, rvAvgVel)
		if(iRetCode /= 0) then
			print *, 'warning:: Some problem computing 3s mean'
			cycle
		end if
		
		! Find maximum
		ivPos = maxloc(rvAvgVel)
		rMaxSec = rvAvgTime(ivPos(1))
		iSecond = floor(rMaxSec)
		iMinute = (iSecond / 60)
		iSecond = iSecond - iMinute * 60
		
		! Print
		write(*, "(a4,2('-',a2),1x,a2,2(':',i2.2),',',f8.2)") sYear, sMonth, sDay, sHour, iMinute, iSecond, rMaxSec

	end do

	! Time elapsed counts
	call cpu_time(rTimeEnd)
	print *, "*** END JOB *** (Time elapsed:", rTimeEnd - rTimeBegin, ")"

end program SonicDiagnostics
