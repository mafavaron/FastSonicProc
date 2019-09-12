fp.exe : fp.obj
	pgfortran -Mcuda -o fp.exe fp.obj

fsr.exe : fsr.obj
	pgfortran -Mcuda -o fsr.exe fsr.obj

fp.obj : fp.f90
	pgfortran -Mcuda -c fp.f90

fsr.obj : fsr.f90
	pgfortran -Mcuda -c fsr.f90
