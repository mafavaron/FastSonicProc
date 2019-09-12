# General naming and format specification

## Explain

The FastSonic format is designed for fast read on a single-core, electro-mechanical disk system. It is native-binary, so it is not well-versed for transferring data across different architectures.

More specifically: file names conform to the following spec:

  _YYYYMMDD_._HH_.fse
  
where _YYYY_ is the year, _MM_ the month, _DD_ the day, and _HH_ the hour. As so:

  20190308.12.fse
  
The naming scheme employed implies a hourly organization.

Any FastSonic-formatted file is of binary (raw stream) type, and may be opened using a command like the following:

  OPEN(LUN=iLun, FILE=sFileName, ACTION='READ', ACCESS='stream')

The first two bytes in a FastSonic file contain an 'integer(2)' value, whose meanings is

* Number of data.

Then, actual data come immediately after, stored as five vectors containing the following data:

* Time stamps (s in current hour; integer(2))
* U component values (m/s, eastward; real(4))
* V component values (m/s, northward; real(4))
* W component values (m/s, upward; real(4))
* T sonic temperature values (°C; real(4))

No invalid data are stored in a FastSonic file, so it may well happen the number of data is zero.

## Performance

Before to arrive to the format spec as it is, some checks have been made to find a reasonable compromise. Two solutions have been compared:

* Data vectors of type 'integer(2)' have been used.
* Data vectors of type 'real(4)' otherwise.

In the former case, data need to be converted to floating point after read; this conversion is not necessary in the latter case.

Two key factors have been used in comparison:

* The time used to read a sample of 1571 data files.
* Their total disk occupation.

A third factor has been included in reports, but not used in evaluations:

* The time used to convert the 1571 files sample from text-based SonicLib to FastSonic form.

Here are our results:

* First case ('integer(2)' data): Generation = 111.8370s    Read = 0.540s    Disk size = 554378304 byte
* Second case ('real(4)' data):   Generation = 113.1200s    Read = 0.338s    Disk size = 997875920 byte

Apparently, in terms of raw speed use of integer data followed by conversion takes some more time than direct read in floating point form. But on the other side, the overall file size is much smaller in integer case.

The final decision has been to use the faster-reading version despite its memory footprint, in sake of a good basis for further high-efficiency data processing.

Please note how generating floating point data from SonicLib files takes a bit of time more than with integer data. The advantage is, however, marginal.

Please also note timings are indicative, having been obtained using non-optimized code on the gaming machine I'm using as a cheap workstation. Not really benchmarks, then: just indications.

