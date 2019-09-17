# Julia script to convert data files from MeteoFlux Core Lite to FastSonic form

using Glob
using IniFile

if length(ARGS) != 1
    println("convert_mfl.jl - Julia script for converting MeteoFlux Core Lite data to FastSonic")
    println("")
    println("Usage:")
    println("")
    println("    julia convert_mfl.jl <Ini_File>")
    println("")
    println("Copyright 2019 by Servizi Territorio")
    println("                  This is open source software, covered by the MIT license")
    println("")
    println("Written by: Mauri Favaron")
    println("")
    exit(1)
end
sIniFile = ARGS[1]

# Get configuration
cfg = Inifile()
read(cfg, sIniFile)
# -1- General section
runName = get(cfg, "General", "Name", "Generic")
runSite = get(cfg, "General", "Site", "Generic")
sInputPath = get(cfg, "General", "RawDataPath", "")
sRawDataForm = get(cfg, "General", "RawDataForm", "")
sOutputPath = get(cfg, "General", "FastSonicPath", "")
sTypeOfPath = get(cfg, "General", "TypeOfPath", "?")
ch = get(cfg, "General", "OperatingSystemType", "?")[1]
if ch == 'W'
    separator = '\\'
elseif ch == 'U'
    separator = '/'
else
    println("error: Unknown operating system type")
end
# -1- Quantities and Quantity_<N> sections
svName         = []
ivChannel      = []
svUnit         = []
rvMultiplier   = []
rvOffset       = []
rvMinPlausible = []
rvMaxPlausible = []
iNumQuantities = parse(Int64, get(cfg, "Quantities", "NumberOfAdditionalQuantities", "0"))
for iQuantity in 1:iNumQuantities
    sSectionName = "Quantity_" * string(iQuantity)
    append!(svName, get(cfg, sSectionName, "Name", ""))
    append(ivChannel, parse(Int64, get(cfg, sSectionName, "Channel", "-9999")))
    append!(svUnit, get(cfg, sSectionName, "Unit", ""))
    append(rvMultiplier, parse(Float64, get(cfg, sSectionName, "Multiplier", "-9999.9")))
    append(rvOffset, parse(Float64, get(cfg, sSectionName, "Offset", "-9999.9")))
    append(rvMinPlausible, parse(Float64, get(cfg, sSectionName, "MinPlausible", "-9999.9")))
    append(rvMaxPlausible, parse(Float64, get(cfg, sSectionName, "MaxPlausible", "-9999.9")))
    if svName[end] == "" || ivChannel[end] < 1 || ivChannel[end] > 10 || rvMultiplier[end] < -9000.0 || rvOffset[end] < -9000.0 || rvMinPlausible[end] < -9000.0 || rvMaxPlausible[end] < -9000.0
        println("error: Quantity ($iQuantity) contains invalid data")
        exit(3)
    end
end

println(separator)
println(sOutputPath)
exit(0)

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
