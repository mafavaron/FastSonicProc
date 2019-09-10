fp.exe : main.obj
	pgfortran -Mcuda -o fp.exe main.obj

main.obj : main.f90
	pgfortran -Mcuda -c main.f90
