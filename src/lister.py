import os
import sys
import glob

if __name__ == "__main__":
	
	# Get parameters
	if len(sys.argv) != 3:
		print("lister.py - Procedure composing the processing list file for 'ckd'")
		print()
		print("Usage:")
		print()
		print("  python lister.py <path> <output_file_name>")
		print()
		print("Copyright 2019 by Servizi Territorio srl")
		print("                  All rights reserved")
		print()
		sys.exit(1)
	in_path  = sys.argv[1]
	out_file = sys.argv[2]
	
	# Search all files, and write their names to output file
	files = sorted(glob.glob(os.path.join(in_path, "*")))
	if len(files) <= 0:
		print("No files in path")
		sys.exit(2)
	f = open(out_file, "w")
	for file_name in files:
		f.write(file_name)
	f.close()
	print("*** End Job ***")
		
