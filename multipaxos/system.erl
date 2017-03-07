%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(system).
-export([start/0]).

start() ->
  N_servers  = 5,
  N_clients  = 3,
  N_accounts = 10,
  Max_amount = 1000,

  End_after  = 1000,   %  Milli-seconds for Simulation

  _Servers = [ spawn(server, start, [self(), N_accounts, End_after])
    || _ <- lists:seq(1, N_servers) ],

  % Now have N servers, with a database, replica, leader and acceptor process

  Components = [ receive {config, R, A, L} -> {R, A, L} end
    || _ <- lists:seq(1, N_servers) ],

  % Object with all replicas, acceptors, and leaders

  {Replicas, Acceptors, Leaders} = lists:unzip3(Components),

  % Each replica is bound to all leaders
  % Each leader is bound to all acceptors and replicas

  [ Replica ! {bind, Leaders} || Replica <- Replicas ],
  [ Leader  ! {bind, Acceptors, Replicas} || Leader <- Leaders ],

  % Clients spawn with the replicas they should communicate
  % with and the number of accounts on the databases

  _Clients = [ spawn(client, start,
               [Replicas, N_accounts, Max_amount, End_after])
    || _ <- lists:seq(1, N_clients) ],

  % Process exits

  done.
