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
    U = []
    V = []
    W = []
    T = []
    firstLine = true
    for line in lines
        fields = split(line, ',')
        n = size(fields)[1]
        if n == 2
            dataString = fields[2,1]
            if length(dataString) != 43
                dataString = " M:x = -9999 y = -9999 z = -9999 T = -9999"
            end
        else
            dataString = " M:x = -9999 y = -9999 z = -9999 T = -9999"
        end
        lineType = dataString[4:5]
        if !firstLine
            if lineType == "x "
                # Save old line
                if iU > -9000
                    append!(U, iU/100.0f0)
                else
                    append!(U, -9999.9f0)
                end
                if iV > -9000
                    append!(V, iV/100.0f0)
                else
                    append!(V, -9999.9f0)
                end
                if iW > -9000
                    append!(W, iW/100.0f0)
                else
                    append!(W, -9999.9f0)
                end
                if iT > -9000
                    append!(T, iT/100.0f0)
                else
                    append!(T, -9999.9f0)
                end
            end
            # Start a new
            firstLine = false
            iU = int(dataString[17:22])
            iV = int(dataString[ 7:12])
            iW = int(dataString[27:32])
            iT = int(dataString[37:42])
        elseif lineType == "e1" || lineType == "a0"
            iE1 = int(dataString[ 7:12])
            iE2 = int(dataString[17:22])
            iE3 = int(dataString[27:32])
            iE4 = int(dataString[37:42])
        elseif lineType == "e5" || lineType == "a4"
            iE5 = int(dataString[ 7:12])
            iE6 = int(dataString[17:22])
            iE7 = int(dataString[27:32])
            iE8 = int(dataString[37:42])
        end
    end
    # Save old line
end

exit(0)
