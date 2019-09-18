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


function encode(iU, iV, iW, iT, analog, rvMultiplier, rvOffset, rvMinPlausible, rvMaxPlausible)

    # An old quadruple exists: save it first
    threshold = Int32(-9000)
    if iU > threshold
        rU = iU/100.0f0
    else
        rU = -9999.9f0
    end
    if iV > threshold
        rV = iV/100.0f0
    else
        rV = -9999.9f0
    end
    if iW > threshold
        rW = iW/100.0f0
    else
        rW = -9999.9f0
    end
    if iT > threshold
        rT = iT/100.0f0
    else
        rT = -9999.9f0
    end

    # Convert and save analog data
    analogConverted = []
    if iNumQuantities > 0
        for iQuantity in 1:iNumQuantities
            rawValue = analog[ivChannel[iQuantity]]
            if rawValue > -9000
                physicalValue = rvMultiplier[iQuantity] * rawValue + rvOffset[iQuantity]
                if physicalValue < rvMinPlausible[iQuantity] || physicalValue > rvMaxPlausible[iQuantity]
                    physicalValue = -9999.9f0
                end
            else
                physicalValue = -9999.9f0
            end
            append!(analogConverted, physicalValue)
        end
    end

    return (rU, rV, rW, rT, analogConverted)

end


function getLineType(dataString)

    firstQuantityName = dataString[4:5]
    if firstQuantityName == "x "
        lineType = 1
    elseif firstQuantityName == "a0" || firstQuantityName == "e1"
        lineType = 2
    elseif firstQuantityName == "a4" || firstQuantityName == "e5"
        lineType = 3
    elseif firstQuantityName == "c0" || firstQuantityName == "c1"
        lineType = 4
    else
        lineType = 0
    end
    return lineType

end


function guessLineType(dataString)

    if occursin("x ", dataString) || occursin("y ", dataString) || occursin("z ", dataString) || occursin("t ", dataString)
        typeGuess = 1
    elseif occursin("a0", dataString) || occursin("a1", dataString) || occursin("a2", dataString) || occursin("a3", dataString)
        typeGuess = 2
    elseif occursin("e1", dataString) || occursin("e2", dataString) || occursin("e3", dataString) || occursin("e4", dataString)
        typeGuess = 2
    elseif occursin("a4", dataString) || occursin("a5", dataString) || occursin("a6", dataString) || occursin("a7", dataString)
        typeGuess = 3
    elseif occursin("e5", dataString) || occursin("e6", dataString) || occursin("e7", dataString) || occursin("e8", dataString)
        typeGuess = 3
    elseif occursin("c0", dataString) || occursin("c1", dataString)
        typeGuess = 4
    else
        typeGuess = 0
    end
    return typeGuess

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
        data = readlines(f)
        lines = split(data[1], '\r')
        U = []
        V = []
        W = []
        T = []
        analogData = []
        firstLine = true
        iU = -9999
        iV = -9999
        iW = -9999
        iT = -9999
        analog = [-9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999]
        numLines = length(lines)
        if lines[numLines] == ""
            numLines -= 1
        end
        if numLines > 0
            for lineIdx in 1:numLines
                line = lines[lineIdx]
                fields = split(line, ',')
                numFields = size(fields)[1]
                numCommas = numFields - 1
                println(numCommas)
                if numFields == 2
                    dataString = fields[2,1]
                    if length(dataString) != 42
                        guessedLineType = guessLineType(dataString)
                        if guessedLineType == 1
                            dataString = " M:x = -9999 y = -9999 z = -9999 t = -9999"
                        elseif guessedLineType == 2
                            dataString = " M:e1= -9999 e2= -9999 e3= -9999 e4= -9999"
                        elseif guessedLineType == 3
                            dataString = " M:e5= -9999 e6= -9999 e7= -9999 e8= -9999"
                        elseif guessedLineType == 4
                            dataString = " M:c1= -9999 c2= -9999"
                        end
                    end
                else
                    guessedLineType = guessLineType(dataString)
                    if guessedLineType == 1
                        dataString = " M:p = -9999 q = -9999 r = -9999 t = -9999"
                    elseif guessedLineType == 2
                        dataString = " M:b1= -9999 b2= -9999 b3= -9999 b4= -9999"
                    elseif guessedLineType == 3
                        dataString = " M:b5= -9999 b6= -9999 b7= -9999 b8= -9999"
                    elseif guessedLineType == 4
                        dataString = " M:b9= -9999 ba= -9999"
                    end
                end
                lineType = getLineType(dataString)
                lastLineQuadruple = false
                if lineType == 1
                    if !firstLine
                        rU, rV, rW, rT, analogConverted = encode(iU, iV, iW, iT, analog, rvMultiplier, rvOffset, rvMinPlausible, rvMaxPlausible)
                        append!(U, rU)
                        append!(V, rV)
                        append!(W, rW)
                        append!(T, rT)
                        append!(analogData, analogConverted)
                    end
                    # Start a new line
                    firstLine = false
                    iU = parse(Int, dataString[17:22])
                    iV = parse(Int, dataString[ 7:12])
                    iW = parse(Int, dataString[27:32])
                    iT = parse(Int, dataString[37:42])
                    analog = [-9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999]
                    lastLineQuadruple = true
                elseif lineType == 2
                    analog[ 1] = parse(Int, dataString[ 7:12])
                    analog[ 2] = parse(Int, dataString[17:22])
                    analog[ 3] = parse(Int, dataString[27:32])
                    analog[ 4] = parse(Int, dataString[37:42])
                elseif lineType == 3
                    analog[ 5] = parse(Int, dataString[ 7:12])
                    analog[ 6] = parse(Int, dataString[17:22])
                    analog[ 7] = parse(Int, dataString[27:32])
                    analog[ 8] = parse(Int, dataString[37:42])
                    lastLineQuadruple = false
                elseif lineType == 4
                    analog[ 9] = parse(Int, dataString[ 7:12])
                    analog[10] = parse(Int, dataString[17:22])
                    lastLineQuadruple = false
                end
            end
            if lineType != 1
                rU, rV, rW, rT, analogConverted = encode(iU, iV, iW, iT, analog, rvMultiplier, rvOffset, rvMinPlausible, rvMaxPlausible)
                append!(U, rU)
                append!(V, rV)
                append!(W, rW)
                append!(T, rT)
                append!(analogData, analogConverted)
            end
            println(length(U), " - ", length(analogData), " (",iU,",",iV,",",iW,",",iT,")")
        else
            println("Empty data file")
        end
        exit(0)
    end

    # Save old line

elseif sRawDataForm == "MFC2"   # MeteoFlux Core V2

elseif sRawDataForm == "WR"     # WindRecorder

else

    println("error: Parameter 'RawDataForm' in configuration file is not MFCL, MFC2, or WR")
    exit(3)

end

exit(0)
