:- module getr.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.
:- implementation.
:- import_module rusage, spawn.
:- import_module string, list, int, float.

:- pred report(int::in, usage::in, io::di, io::uo) is det.

main(!IO) :-
	io.command_line_arguments(Args, !IO),
	(
		Args = [NStr, Command | Rest],
		string.to_int(NStr, N)
	->
		spawn.benchmark(N, Command, Rest, !IO),
		rusage.getrusage(rusage.children, Usage, !IO),
		report(N, Usage, !IO)
	;
		io.progname("getr", Name, !IO),
		io.format(io.stderr_stream, "%s <n> <command> [<args> ...]\n", [s(Name)], !IO),
		io.set_exit_status(1, !IO)
	).

report(Count, Usage, !IO) :-
	io.format(io.stderr_stream, "\
User time      : %d s, %d us
System time    : %d s, %d us
Time           : %d ms (%.3f ms/per)
Max RSS        : %d kB
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
		i(Usage^max_rss),
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
