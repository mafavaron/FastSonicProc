program test

  use cudafor

  implicit none

  ! Locals
  real, dimension(:), allocatable         :: a
  real, dimension(:), allocatable, device :: d_a
  integer                                 :: numElements

  ! Initialize
  numElements = 128
  allocate(a(numElements))
  allocate(d_a(numElements))

  ! Leave
  deallocate(d_a)
  deallocate(a)

end program test
