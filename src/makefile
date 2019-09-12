fp.exe : fp.obj
	pgfortran -Mcuda -o fp.exe fp.obj

fp_wide.exe : fp_wide.obj
	pgfortran -Mcuda -o fp_wide.exe fp_wide.obj

fsr.exe : fsr.obj
	pgfortran -Mcuda -o fsr.exe fsr.obj

fsr_wide.exe : fsr_wide.obj
	pgfortran -Mcuda -o fsr_wide.exe fsr_wide.obj

fp.obj : fp.f90
	pgfortran -Mcuda -c fp.f90

fp_wide.obj : fp_wide.f90
	pgfortran -Mcuda -c fp_wide.f90

fsr.obj : fsr.f90
	pgfortran -Mcuda -c fsr.f90

fsr_wide.obj : fsr_wide.f90
	pgfortran -Mcuda -c fsr_wide.f90
