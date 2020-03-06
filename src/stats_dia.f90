module stats_dia

	implicit none
	
	private
	
	! Public interface
	public	:: clean
	public	:: mean
	public	:: stddev
	public	:: cov
	public	:: decompose
	
contains

	! Given a sequence of sonic quadruples, this routine shrinks them so that
	! only valid data are present. The transformation is performed in-place.
	function clean(rvTime, rvU, rvV, rvW, rvT) result(iRetCode)
	
		! Routine arguments
		real, dimension(:), allocatable, intent(inout)	:: rvTime
		real, dimension(:), allocatable, intent(inout)	:: rvU
		real, dimension(:), allocatable, intent(inout)	:: rvV
		real, dimension(:), allocatable, intent(inout)	:: rvW
		real, dimension(:), allocatable, intent(inout)	:: rvT
		integer											:: iRetCode
		
		! Locals
		integer							:: iNumValid
		real, dimension(:), allocatable	:: rvNewTime
		real, dimension(:), allocatable	:: rvNewU
		real, dimension(:), allocatable	:: rvNewV
		real, dimension(:), allocatable	:: rvNewW
		real, dimension(:), allocatable	:: rvNewT
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check parameters (minimal)
		if(
			.not.allocated(rvTime) .or. &
			.not.allocated(rvU) .or. &
			.not.allocated(rvV) .or. &
			.not.allocated(rvW) .or. &
			.not.allocated(rvT) &
		) then
			iRetCode = 1
			return
		end if
		if(size(rvTime) <= 0 .or. size(rvU) <= 0 .or. size(rvV) <= 0 .or. size(rvW) <= 0 .or. size(rvT) <= 0) then
			iRetCode = 2
			return
		end if
		
		! Transfer valid data
		
	end function clean

	function mean(rvTime, rvX, rDeltaTime, rvAvgTime, rvAvgX) result(iRetCode)
	
		! Routine arguments
		real, dimension(:), intent(in)					:: rvTime		! Sequence of seconds in hour (not necessarily in ascending order)
		real, dimension(:), intent(in)					:: rvX			! Signal values corresponding to the times
		real, intent(in)								:: rDeltaTime	! Time step (must be strictly positive)
		real, dimension(:), allocatable, intent(out)	:: rvAvgTime	! Seconds at beginning of each averaging step
		real, dimension(:), allocatable, intent(out)	:: rvAvgX		! Averages, on every time step
		integer											:: iRetCode		! Return code (0 = OK, Non-zero = some problem)
		
		! Locals
		integer								:: iNumSteps
		integer, dimension(:), allocatable	:: ivNumData
		integer								:: i
		integer								:: iIndex
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check parameters
		if(size(rvTime) <= 0 .or. size(rvTime) /= size(rvX) .or. rDeltaTime <= 0.) then
			iRetCode = 1
			return
		end if
		
		! Compute number of steps and use it to reserve workspace
		iNumSteps = ceiling(3600. / rDeltaTime)
		allocate(ivNumData(iNumSteps), rvAvgX(iNumSteps), rvAvgTime(iNumSteps))
		ivNumData = 0
		rvAvgX    = 0.
		
		! Sum step values
		do i = 1, size(rvTime)
			iIndex = floor(rvTime(i) / rDeltaTime) + 1
			ivNumData(iIndex) = ivNumData(iIndex) + 1
			rvAvgX(iIndex)    = rvAvgX(iIndex) + rvX(i)
		end do
		
		! Render averages
		do i = 1, iNumSteps
			if(ivNumData(i) > 0) then
				rvAvgX(i) = rvAvgX(i) / ivNumData(i)
			else
				rvAvgX(i) = -9999.9
			end if
		end do
		
		! Compute time values
		rvAvgTime = [(i*rDeltaTime, i=0, iNumSteps-1)]
		
	end function mean


	function stddev(rvTime, rvX, rDeltaTime, rvAvgTime, rvAvgX) result(iRetCode)
	
		! Routine arguments
		real, dimension(:), intent(in)					:: rvTime		! Sequence of seconds in hour (not necessarily in ascending order)
		real, dimension(:), intent(in)					:: rvX			! Signal values corresponding to the times
		real, intent(in)								:: rDeltaTime	! Time step (must be strictly positive)
		real, dimension(:), allocatable, intent(out)	:: rvAvgTime	! Seconds at beginning of each averaging step
		real, dimension(:), allocatable, intent(out)	:: rvStdDevX	! Standard deviations, on every time step
		integer											:: iRetCode		! Return code (0 = OK, Non-zero = some problem)
		
		! Locals
		integer								:: iNumSteps
		integer, dimension(:), allocatable	:: ivNumData
		real, dimension(:), allocatable		:: rvSumX
		real, dimension(:), allocatable		:: rvSumXX
		integer								:: i
		integer								:: iIndex
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check parameters
		if(size(rvTime) <= 0 .or. size(rvTime) /= size(rvX) .or. rDeltaTime <= 0.) then
			iRetCode = 1
			return
		end if
		
		! Compute number of steps and use it to reserve workspace
		iNumSteps = ceiling(3600. / rDeltaTime)
		allocate(ivNumData(iNumSteps), rvStdDevX(iNumSteps), rvAvgTime(iNumSteps))
		allocate(rvSumX(iNumSteps), rvSumXX(iNumSteps))
		ivNumData = 0
		rvSumX    = 0.
		rvSumXX   = 0.
		
		! Sum step values
		do i = 1, size(rvTime)
			iIndex = floor(rvTime(i) / rDeltaTime) + 1
			ivNumData(iIndex) = ivNumData(iIndex) + 1
			rvSumX(iIndex)    = rvSumX(iIndex)  + rvX(i)
			rvSumXX(iIndex)   = rvSumXX(iIndex) + rvX(i)**2
		end do
		
		! Render averages
		do i = 1, iNumSteps
			if(ivNumData(i) > 0) then
				rvStdDevX(i) = sqrt(rvSumXX(i)/ivNumData(i) - (rvSumX(i)/ivNumData(i))**2)
			else
				rvStdDevX(i) = -9999.9
			end if
		end do
		
		! Compute time values
		rvAvgTime = [(i*rDeltaTime, i=0, iNumSteps-1)]
		
		! Leave orderly
		deallocate(rvSumX, rvSumXX)
		
	end function stddev


	function cov(rvTime, rvX, rvY, rDeltaTime, rvAvgTime, rvCovXY) result(iRetCode)
	
		! Routine arguments
		real, dimension(:), intent(in)					:: rvTime		! Sequence of seconds in hour (not necessarily in ascending order)
		real, dimension(:), intent(in)					:: rvX			! Signal values X corresponding to the times
		real, dimension(:), intent(in)					:: rvY			! Signal values Y corresponding to the times
		real, intent(in)								:: rDeltaTime	! Time step (must be strictly positive)
		real, dimension(:), allocatable, intent(out)	:: rvAvgTime	! Seconds at beginning of each averaging step
		real, dimension(:), allocatable, intent(out)	:: rvCovXY		! Covariance, on every time step
		integer											:: iRetCode		! Return code (0 = OK, Non-zero = some problem)
		
		! Locals
		integer								:: iNumSteps
		integer, dimension(:), allocatable	:: ivNumData
		real, dimension(:), allocatable		:: rvSumX
		real, dimension(:), allocatable		:: rvSumY
		real, dimension(:), allocatable		:: rvSumXY
		integer								:: i
		integer								:: iIndex
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check parameters
		if(size(rvTime) <= 0 .or. size(rvTime) /= size(rvX) .or. size(rvTime) /= size(rvY) .or. rDeltaTime <= 0.) then
			iRetCode = 1
			return
		end if
		
		! Compute number of steps and use it to reserve workspace
		iNumSteps = ceiling(3600. / rDeltaTime)
		allocate(ivNumData(iNumSteps), rvCovXY(iNumSteps), rvAvgTime(iNumSteps))
		allocate(rvSumX(iNumSteps), rvSumY(iNumSteps), rvSumXY(iNumSteps))
		ivNumData = 0
		rvSumX    = 0.
		rvSumXY   = 0.
		
		! Sum step values
		do i = 1, size(rvTime)
			iIndex = floor(rvTime(i) / rDeltaTime) + 1
			ivNumData(iIndex) = ivNumData(iIndex) + 1
			rvSumX(iIndex)    = rvSumX(iIndex)  + rvX(i)
			rvSumY(iIndex)    = rvSumY(iIndex)  + rvY(i)
			rvSumXY(iIndex)   = rvSumXY(iIndex) + rvX(i)*rvY(i)
		end do
		
		! Render averages
		do i = 1, iNumSteps
			if(ivNumData(i) > 0) then
				rvCovXY(i) = (rvSumXY(i)/ivNumData(i) - (rvSumX(i)/ivNumData(i))*(rvSumY(i)/ivNumData(i)))
			else
				rvCovXY(i) = -9999.9
			end if
		end do
		
		! Compute time values
		rvAvgTime = [(i*rDeltaTime, i=0, iNumSteps-1)]
		
		! Leave orderly
		deallocate(rvSumX, rvSumY, rvSumXY)
		
	end function cov


	function decompose(rvTime, rvX, rDeltaTime, rvMean, rvResidual) result(iRetCode)
	
		! Routine arguments
		real, dimension(:), intent(in)					:: rvTime		! Sequence of seconds in hour (not necessarily in ascending order)
		real, dimension(:), intent(in)					:: rvX			! Signal values corresponding to the times
		real, intent(in)								:: rDeltaTime	! Time step (must be strictly positive)
		real, dimension(:), allocatable, intent(out)	:: rvMean		! Mean value
		real, dimension(:), allocatable, intent(out)	:: rvResidual	! Difference between original signal and mean
		integer											:: iRetCode		! Return code (0 = OK, Non-zero = some problem)
		
		! Locals
		integer								:: iNumSteps
		integer, dimension(:), allocatable	:: ivNumData
		real, dimension(:), allocatable		:: rvAvgX
		integer								:: i
		integer								:: iIndex
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check parameters
		if(size(rvTime) <= 0 .or. size(rvTime) /= size(rvX) .or. rDeltaTime <= 0.) then
			iRetCode = 1
			return
		end if
		
		! Compute number of steps and use it to reserve workspace
		iNumSteps = ceiling(3600. / rDeltaTime)
		if(allocated(rvMean)) deallocate(rvMean)
		if(allocated(rvResidual)) deallocate(rvResidual)
		if(allocated(rvAvgX)) deallocate(rvAvgX)
		allocate(ivNumData(iNumSteps), rvMean(size(rvTime)), rvResidual(size(rvTime)), rvAvgX(iNumStepa))
		ivNumData = 0
		rvAvgX    = 0.
		
		! Sum step values
		do i = 1, size(rvTime)
			iIndex = floor(rvTime(i) / rDeltaTime) + 1
			ivNumData(iIndex) = ivNumData(iIndex) + 1
			rvAvgX(iIndex)    = rvAvgX(iIndex) + rvX(i)
		end do
		
		! Render averages
		do i = 1, iNumSteps
			if(ivNumData(i) > 0) then
				rvAvgX(i) = rvAvgX(i) / ivNumData(i)
			else
				rvAvgX(i) = -9999.9
			end if
		end do
		
		! Propagate mean to all individual values and compute residuals
		do i = 1, size(rvTime)
			iIndex = floor(rvTime(i) / rDeltaTime) + 1
			rvMean(i) = rvAvgX(iIndex)
			if(rvResidual(i) > -9990. .and. rvMean(i) > -9990.) then
				rvResidual(i) = rvX(i) - rvMean(i)
			end if
		end do
		
	end function decompose

end module stats_dia
