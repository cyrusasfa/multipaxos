%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(server).
-export([start/3]).

start(System, N_accounts, End_after) ->

  Database = spawn(database, start, [ N_accounts, End_after ]),

  Replica = spawn(replica, start, [ Database, End_after ]),

  Leader = spawn(leader, start, [ End_after ]),

  Acceptor = spawn(acceptor, start, [ End_after ]),

  System ! { config, Replica, Acceptor, Leader },

  % Process exits

  done.
