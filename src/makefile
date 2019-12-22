fp.exe : fp.obj
	pgfortran -Mcuda -o fp.exe fp.obj

fsr.exe : fsr.obj files.obj stats.obj
	pgfortran -Mcuda -o fsr.exe fsr.obj files.obj stats.obj

wdia.exe : wdia.obj files.obj stats_dia.obj
	pgfortran -Mcuda -o wdia.exe wdia.obj files.obj stats_dia.obj

fp.obj : fp.f90
	pgfortran -Mcuda -c -fast fp.f90

fsr.obj : fsr.f90 files.mod stats.mod
	pgfortran -Mcuda -c -fast fsr.f90

wdia.obj : wdia.f90 files.mod stats_dia.mod
	pgfortran -Mcuda -c -fast wdia.f90

files.obj files.mod : files.f90
	pgfortran -Mcuda -c -fast files.f90

stats.obj stats.mod : stats.f90
	pgfortran -Mcuda -c -fast stats.f90

stats_dia.obj stats_dia.mod : stats_dia.f90
	pgfortran -Mcuda -c -fast stats_dia.f90
