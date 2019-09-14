# Julia script to convert data files from MeteoFlux Core Lite to FastSonic form

using Glob

if length(ARGS) != 2
    println("convert_mfl.jl - Julia script for converting MeteoFlux Core Lite data to FastSonic")
    println("")
    println("Usage:")
    println("")
    println("    julia convert_mfl.jl <MFL_Path> <FSE_Path>")
    println("")
    println("Copyright 2019 by Servizi Territorio")
    println("                  This is open source software, covered by the MIT license")
    println("")
    println("Written by: Mauri Favaron")
    println("")
    exit(1)
end
sInputPath = ARGS[1]
sOutputPath = ARGS[2]

# Locate files to process
svFiles = []
dirs = glob("*", sInputPath)
for d in dirs
    if isdir(d)
        println(d)
        append!(svFiles, glob("*", d))
    end
end

for f in svFiles
    println(f)
end

exit(0)
