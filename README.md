# Rationale

Processing a large number of ultrasonic anemometer raw data file may be cumbersome, especially if interpreted languages like R or Python are used.

As far as I can envision, the problem has at least two sides:

1. Extant libraries (SonicLib among them) are intrinsically sequential.

2. The common data formats (once again, the SonicLib format) are text-oriented, which makes their parsing relatively slow whatever the language employed to this end.

A solution might then be, using parallel construct as most as possible, coupled with some native data representation.

The need for a more parallel-minded "library" (plus conventions) is then needed.

To date, the parallel architectures allowing first tests has been selected as CUDA. Others exist in the readily available camp, however. Using CUDA is not an endorsement of it from my side.

