%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(leader).
-export([start/1]).

start(End_after) ->
  receive
    { bind, Acceptors, Replicas } ->
      timer:send_after(End_after, { finish }),
      BallotInitial = { 0, self() },
      spawn(scout, start, [self(), Acceptors, BallotInitial]),
      next(false, BallotInitial, maps:new(), Acceptors, Replicas)
  end.

next(Active, Ballot, Proposals, Acceptors, Replicas) ->
  receive
    { propose, Slot, Cmd } ->
      case not maps:is_key(Slot, Proposals) of
        true ->
          ProposalsO = maps:put(Slot, Cmd, Proposals),
          case Active of
            true ->
              spawn(commander, start,
                    [self(), Acceptors, Replicas, Ballot, Slot, Cmd]) ;
            false ->
              ok
          end,
          next(Active, Ballot, ProposalsO, Acceptors, Replicas) ;
        false ->
          ok
      end ;
    { adopted, Ballot, Accepted } ->
      ProposalsO = sets:union(
        sets:from_list(maps:to_list(Proposals)), pValueMax(Accepted)
      ),
      [ spawn(commander, start,
              [ self(), Acceptors, Replicas, Ballot, Slot, Cmd ]) ||
        { Slot, Cmd } <- sets:to_list(ProposalsO) ],
      next(true, Ballot, maps:from_list(sets:to_list(ProposalsO)),
           Acceptors, Replicas) ;
    { preempted, { Round, Leader } } ->
      case { Round, Leader } > Ballot of
        true  ->
          ActiveO = false,
          BallotO = { Round + 1, self() },
          spawn(scout, start, [ self(), Acceptors, BallotO ]) ;
        false ->
          ActiveO = Active,
          BallotO = Ballot
      end,
      next(ActiveO, BallotO, Proposals, Acceptors, Replicas) ;
    { finish } ->
      done
  end.

pValueMax(Accepted) ->
  AcceptedList = sets:to_list(Accepted),
  sets:from_list([ { S, C } ||
    { B, S, C } <- AcceptedList,
    length([
      1 ||
      { B_, S_, C_ } <- AcceptedList,
      B_ > B,
      S_ == S,
      C_ /= C
    ]) == 0
  ]).
