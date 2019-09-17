# Julia script to convert data files from MeteoFlux Core Lite to FastSonic form

using Glob
using IniFile


function findDataFiles(sInputPath, sTypeOfPath)
    svFiles = []
    if sTypeOfPath == "Metek" || sTypeOfPath == "M"
        dirs = glob("*", sInputPath)
        for d in dirs
            if isdir(d)
                append!(svFiles, glob("*", d))
            end
        end
    elseif sTypeOfPath == "Flat" || sTypeOfPath == "F"
        svFiles = glob("*", sInputPath)
    end
    return svFiles
end

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
    append!(ivChannel, parse(Int64, get(cfg, sSectionName, "Channel", "-9999")))
    append!(svUnit, get(cfg, sSectionName, "Unit", ""))
    append!(rvMultiplier, parse(Float64, get(cfg, sSectionName, "Multiplier", "-9999.9")))
    append!(rvOffset, parse(Float64, get(cfg, sSectionName, "Offset", "-9999.9")))
    append!(rvMinPlausible, parse(Float64, get(cfg, sSectionName, "MinPlausible", "-9999.9")))
    append!(rvMaxPlausible, parse(Float64, get(cfg, sSectionName, "MaxPlausible", "-9999.9")))
    if svName[end] == "" || ivChannel[end] < 1 || ivChannel[end] > 10 || rvMultiplier[end] < -9000.0 || rvOffset[end] < -9000.0 || rvMinPlausible[end] < -9000.0 || rvMaxPlausible[end] < -9000.0
        println("error: Quantity ($iQuantity) contains invalid data")
        exit(3)
    end
end

# Locate files to process
svFiles = findDataFiles(sInputPath, "Metek")

# Perform data conversion
if sRawDataForm == "MFCL"   # MeteoFlux Core Lite (Arduino-based)

    for f in svFiles
        println(f)
        data=readlines(f)
        lines = split(data[1], '\r')
        U = []
        V = []
        W = []
        T = []
        analogData = []
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
            lastLineQuadruple = false
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
                # Start a new line
                firstLine = false
                iU = int(dataString[17:22])
                iV = int(dataString[ 7:12])
                iW = int(dataString[27:32])
                iT = int(dataString[37:42])
                analog = (-9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9)
                lastLineQuadruple = true
            elseif lineType == "x "
                iU = int(dataString[17:22])
                iV = int(dataString[ 7:12])
                iW = int(dataString[27:32])
                iT = int(dataString[37:42])
                analog = (-9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9, -9999.9)
                lastLineQuadruple = true
            elseif lineType == "e1" || lineType == "a0"
                analog[ 1] = int(dataString[ 7:12])
                analog[ 2] = int(dataString[17:22])
                analog[ 3] = int(dataString[27:32])
                analog[ 4] = int(dataString[37:42])
            elseif lineType == "e5" || lineType == "a4"
                analog[ 5] = int(dataString[ 7:12])
                analog[ 6] = int(dataString[17:22])
                analog[ 7] = int(dataString[27:32])
                analog[ 8] = int(dataString[37:42])
                lastLineQuadruple = false
            elseif lineType == "c1" || lineType == "c0"
                analog[ 9] = int(dataString[ 7:12])
                analog[10] = int(dataString[17:22])
                lastLineQuadruple = false
            end
        end
    end

    # Save old line

elseif sRawDataForm == "MFC2"   # MeteoFlux Core V2

elseif sRawDataForm == "WR"     # WindRecorder

else

    println("error: Parameter 'RawDataForm' in configuration file is not MFCL, MFC2, or WR")
    exit(3)

end

exit(0)
