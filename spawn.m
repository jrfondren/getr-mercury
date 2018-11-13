:- module spawn.
:- interface.

:- import_module io, list, string, int.

:- pred spawn(int::out, string::in, list(string)::in, io::di, io::uo) is det.
:- pred waitpid(int::in, io::di, io::uo) is det.
:- pred benchmark(int::in, string::in, list(string)::in, io::di, io::uo) is det.

:- implementation.

:- pragma foreign_decl("C", "
#include <sys/types.h>
#include <sys/wait.h>
#include <spawn.h>
").

spawn(Pid, Command, Args, !IO) :-
	c_spawn(Pid, Command, list.length(Args), Args, !IO).

benchmark(N, Command, Args, !IO) :-
	c_benchmark(N, Command, list.length(Args), Args, !IO).

:- pred c_benchmark(int::in, string::in, int::in, list(string)::in, io::di, io::uo) is det.
:- pragma foreign_proc("C",
	c_benchmark(Count::in, Command::in, Len::in, Args::in, IO0::di, IO::uo),
	[will_not_call_mercury, promise_pure],
"
	int Pid;
	char **args = malloc(sizeof(char *) * (Len + 2));
	args[0] = Command;
	args[Len + 1] = NULL;
	for (int i = 0; i < Len; i++) {
		args[i+1] = (char*) MR_list_head(Args);
		Args = MR_list_tail(Args);
	}
	for (int i = 0; i < Count; i++) {
		posix_spawn(&Pid, Command, NULL, NULL, args, environ);
		waitpid(Pid, NULL, 0);
	}
	free(args);
	IO = IO0;
").

:- pred c_spawn(int::out, string::in, int::in, list(string)::in, io::di, io::uo) is det.
:- pragma foreign_proc("C",
	c_spawn(Pid::out, Command::in, Len::in, Args::in, IO0::di, IO::uo),
	[will_not_call_mercury, promise_pure],
"
	int pid;
	char **args = malloc(sizeof(char *) * (Len + 2));
	args[0] = Command;
	args[Len + 1] = NULL;
	for (int i = 0; i < Len; i++) {
		args[i+1] = (char*) MR_list_head(Args);
		Args = MR_list_tail(Args);
	}
	posix_spawn(&pid, Command, NULL, NULL, args, environ);
	free(args);
	Pid = pid;
	IO = IO0;
").

:- pragma foreign_proc("C",
	waitpid(Pid::in, IO0::di, IO::uo),
	[will_not_call_mercury, promise_pure],
"
	waitpid(Pid, NULL, 0);
	IO = IO0;
").
