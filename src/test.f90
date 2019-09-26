program test

  use cudafor, gpusum => sum

  implicit none

  ! Locals
  real, dimension(:), allocatable          :: a
  real, dimension(:), allocatable, managed :: d_a
  integer                                  :: numElements
  integer                                  :: iState

  ! Initialize
  numElements = 128
  allocate(a(numElements))
  allocate(d_a(numElements))

  d_a = 1.0
  iState = cudaDeviceSynchronize()
  print *, sum(d_a)
  print *, gpusum(d_a)

  ! Leave
  deallocate(d_a)
  deallocate(a)

end program test
