module stats_dia

	implicit none
	
	private
	
	! Public interface
	public	:: mean
	
contains

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

end module stats_dia
