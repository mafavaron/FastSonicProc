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

