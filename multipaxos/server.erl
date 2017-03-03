%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(server).
-export([start/3]).

start(System, N_accounts, End_after) ->

  Database = spawn(database, start, [N_accounts, End_after]),

  Replica = spawn(replica, start, [Database]),

  Leader = spawn(leader, start, []),

  Acceptor = spawn(acceptor, start, []),

  System ! {config, Replica, Acceptor, Leader},

  done.
