:- module rusage.
:- interface.
:- import_module io, int.

:- type who ---> self ; children.
:- type usage
    --->    usage(
            user_sec :: int,
            user_usec :: int,
            system_sec :: int,
            system_usec :: int,
            max_rss :: int,
            minor_faults :: int,
            major_faults :: int,
            in_blocks :: int,
            out_blocks :: int,
            vol_context :: int,
            invol_context :: int
        ).

:- pred getrusage(who::in, usage::out, io::di, io::uo) is det.

:- implementation.

:- pragma foreign_decl("C", "
#include <sys/time.h>
#include <sys/resource.h>
").

getrusage(Who, usage(USec, UUsec, SSec, SUSec, MaxRSS, MinFlt, MajFlt, InBlock, OutBlock, VolCTX, InvolCTX), !IO) :-
    c_getrusage(Who, USec, UUsec, SSec, SUSec, MaxRSS, MinFlt, MajFlt, InBlock, OutBlock, VolCTX, InvolCTX, !IO).

:- pragma foreign_enum("C", who/0, [
    self - "RUSAGE_SELF",
    children - "RUSAGE_CHILDREN"
]).

:- pred c_getrusage(who, int, int, int, int, int, int, int, int, int, int, int, io, io).
:- mode c_getrusage(in, out, out, out, out, out, out, out, out, out, out, out, di, uo) is det.
:- pragma foreign_proc("C",
    c_getrusage(
        Who::in,
        USec::out, UUsec::out, SSec::out, SUsec::out,
        MaxRSS::out,
        MinFlt::out, MajFlt::out,
        InBlock::out, OutBlock::out,
        VolCTX::out, InvolCTX::out,
        _IO0::di, _IO::uo),
    [will_not_call_mercury, promise_pure],
"
    struct rusage usage;
    getrusage(Who, &usage);
    USec = usage.ru_utime.tv_sec;
    UUsec = usage.ru_utime.tv_usec;
    SSec = usage.ru_stime.tv_sec;
    SUsec = usage.ru_stime.tv_usec;
    MaxRSS = usage.ru_maxrss;
    MinFlt = usage.ru_minflt;
    MajFlt = usage.ru_majflt;
    InBlock = usage.ru_inblock;
    OutBlock = usage.ru_oublock;
    VolCTX = usage.ru_nvcsw;
    InvolCTX = usage.ru_nivcsw;
").
