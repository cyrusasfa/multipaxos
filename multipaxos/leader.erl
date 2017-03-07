%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(leader).
-export([start/0]).

start() ->
  receive
    { bind, Acceptors, Replicas } ->
      spawn(scout, start, [self(), Acceptors, 0]),
      next(false, 0, maps:new(), Acceptors, Replicas)
  end.

next(Active, Ballot, Proposals, Acceptors, Replicas) ->
  receive
    { propose, Slot, Cmd } ->
      case maps:is_key(Slot, Proposals) of
        false ->
          ProposalsN = maps:put(Slot, Cmd, Proposals),
          case Active of
            true  ->
              spawn(commander, start,
                    [self(), Acceptors, Replicas, Ballot, Slot, Cmd])
          end,
          next(Active, Ballot, ProposalsN, Acceptors, Replicas)
      end ;
    { adopted, _, Ballot, Accepted } ->
      Commands = accumulate_proposals(Accepted, maps:new(), maps:new()),
      [ spawn(
          commander, start,
          [self(), Acceptors, Replicas, Ballot, Slot, C ]
        ) || { Slot, C } <- maps:to_list(Commands) ],
      next(true, Ballot, Proposals, Acceptors, Replicas) ;
    { preempted, _, BallotN } ->
      case BallotN > Ballot of
        true  ->
          BallotNN = Ballot + 1,
          spawn(scout, start, [self(), Acceptors, BallotNN]) ;
        false ->
          BallotNN = Ballot
      end,
      next(false, BallotNN, Proposals, Acceptors, Replicas)
  end.

accumulate_proposals(Proposals, Commands, Map) ->
  case Proposals of
    [ { Ballot, Slot, Cmd } | T ] ->
      case (not maps:is_key(Slot, Map) or (maps:get(Slot, Map) < Ballot)) of
        true  ->
          accumulate_proposals(
            T,
            maps:put(Slot, Cmd, Commands),
            maps:put(Slot, Ballot, Map)
          ) ;
        false -> accumulate_proposals(T, Commands, Map)
      end ;
    _ -> Commands
  end.
