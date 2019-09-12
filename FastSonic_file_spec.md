# General naming and format specification

## Explain

The FastSonic format is designed for fast read on a single-core, electro-mechanical disk system. It is native-binary, so it is not well-versed for transferring data across different architectures.

More specifically: file names conform to the following spec:

  _YYYYMMDD_._HH_.fsr
  
where _YYYY_ is the year, _MM_ the month, _DD_ the day, and _HH_ the hour. As so:

  20190308.12.fsr
  
The naming scheme employed implies a hourly organization.

Any FastSonic-formatted file is of binary (raw stream) type, and may be opened using a command like the following:

  OPEN(LUN=iLun, FILE=sFileName, ACTION='READ', ACCESS='stream')

The first two bytes in a FastSonic file contain an 'integer(2)' value, whose meanings is

* Number of data.

Then, actual data come immediately after, stored as five 'integer(2)' vectors containing the following data:

* Time stamps (s in current hour)
* U component values (cm/s, eastward)
* V component values (cm/s, northward)
* W component values (cm/s, upward)
* T sonic temperature values (hundredths of °C)

No invalid data are stored in a FastSonic file, so it may well happen the number of data is zero.

## Performance

Before to arrive to the format spec as it is, 
