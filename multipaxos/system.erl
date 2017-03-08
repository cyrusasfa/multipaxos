%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(system).
-export([start/0]).

start() ->
  N_servers  = 5,
  N_clients  = 3,
  N_accounts = 10,
  Max_amount = 1000,

  End_after  = 1000,   %  Milli-seconds for Simulation

  _Servers = [ spawn(server, start, [ self(), N_accounts, End_after ]) ||
               _ <- lists:seq(1, N_servers) ],

  % Now have N servers, with a database, replica, leader and acceptor process

  Components = [ receive { config, R, A, L } -> { R, A, L } end ||
                 _ <- lists:seq(1, N_servers) ],

  % Object with all replicas, acceptors, and leaders

  { Replicas_List, Acceptors_List, Leaders_List } = lists:unzip3(Components),
  { Replicas, Acceptors, Leaders } = {
    sets:from_list(Replicas_List),
    sets:from_list(Acceptors_List),
    sets:from_list(Leaders_List)
  },

  % Each replica is bound to all leaders
  % Each leader is bound to all acceptors and replicas

  [ R ! { bind, Leaders } || R <- sets:to_list(Replicas) ],
  [ L ! { bind, Acceptors, Replicas } || L <- sets:to_list(Leaders) ],

  % Clients spawn with the replicas they should communicate
  % with and the number of accounts on the databases

  _Clients = [ spawn(client, start,
                     [ Replicas, N_accounts, Max_amount, End_after ]) ||
               _ <- lists:seq(1, N_clients) ],

  % Process exits

  timer:sleep(End_after + 1000 + 500),
  erlang:halt().
