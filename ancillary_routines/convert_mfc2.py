import os
import sys
import glob
import math

if __name__ == "__main__":
	
	# Get parameters
	if len(sys.argv) != 4:
		print("convert_mfc2.py - Procedure converting MeteoFlux Core V2 raw data to FastSonic form\n")
		print("Usage:\n")
		print("    python convert_mfc2.py <MFC2_Data_Path> <Out_Data_Path> <Dia_File>\n")
		print("Copyright 2019 by Servizi Territorio srl")
		print("                  All rights reserved\n")
		sys.exit(1)
	mfc2_path = sys.argv[1]
	out_path  = sys.argv[2]
	dia_file  = sys.argv[3]

	# Iterate over sub-directories assuming a METEK style directory structure
	dirs = glob.glob(os.path.join(mfc2_path, "*"))
	p = open(dia_file, 'w')
	p.write("file, inv, ill, Vel, Dir, W.Avg, TS.Avg\n")
	for d in sorted(dirs):
		
		# Iterate over files in sub-directories
		files = sorted(glob.glob(os.path.join(d, "*")))
		for file_name in files:
			
			# Read file into a byte string
			f = open(file_name, "rb")
			data = f.read()
			f.close()
			totData = len(data) / 10
			if totData < 33000:
				continue
			
			# Decode byte string to actual sonic quadruples
			time_stamp = []
			u          = []
			v          = []
			w          = []
			t          = []
			for line_idx in range(int(totData)):
				from_idx = 2*(5*line_idx + 0)
				tm_value = int.from_bytes(data[from_idx:from_idx+2], byteorder="little", signed=True)
				from_idx = 2*(5*line_idx + 1)
				d0       = int.from_bytes(data[from_idx:from_idx+2], byteorder="little", signed=True)
				from_idx = 2*(5*line_idx + 2)
				d1       = int.from_bytes(data[from_idx:from_idx+2], byteorder="little", signed=True)
				from_idx = 2*(5*line_idx + 3)
				d2       = int.from_bytes(data[from_idx:from_idx+2], byteorder="little", signed=True)
				from_idx = 2*(5*line_idx + 4)
				d3       = int.from_bytes(data[from_idx:from_idx+2], byteorder="little", signed=True)
				if tm_value <= 5000:
					time_stamp.append(int(tm_value))
					u.append(d1 / 100.0)
					v.append(d0 / 100.0)
					w.append(d2 / 100.0)
					t.append(d3 / 100.0)

			# Write data, while computing basic stats meanwhile
			out_file = os.path.join(out_path, os.path.basename(file_name) + ".csv")
			uAvg = 0.
			vAvg = 0.
			wAvg = 0.
			tsAvg = 0.
			nSonic = 0
			g = open(out_file, "w")
			g.write("time.stamp, u, v, w, t\n")
			num_invalid = 0
			num_ill_formed = 0
			go = False
			idx = 0
			for line_idx in range(len(time_stamp)):
				uAvg += u[line_idx]
				vAvg += v[line_idx]
				wAvg += w[line_idx]
				tsAvg += t[line_idx]
				nSonic += 1
				g.write("%d, %6.2f, %6.2f, %6.2f, %6.2f\n" % (time_stamp[line_idx], u[line_idx], v[line_idx], w[line_idx], t[line_idx]))

			g.close()

			vel = math.sqrt((uAvg/nSonic)**2 + (vAvg/nSonic)**2)
			dir = math.atan2(-(uAvg/nSonic),-(vAvg/nSonic))*180.0/3.1415927
			if dir < 0.:
				dir += 360.
			wAvg /= nSonic
			tsAvg /= nSonic
			p.write("%s,%5d,%5d,%7.3f,%7.3f,%7.3f,%7.3f\n" % (file_name, num_invalid, num_ill_formed, vel, dir, wAvg, tsAvg))
			print("Processed " + file_name + " (%5d invalid USA1 lines - %5d ill-formed lines - Vel = %7.3f - Dir = %7.3f)" % (num_invalid, num_ill_formed, vel, dir))

	p.close()
