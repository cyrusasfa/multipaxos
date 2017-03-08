%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(leader).
-export([start/0]).

start() ->
  receive
    { bind, Acceptors, Replicas } ->
      BallotInitial = { 0, self() },
      spawn(scout, start, [self(), Acceptors, BallotInitial]),
      next(false, BallotInitial, maps:new(), Acceptors, Replicas)
  end.

next(Active, Ballot, Proposals, Acceptors, Replicas) ->
  receive
    { propose, Slot, Cmd } ->
      case maps:is_key(Slot, Proposals) of
        false ->
          ProposalsO = maps:put(Slot, Cmd, Proposals),
          case Active of
            true  ->
              spawn(commander, start,
                    [self(), Acceptors, Replicas, Ballot, Slot, Cmd])
          end,
          next(Active, Ballot, ProposalsO, Acceptors, Replicas)
      end ;
    { adopted, Ballot, Accepted } ->
      ProposalsO = triangle(Proposals, pmax(Accepted)),
      % Commands = accumulate_proposals(Accepted, maps:new(), maps:new()),
      [ spawn(commander, start,
              [ self(), Acceptors, Replicas, Ballot, Slot, Cmd ]) ||
        { Slot, Cmd } <- ProposalsO ],
      next(true, Ballot, ProposalsO, Acceptors, Replicas) ;
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
      next(ActiveO, BallotO, Proposals, Acceptors, Replicas)
  end.

triangle(ProposalsX, ProposalsY) ->
  sets:union(ProposalsY, ProposalsX -- ProposalsY).

pmax(Accepted) ->
  [ { S, C } ||
    { B, S, C } <- Accepted,
    length([
      1 ||
      { B_, S_, C_ } <- Accepted,
      B_ > B,
      S_ == S,
      C_ /= C
    ]) == 0
  ].
