# getrusage() wrapper
- known to work on Linux (and Termux on Android, if using fork&exec)
- created as my simple "time for x in {1..100}; ..." benchmarks were a lot less pleasant on OpenBSD.

## Mercury notes
- this is a Mercury translation of the C version at https://github.com/jrfondren/getr
- this is the only version that doesn't complain and abort if `posix_spawn` fails

## build
```
make
make fork  # build fork&exec version
```

## usage and examples
```
$ getr 1000 ./fizzbuzz >/dev/null
User time      : 0 s, 717132 us
System time    : 0 s, 760456 us
Time           : 1477 ms (1.477 ms/per)
Max RSS        : 6.0 MB
Page reclaims  : 481577
Page faults    : 0
Block inputs   : 0
Block outputs  : 0
vol ctx switches   : 1000
invol ctx switches : 40

$ getr 100 python3 -c ''
User time      : 1 s, 254026 us
System time    : 0 s, 258217 us
Time           : 1512 ms (15.120 ms/per)
Max RSS        : 8.2 MB
Page reclaims  : 99141
Page faults    : 0
Block inputs   : 0
Block outputs  : 0
vol ctx switches   : 100
invol ctx switches : 8

$ getr -b 15.120 100 perl -le ''
| 0.085x | 1.280 ms | 5.9 MB |
```

## defects and room for improvement
- output is in an ad-hoc text format that machine consumers would need to parse manually
- 'getr' is probably a poor name
