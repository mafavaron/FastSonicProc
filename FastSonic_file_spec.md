# General naming and format specification

## Purpose of the FastSonic format

The FastSonic format is designed for fast read on a single-core, electro-mechanical disk system. It is native-binary, so it is not optimized for transferring data across different architectures. Its real utility is, allowing an as fast as possible processing, by mitigating the bottleneck effect inherent in text parsing.

## Naming convention

More specifically: file names conform to the following spec:

  _YYYYMMDD_._HH_.fsr
  
where _YYYY_ is the year, _MM_ the month, _DD_ the day, and _HH_ the hour. The '.fsr' extension stays for itself, to mean something like "FastSonic Raw". As so:

  20190308.12.fsr
  
The naming scheme employed implies a hourly organization.

Note: the 'fsr' file extension has been selected because:
1. It's easy to remember.
2. It does correspond to no popular file format.

## File contents

Any FastSonic-formatted file is of binary (raw stream) type, and may be opened using a command like the following:

  OPEN(LUN=iLun, FILE=sFileName, ACTION='READ', ACCESS='stream')

The first 4 bytes in a FastSonic file contain an 'integer(4)' value, whose meanings is

* Number of data.

Then a 2 bytes value follow, with meaning

* Number of "additional" columns.

For any "additional" column, 8 bytes follow with meaning

* Name of additional column (8 ASCII alphanumeric characters)

Then, actual data come immediately after, stored as five vectors:

* Time stamps (s in current hour; real(2))
* U component values (m/s, eastward; real(4))
* V component values (m/s, northward; real(4))
* W component values (m/s, upward; real(4))
* T sonic temperature values (°C; real(4))

If additional columns follow, they are stored following, in their name orders:

* I-th additional column (Unit is quantity-dependent; real(4))

# Properties

## Time stamp

The sequential order of time stamps in a FileSonic file is not required to coincide with real time order: it is allowed FastSonic files contain zero or more glitches.

This given, time series may be tested for the following conditions:
* _Rangeness_: Time stamp values are larger or equal than 0, and smaller than 3600.
* _Monotonicity_: If Ta, Tb are any two consecutive time stamps, then Ta < Tb.
* _Regularity_: Any time stamp T satisfies up to rounding errors, the condition T = dT*i + T0, where dT, the sampling time, is a real positive number, i is a non-negative integer, and _T0_ an arbitrary real number.
* _Completeness_: The time stamps sequence (is regular and) contains no gaps.

## Mandatory columns 'U', 'V', 'W', 'T'

Invalid data, if present, are encoded using the special value -9999.9.

The conversion procedure may choose either to decide whether including lines containing at least one invalid data in file, or to exclude them. In the former case, a line in which one data is found invalid should be treated as globally invalid. In other terms: if 'u' is invalid but 'v', 'w', 'T' are not, then 'v', 'w', 'T' should be considered invalid. This propagation of invalidity, although enforced by procedures, is not however demanded by this specification.

## Additional columns

Invalid values are also encoded as -9999.9.

No invalidity propagation is demanded for additional columns.

# The campaign descriptor

## Form

The _campaign descriptor file_ is a text file matching the specification for INI files.

## Sections

The campaign descriptor file contains the following section:

[General]

[Quantities]

[Quantity_1]

[Quantity_2]

...   ...   ...


[Quantity_N]

## [General] section

The section contains the following keys:

* Name: String, containing the campaign name.
* Site: String, containing the name of geographic site where data were collected.
* Sensor: String, containing the name of a supported ultrasonic anemometer; possible values are "USA-1" and "uSonic-3" (default).
* Zr: Height of sonic center from ground zero (in meters; floating point)
* LandType: Integer, containing land use data: 1 = Bare rock, desert, regolite; 2 = Ice, snow; 3 = Grassland; 4 = Forest; 5 = Urban. This data is retained for documentation only.
* RawDataPath: Name of path containing the data (directly, if "TypeOfPath" is "F"; or, in subdir-data form if "TypeOfPath" is "M". See next parameter description.
* RawDataForm: String, identifying the type of data (and, implicitly, its naming conventions). Values are: MFC2 for Meteoflux Core V2, MFCL for Meteoflux Core Lite, WR for WindReader, SL for SonicLib.
* FastSonicPath: String, indicating the directory where FastSonic data are.
* TypeOfPath: String indicating the directory structure for FastSonic data. Possible values are "Flat" or "F" for a flat directory, "Metek" or "M" for YYYYDD subdirs-in-dir.
* DiagnosticFile: String, containing the name of a diagnostic file where a short campaign resume is written as a log file.
* OperatingSystemType: String, containing the name of operating system. Possible values are "UNIX" for UNIX/Linux/OSX,
                                 and "WINDOWS" for Microsoft Windows.
* InvalidDataFate: String, with three possible values: "Keep", to save data also when they are invalid; "ExcludeSonicQuadruples" to exclude from write the sonic quadruples where an invalid data value is found; and "ExcludeAll" to exclude from write all records in which theer is one invalid value or more.
                                 
## The [Quantities] section

This section contains a single key:

* NumberOfAdditionalQuantities: Integer, non-negative.

The actual number of [Quantity_I] sections should match exactly this value.

## The [Quantity_N] sections

The sections with names [Quantity_N] contains the following keys

* Name: Name of the desired quantity (the first 8 chars are considered).
* Channel: Number of USA-1 / uSonic-3 analog channel. Values range from 1 to 10. Values 1..8 indicate regular analog channels; 9 and 10 stay for counters.
* Unit: Name of measurement unit.
* Multiplier: Multiplier from sonic counts to the desired unit.
* Offset: Offset.
* MinPlausible: Minimum plausible value (in physical units; floating point)
* MaxPlausible: Maximum plausible value (in physical units; floating point)

# Other restrictions

The number of additional quantities in [General] section may be 0, in which case only 'TimeStamp', 'U', 'V', 'W', 'T' data are present in files.

The value of "TypeOfPath" should be chosen wisely. The "Metek" case is more complex, but taxes the operating system far less. Please opt for "Metek" if the number of campaign files is 1000 or more.
