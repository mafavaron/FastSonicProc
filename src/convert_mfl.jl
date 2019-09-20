# Julia script to convert data files from MeteoFlux Core Lite to FastSonic form

using Glob
using IniFile
using Printf


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


function getMetekSubdirs(sInputPath)
    dirs = glob("*", sInputPath)
    dirNames = []
    for d in dirs
        if isdir(d)
            append!(dirNames, d)
        end
    end
    return dirNames
end


function replicateDirStructure(sInputPath, sTypeOfPath, sOutputPath, separator)
    if !isdir(sOutputPath)
        mkdir(sOutputPath)
    end
    if sTypeOfPath == "Metek" || sTypeOfPath == "M"
        metekSubdirs = getMetekSubdirs(sInputPath)
        for dir in metekSubdirs
            subDir = sOutputPath * separator * dir
            if !isdir(subDir)
                mkdir(subDir)
            end
        end
    end
end


function generateOutFileName(sInputFileName, sTypeOfPath, sOutputPath, separator)
    sBaseName = basename(sInputFileName)
    if sTypeOfPath == "M" || sTypeOfPath == "Metek"
        sSubDir = sBaseName[1:6]
        sOutputFileName = sOutputPath * separator * sSubDir * separator * sBaseName * ".fsr"
    else
        sOutputFileName = sOutputPath * separator * sBaseName * ".fsr"
    end
    return sOutputFileName
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


function getLineType2(dataString)

    firstQuantityName = dataString[3:4]
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
sensorId = get(cfg, "General", "Sensor", "uSonic-3")
if sensorId == "uSonic-3"
    flipReference = false
elseif sensorId == "USA-1"
    flipReference = true
else
    flipReference = false
end
sInputPath = get(cfg, "General", "RawDataPath", "")
sRawDataForm = get(cfg, "General", "RawDataForm", "")
sOutputPath = get(cfg, "General", "FastSonicPath", "")
sTypeOfPath = get(cfg, "General", "TypeOfPath", "?")
sDiaFile = get(cfg, "General", "DiagnosticFile", "diag.dat")
sReportFile = get(cfg, "General", "ExecutionReport", "report.dat")
ch = get(cfg, "General", "OperatingSystemType", "?")[1]
if ch == 'W'
    separator = '\\'
elseif ch == 'U'
    separator = '/'
else
    println("error: Unknown operating system type")
end
sInvalidDataFate = get(cfg, "General", "InvalidDataFate", "Keep")
# -1- Quantities and Quantity_<N> sections
svName         = String[]
ivChannel      = Int32[]
svUnit         = String[]
rvMultiplier   = Float32[]
rvOffset       = Float32[]
rvMinPlausible = Float32[]
rvMaxPlausible = Float32[]
iNumQuantities = parse(Int64, get(cfg, "Quantities", "NumberOfAdditionalQuantities", "0"))
for iQuantity in 1:iNumQuantities
    sSectionName = "Quantity_" * string(iQuantity)
    push!(svName, get(cfg, sSectionName, "Name", ""))
    append!(ivChannel, parse(Int64, get(cfg, sSectionName, "Channel", "-9999")))
    push!(svUnit, get(cfg, sSectionName, "Unit", ""))
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
if length(svFiles) <= 0
    print("error: No files found in (sub)directories")
    exit(4)
end

# Generate directory structure to receive processed data
replicateDirStructure(sInputPath, sTypeOfPath, sOutputPath, separator)

# Perform data conversion
dia = open(sDiaFile, "w")
rep = open(sReportFile, "w")
println(rep, "File, N.Lines, N.Data.Records, N.Valid.Lines, N.Invalid.Lines")
if sRawDataForm == "MFCL"   # MeteoFlux Core Lite (Arduino-based)

    # Main loop: Iterate over files
    for f in svFiles

        # Get data
        data = readlines(f)
        lines = split(data[1], '\r')

        # Secondary loop: Iterate over lines in file
        U = Float32[]
        V = Float32[]
        W = Float32[]
        T = Float32[]
        analogData = Float32[]
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
        lineType = -1
        numInvalid = 0
        numValid   = 0
        if numLines > 0
            for lineIdx in 1:numLines

                # Divide line in parts, along ',' separator
                line = lines[lineIdx]
                fields = split(line, ',')
                numFields = size(fields)[1]

                # Check the string is potentially valid, that is, it contains two comma-separated blocks...
                iValue1 = -99999
                iValue2 = -99999
                iValue3 = -99999
                iValue4 = -99999
                valid   = false
                numCommas = numFields - 1
                if numFields == 2
                    dataString = fields[2,1]

                    # ... and the length of second block is 42 characters
                    if length(dataString) != 42
                        println(dia, @sprintf(" -W- Data line len. not 42 - Line: %6d -> %s", lineIdx, line))
                        lineType = guessLineType(dataString)
                        if lineType == 1
                            dataString = " M:x = -9999 y = -9999 z = -9999 t = -9999"
                        elseif lineType == 2
                            dataString = " M:e1= -9999 e2= -9999 e3= -9999 e4= -9999"
                        elseif lineType == 3
                            dataString = " M:e5= -9999 e6= -9999 e7= -9999 e8= -9999"
                        elseif lineType == 4
                            dataString = " M:c1= -9999 c2= -9999"
                        end
                        numInvalid += 1
                    else

                        # At this point, line is two comma-separated blocks and second block is 42 characters.
                        # This does not still mean the string contents makes sense: a direct pareseability check
                        # is due.
                        try
                            iValue1 = parse(Int, dataString[ 7:12])
                            iValue2 = parse(Int, dataString[17:22])
                            iValue3 = parse(Int, dataString[27:32])
                            iValue4 = parse(Int, dataString[37:42])
                            numValid += 1
                            valid    = true
                            lineType = getLineType(dataString)
                        catch e
                            println(dia, @sprintf(" -W- Not parsing to numbers - Line: %6d ->%s", lineIdx, line))
                            iValue1 = -9999
                            iValue2 = -9999
                            iValue3 = -9999
                            iValue4 = -9999
                            lineType = guessLineType(dataString)
                            if guessedLineType == 1
                                dataString = " M:x = -9999 y = -9999 z = -9999 t = -9999"
                            elseif guessedLineType == 2
                                dataString = " M:e1= -9999 e2= -9999 e3= -9999 e4= -9999"
                            elseif guessedLineType == 3
                                dataString = " M:e5= -9999 e6= -9999 e7= -9999 e8= -9999"
                            elseif guessedLineType == 4
                                dataString = " M:c1= -9999 c2= -9999"
                            end
                            numInvalid += 1
                        end

                    end

                else

                    # Too few, or too many, commas
                    println(dia, @sprintf(" -W- Num.commas not 1 - Line: %6d -> %s", lineIdx, line))
                    lineType = guessLineType(line)
                    if lineType == 1
                        dataString = " M:x = -9999 y = -9999 z = -9999 t = -9999"
                    elseif lineType == 2
                        dataString = " M:e1= -9999 e2= -9999 e3= -9999 e4= -9999"
                    elseif lineType == 3
                        dataString = " M:e5= -9999 e6= -9999 e7= -9999 e8= -9999"
                    elseif lineType == 4
                        dataString = " M:c1= -9999 c2= -9999"
                    end
                    numInvalid += 1

                end
                lastLineQuadruple = false
                if lineType == 1
                    if !firstLine
                        rU, rV, rW, rT, analogConverted = encode(iU, iV, iW, iT, analog, rvMultiplier, rvOffset, rvMinPlausible, rvMaxPlausible)
                        if sInvalidDataFate == "ExcludeSonicQuadruples"
                            if rU >= -9990.0f0 && rV >= -9990.0f0 && rW >= -9990.0f0 && rT >= -9990.0f0
                                append!(U, rU)
                                append!(V, rV)
                                append!(W, rW)
                                append!(T, rT)
                                append!(analogData, analogConverted)
                            end
                        elseif sInvalidDataFate == "ExcludeAll"
                            if rU >= -9990.0f0 && rV >= -9990.0f0 && rW >= -9990.0f0 && rT >= -9990.0f0 && all(x -> x >= -9990.0f0, analogConverted)
                                append!(U, rU)
                                append!(V, rV)
                                append!(W, rW)
                                append!(T, rT)
                                append!(analogData, analogConverted)
                            end
                        elseif sInvalidDataRate == "Keep"
                            append!(U, rU)
                            append!(V, rV)
                            append!(W, rW)
                            append!(T, rT)
                            append!(analogData, analogConverted)
                        else
                            append!(U, rU)
                            append!(V, rV)
                            append!(W, rW)
                            append!(T, rT)
                            append!(analogData, analogConverted)
                        end
                    end
                    # Start a new line
                    firstLine = false
                    if flipReference
                        # USA-1 and old uSonic-3
                        iU = iValue2
                        iV = iValue1
                    else
                        # uSonic-3
                        iU = iValue1
                        iV = iValue2
                    end
                    iW = iValue3
                    iT = iValue4
                    analog = [-9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999]
                    lastLineQuadruple = true
                elseif lineType == 2
                    analog[ 1] = iValue1
                    analog[ 2] = iValue2
                    analog[ 3] = iValue3
                    analog[ 4] = iValue4
                elseif lineType == 3
                    analog[ 5] = iValue1
                    analog[ 6] = iValue2
                    analog[ 7] = iValue3
                    analog[ 8] = iValue4
                    lastLineQuadruple = false
                elseif lineType == 4
                    analog[ 9] = iValue1
                    analog[10] = iValue2
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
            println(dia, f, @sprintf(" -I- %6d data lines parsed", length(U)))
        else
            println(dia, f, " -E- No data in file")
        end

        # Generate floating point time stamps
        deltaTime = 3600.0f0 / numLines
        if length(U) > 1
            timeStamp = collect(range(0.0f0, stop=3600.0f0 - deltaTime, length=length(U)))
        elseif length(U) == 1
            timeStamp = [1800.0f0]
        else
            timeStamp = []
        end

        # Write to file
        sOutputFileName = generateOutFileName(f, sTypeOfPath, sOutputPath, separator)
        nQuantities = length(analogConverted)
        n = length(timeStamp)
        g = open(sOutputFileName, "w")
        write(g, Int32(n))
        write(g, Int16(nQuantities))
        for i in 1:nQuantities
            write(g, ascii((svName[i] * "        ")[1:8]))
        end
        write(g, timeStamp)
        write(g, U)
        write(g, V)
        write(g, W)
        write(g, T)
        for i in 1:nQuantities
            write(g, analogData[i:nQuantities:n*nQuantities])
        end
        close(g)

        println(f, ", Lines=", numLines, ", Records=", n, ", Valid.Lines=", numValid, ", Invalid.Lines=", numInvalid)
        println(rep, f, ", ", numLines, ", ", n, ", ", numValid, ", ", numInvalid)

    end

elseif sRawDataForm == "MFC2"   # MeteoFlux Core V2

elseif sRawDataForm == "WR"     # WindRecorder

    # Main loop: Iterate over files
    for f in svFiles

        # Get data
        lines = readlines(f)

        # Secondary loop: Iterate over lines in file
        U = Float32[]
        V = Float32[]
        W = Float32[]
        T = Float32[]
        analogData = Float32[]
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
        lineType = -1
        numInvalid = 0
        numValid   = 0
        if numLines > 0
            for lineIdx in 1:numLines

                # Divide line in parts, along ',' separator
                line = lines[lineIdx]

                # Check the string is potentially valid, that is, it contains two comma-separated blocks...
                iValue1 = -99999
                iValue2 = -99999
                iValue3 = -99999
                iValue4 = -99999
                valid   = false
                dataString = line

                # ... and the length of second block is 42 characters
                if length(dataString) != 41
                    println(dia, @sprintf(" -W- Data line len. not 41 - Line: %6d -> %s", lineIdx, line))
                    lineType = guessLineType(dataString)
                    if lineType == 1
                        dataString = "M:x = -9999 y = -9999 z = -9999 t = -9999"
                    elseif lineType == 2
                        dataString = "M:e1= -9999 e2= -9999 e3= -9999 e4= -9999"
                    elseif lineType == 3
                        dataString = "M:e5= -9999 e6= -9999 e7= -9999 e8= -9999"
                    elseif lineType == 4
                        dataString = "M:c1= -9999 c2= -9999"
                    end
                    numInvalid += 1
                else

                    # At this point, line is two comma-separated blocks and second block is 42 characters.
                    # This does not still mean the string contents makes sense: a direct pareseability check
                    # is due.
                    try
                        iValue1 = parse(Int, dataString[ 6:11])
                        iValue2 = parse(Int, dataString[16:21])
                        iValue3 = parse(Int, dataString[26:31])
                        iValue4 = parse(Int, dataString[36:41])
                        numValid += 1
                        valid    = true
                        lineType = getLineType2(dataString)
                    catch e
                        println(dia, @sprintf(" -W- Not parsing to numbers - Line: %6d ->%s", lineIdx, line))
                        iValue1 = -9999
                        iValue2 = -9999
                        iValue3 = -9999
                        iValue4 = -9999
                        lineType = guessLineType(dataString)
                        if guessedLineType == 1
                            dataString = "M:x = -9999 y = -9999 z = -9999 t = -9999"
                        elseif guessedLineType == 2
                            dataString = "M:e1= -9999 e2= -9999 e3= -9999 e4= -9999"
                        elseif guessedLineType == 3
                            dataString = "M:e5= -9999 e6= -9999 e7= -9999 e8= -9999"
                        elseif guessedLineType == 4
                            dataString = "M:c1= -9999 c2= -9999"
                        end
                        numInvalid += 1
                    end

                end

                lastLineQuadruple = false
                if lineType == 1
                    if !firstLine
                        rU, rV, rW, rT, analogConverted = encode(iU, iV, iW, iT, analog, rvMultiplier, rvOffset, rvMinPlausible, rvMaxPlausible)
                        if sInvalidDataFate == "ExcludeSonicQuadruples"
                            if rU >= -9990.0f0 && rV >= -9990.0f0 && rW >= -9990.0f0 && rT >= -9990.0f0
                                append!(U, rU)
                                append!(V, rV)
                                append!(W, rW)
                                append!(T, rT)
                                append!(analogData, analogConverted)
                            end
                        elseif sInvalidDataFate == "ExcludeAll"
                            if rU >= -9990.0f0 && rV >= -9990.0f0 && rW >= -9990.0f0 && rT >= -9990.0f0 && all(x -> x >= -9990.0f0, analogConverted)
                                append!(U, rU)
                                append!(V, rV)
                                append!(W, rW)
                                append!(T, rT)
                                append!(analogData, analogConverted)
                            end
                        elseif sInvalidDataRate == "Keep"
                            append!(U, rU)
                            append!(V, rV)
                            append!(W, rW)
                            append!(T, rT)
                            append!(analogData, analogConverted)
                        else
                            append!(U, rU)
                            append!(V, rV)
                            append!(W, rW)
                            append!(T, rT)
                            append!(analogData, analogConverted)
                        end
                    end
                    # Start a new line
                    firstLine = false
                    if flipReference
                        # USA-1 and old uSonic-3
                        iU = iValue2
                        iV = iValue1
                    else
                        # uSonic-3
                        iU = iValue1
                        iV = iValue2
                    end
                    iW = iValue3
                    iT = iValue4
                    analog = [-9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999, -9999]
                    lastLineQuadruple = true
                elseif lineType == 2
                    analog[ 1] = iValue1
                    analog[ 2] = iValue2
                    analog[ 3] = iValue3
                    analog[ 4] = iValue4
                elseif lineType == 3
                    analog[ 5] = iValue1
                    analog[ 6] = iValue2
                    analog[ 7] = iValue3
                    analog[ 8] = iValue4
                    lastLineQuadruple = false
                elseif lineType == 4
                    analog[ 9] = iValue1
                    analog[10] = iValue2
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
            println(dia, f, @sprintf(" -I- %6d data lines parsed", length(U)))
        else
            println(dia, f, " -E- No data in file")
        end

        # Generate floating point time stamps
        deltaTime = 3600.0f0 / numLines
        if length(U) > 1
            timeStamp = collect(range(0.0f0, stop=3600.0f0 - deltaTime, length=length(U)))
        elseif length(U) == 1
            timeStamp = [1800.0f0]
        else
            timeStamp = []
        end
        exit(8)

        # Write to file
        sOutputFileName = generateOutFileName(f, sTypeOfPath, sOutputPath, separator)
        nQuantities = length(analogConverted)
        n = length(timeStamp)
        g = open(sOutputFileName, "w")
        write(g, Int32(n))
        write(g, Int16(nQuantities))
        for i in 1:nQuantities
            write(g, ascii((svName[i] * "        ")[1:8]))
        end
        write(g, timeStamp)
        write(g, U)
        write(g, V)
        write(g, W)
        write(g, T)
        for i in 1:nQuantities
            write(g, analogData[i:nQuantities:n*nQuantities])
        end
        close(g)

        println(f, ", Lines=", numLines, ", Records=", n, ", Valid.Lines=", numValid, ", Invalid.Lines=", numInvalid)
        println(rep, f, ", ", numLines, ", ", n, ", ", numValid, ", ", numInvalid)

    end

else

    println("error: Parameter 'RawDataForm' in configuration file is not MFCL, MFC2, or WR")
    exit(3)

end

# Leave
close(rep)
close(dia)
exit(0)
