:- module spawn.
:- interface.
:- import_module io, list, string, int.

    % spawn(Pid, Command, Args, !IO)
    % spawn Command as a separate process, resolving Command with PATH.
    % Args needn't begin with Command.
    % Pid is set to the process ID of the spawned process, suitable for waitpid
    %
:- pred spawn(int::out, string::in, list(string)::in, io::di, io::uo) is det.

    % waitpid(Pid, !IO)
    % block until the process identified by Pid exits.
    %
:- pred waitpid(int::in, io::di, io::uo) is det.

    % benchmark(Times, Command, Args, !IO)
    % equivalent to Times x invocations of:
    %   ( spawn(Pid, Command, Args, !IO), waitpid(Pid, !IO) )
    % but slightly more efficient as low-level structures are reused.
    %
:- pred benchmark(int::in, string::in, list(string)::in, io::di, io::uo) is det.

    % benchmark(Path, Times, Command, Args, !IO)
    % sets stdin to beginning of file at Path before spawns
    %
:- pred benchmark(string::in, int::in, string::in, list(string)::in,
    io::di, io::uo) is det.

:- implementation.

:- pragma foreign_decl("C", "
#include <sys/types.h>
#include <sys/wait.h>
#include <stdio.h>
#ifdef GETR_FORKEXEC
#include <unistd.h>
#else
#include <spawn.h>
#endif
#ifdef __APPLE__
#include <crt_externs.h>
#endif
").

spawn(Pid, Command, Args, !IO) :-
    c_spawn(Pid, Command, list.length(Args), Args, !IO).

benchmark(N, Command, Args, !IO) :-
    c_benchmark(N, Command, list.length(Args), Args, !IO).

benchmark(Path, N, Command, Args, !IO) :-
    c_benchmark(Path, N, Command, list.length(Args), Args, !IO).

:- pred c_benchmark(int::in, string::in, int::in, list(string)::in, io::di, io::uo) is det.
:- pragma foreign_proc("C",
    c_benchmark(Count::in, Command::in, Len::in, Args::in, _IO0::di, _IO::uo),
    [will_not_call_mercury, promise_pure],
"
    int Pid;
    char **args = malloc(sizeof(char *) * (Len + 2));
#ifdef __APPLE__
    char **environ = _NSGetEnviron();
#endif
    args[0] = Command;
    args[Len + 1] = NULL;
    for (int i = 0; i < Len; i++) {
        args[i+1] = (char*) MR_list_head(Args);
        Args = MR_list_tail(Args);
    }
    for (int i = 0; i < Count; i++) {
#ifdef GETR_FORKEXEC
        if ((Pid = fork())) waitpid(Pid, NULL, 0);
        else execvp(Command, args);
#else
        posix_spawnp(&Pid, Command, NULL, NULL, args, environ);
        waitpid(Pid, NULL, 0);
#endif
    }
    free(args);
").

:- pred c_benchmark(string::in, int::in, string::in, int::in, list(string)::in,
    io::di, io::uo) is det.
:- pragma foreign_proc("C",
    c_benchmark(Path::in, Count::in, Command::in, Len::in, Args::in,
        _IO0::di, _IO::uo),
    [will_not_call_mercury, promise_pure],
"
    int Pid;
    FILE *input = fopen(Path, ""r"");
    char **args = malloc(sizeof(char *) * (Len + 2));
#ifdef __APPLE__
    char **environ = _NSGetEnviron();
#endif
    args[0] = Command;
    args[Len + 1] = NULL;
    for (int i = 0; i < Len; i++) {
        args[i+1] = (char*) MR_list_head(Args);
        Args = MR_list_tail(Args);
    }
    dup2(fileno(input), STDIN_FILENO);
    for (int i = 0; i < Count; i++) {
        rewind(input);
#ifdef GETR_FORKEXEC
        if ((Pid = fork())) waitpid(Pid, NULL, 0);
        else execvp(Command, args);
#else
        posix_spawnp(&Pid, Command, NULL, NULL, args, environ);
        waitpid(Pid, NULL, 0);
#endif
    }
    fclose(input);
    free(args);
").

:- pred c_spawn(int::out, string::in, int::in, list(string)::in, io::di, io::uo) is det.
:- pragma foreign_proc("C",
    c_spawn(Pid::out, Command::in, Len::in, Args::in, _IO0::di, _IO::uo),
    [will_not_call_mercury, promise_pure],
"
    int pid;
    char **args = malloc(sizeof(char *) * (Len + 2));
#ifdef __APPLE__
    char **environ = _NSGetEnviron();
#endif
    args[0] = Command;
    args[Len + 1] = NULL;
    for (int i = 0; i < Len; i++) {
        args[i+1] = (char*) MR_list_head(Args);
        Args = MR_list_tail(Args);
    }
#ifdef GETR_FORKEXEC
    if (!(pid = fork())) execvp(Command, args);
#else
    posix_spawnp(&pid, Command, NULL, NULL, args, environ);
#endif
    free(args);
    Pid = pid;
").

:- pragma foreign_proc("C",
    waitpid(Pid::in, _IO0::di, _IO::uo),
    [will_not_call_mercury, promise_pure],
"
    waitpid(Pid, NULL, 0);
").
