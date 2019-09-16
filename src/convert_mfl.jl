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
        append!(svFiles, glob("*", d))
    end
end

for f in svFiles
    println(f)
    data=readlines(f)
    lines = split(data[1], '\r')
    sonicData = []
    for line in lines
        fields = split(line, ',')
        println(size(fields)[1])
        n = size(fields)[1]
        if n == 2
            dataString = fields[2,1]
        else
            dataString = " M:x = -9999 y = -9999 z = -9999 T = -9999"
        end
        println(dataString)
        u = dataString[17:22]
        v = dataString[ 7:12]
        w = dataString[27:32]
        T = dataString[37:42]
        println(u, v, w, T)
    end
end

exit(0)
