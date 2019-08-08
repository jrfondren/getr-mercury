# getrusage() wrapper
- known to work on Linux
- created as my simple "time for x in {1..100}; ..." benchmarks were a lot less pleasant on OpenBSD.

## Mercury notes
- this is a Mercury translation of the C version at https://github.com/jrfondren/getr
- this is the only version that doesn't complain and abort if `posix_spawn` fails

## build
```
make
```

## usage and examples
```
$ getr 1000 ./fizzbuzz >/dev/null
User time      : 0 s, 283052 us
System time    : 0 s, 127471 us
Time           : 410 ms (0.410 ms/per)
Max RSS        : 5608 kB
Page reclaims  : 65309
Page faults    : 0
Block inputs   : 0
Block outputs  : 0
vol ctx switches   : 998
invol ctx switches : 17

$ getr 100 $(which python3) -c ''
User time      : 1 s, 450814 us
System time    : 0 s, 290732 us
Time           : 1741 ms (17.410 ms/per)
Max RSS        : 8704 kB
Page reclaims  : 98102
Page faults    : 0
Block inputs   : 0
Block outputs  : 0
vol ctx switches   : 103
invol ctx switches : 10

$ getr 100 $(which perl) -le ''
User time      : 0 s, 84307 us
System time    : 0 s, 62373 us
Time           : 146 ms (1.460 ms/per)
Max RSS        : 5648 kB
Page reclaims  : 22159
Page faults    : 0
Block inputs   : 0
Block outputs  : 0
vol ctx switches   : 103
invol ctx switches : 6
```

## defects and room for improvement
- output is in an ad-hoc text format that machine consumers would need to parse manually
- only `posix_spawn` is used, but fork&exec might be preferred for timings more like a fork&exec-using application
- this command lacks a manpage
- 'getr' is probably a poor name
- kB and ms are always used even when number ranges might be easier to understand in MB or s, or GB or min:s
