:- module getr.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.
:- implementation.
:- use_module spawn.
:- import_module rusage.
:- import_module string, list, int, float, maybe.

:- func version = string.
version = "v0.2.0".

:- pred usage(io::di, io::uo) is erroneous.
usage(!IO) :-
    io.progname_base("getr", Program, !IO),
    Usage = string.format(
        "usage: %s --help\n" ++
        "usage: %s --version\n" ++
        "usage: %s [-i <file>] [-b <ref>] <#runs> <command> [<args> ...]\n\n" ++

        "  --help           show this text and exit\n" ++
        "  --version        show version and exit\n\n" ++

        "  -b <reference>   print only: | Speed | Runtime | MaxRSS |\n" ++
        "                   'Speed' is presented as 3.8x, 0.11x, etc., and is\n" ++
        "                   calculated as 'reference' * Speed = Runtime\n\n" ++

        "  -i <file>        spawned commands have 'file' as their standard input\n\n" ++

        "Normal operation: run command #runs times and report its resource usage\n",
        [s(Program), s(Program), s(Program)]),
    die(Usage, !IO).

:- type options
    --->    options(
                input :: maybe(string),
                brief :: maybe(float),
                count :: int,
                command :: string,
                args :: list(string)
            ).
:- type partial
    --->    partial(
                p_input :: maybe(string),
                p_brief :: maybe(float)
            ).
:- type optfail
    --->    general
    ;       count(string)
    ;       brief(string).
:- type optres
    --->    ok(options)
    ;       error(optfail).

:- pred getopt(list(string)::in, partial::in, optres::out) is det.
getopt(Args, !.Opt, Res) :-
    ( if Args = ["-b", BStr | Rest] then
        ( if to_float(BStr, B) then
            !Opt^p_brief := yes(B),
            getopt(Rest, !.Opt, Res)
        else
            Res = error(brief(BStr))
        )
    else if Args = ["-i", Path | Rest] then
        !Opt^p_input := yes(Path),
        getopt(Rest, !.Opt, Res)
    else if Args = [NStr, Command | Rest] then
        ( if to_int(NStr, N) then
            Res = ok(options(!.Opt^p_input, !.Opt^p_brief, N, Command, Rest))
        else
            Res = error(count(NStr))
        )
    else
        Res = error(general)
    ).

:- pred getopt(list(string)::in, optres::out) is det.
getopt(L, Res) :- getopt(L, partial(no, no), Res).

main(!IO) :-
    io.command_line_arguments(Args, !IO),
    ( if Args = ["--help"] then
        usage(!IO)
    else if Args = ["--version"] then
        die("getr version " ++ version ++ "\n", !IO)
    else
        true
    ),
    getopt(Args, OptRes),
    (
        OptRes = error(general),
        usage(!IO)
    ;
        OptRes = error(count(CountStr)),
        die("#runs must be an integer, but got: " ++ CountStr ++ "\n", !IO)
    ;
        OptRes = error(brief(RefStr)),
        die("-b requires a decimal time in ms, but got: " ++ RefStr ++ "\n", !IO)
    ;
        OptRes = ok(Opts),
        (
            Opts^input = no,
            spawn.benchmark(Opts^count, Opts^command, Opts^args, !IO)
        ;
            Opts^input = yes(Path),
            spawn.benchmark(Path, Opts^count, Opts^command, Opts^args, !IO)
        ),
        rusage.getrusage(rusage.children, Usage, !IO),
        (
            Opts^brief = no,
            report(Opts^count, Usage, !IO)
        ;
            Opts^brief = yes(Ref),
            brief_report(Ref, Opts^count, Usage, !IO)
        )
    ).

:- pred report(int::in, usage::in, io::di, io::uo) is det.
report(Count, Usage, !IO) :-
    io.format(io.stderr_stream, "\
User time      : %d s, %d us
System time    : %d s, %d us
Time           : %d ms (%.3f ms/per)
Max RSS        : %s
Page reclaims  : %d
Page faults    : %d
Block inputs   : %d
Block outputs  : %d
vol ctx switches   : %d
invol ctx switches : %d\n", [
        i(Usage^user_sec),
        i(Usage^user_usec),
        i(Usage^system_sec),
        i(Usage^system_usec),
        i(MS), f(MSPer),
        s(smart_rss(Usage^max_rss)),
        i(Usage^minor_faults),
        i(Usage^major_faults),
        i(Usage^in_blocks),
        i(Usage^out_blocks),
        i(Usage^vol_context),
        i(Usage^invol_context)
    ], !IO),
    MS = Secs*1000 + USecs/1000,
    MSPer = float(MS)/float(Count),
    Secs = Usage^user_sec + Usage^system_sec,
    USecs = Usage^user_usec + Usage^system_usec.

:- pred brief_report(float::in, int::in, usage::in, io::di, io::uo) is det.
brief_report(Reference, Count, Usage, !IO) :-
    io.format(io.stderr_stream,
        "| %5.3fx | %.3f ms | %s |\n",
        [f(Speed), f(MSPer), s(smart_rss(Usage^max_rss))], !IO),
    Speed = MSPer / Reference,
    MS = Secs*1000 + USecs/1000,
    MSPer = float(MS) / float(Count),
    Secs = Usage^user_sec + Usage^system_sec,
    USecs = Usage^user_usec + Usage^system_usec.

:- func smart_rss(float) = string.
smart_rss(KB) = RSS :-
    ( if KB < 1024.0 then
        RSS = string.format("%.0f kB", [f(KB)])
    else if KB < 1024.0 * 1024.0 then
        RSS = string.format("%.1f MB", [f(KB / 1024.0)])
    else
        RSS = string.format("%.2f GB", [f(KB / (1024.0 * 1024.0))])
    ).

:- pred die(string::in, io::di, io::uo) is erroneous.
:- pragma foreign_decl("C", "\
#include <stdio.h>
#include <stdlib.h>
").
:- pragma foreign_proc("C",
    die(Reason::in, _IO0::di, _IO::uo),
    [promise_pure, will_not_call_mercury],
"
    fprintf(stderr, Reason);
    exit(1);
").
