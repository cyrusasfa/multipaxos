%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(acceptor).
-export([start/0]).

start() ->
  next(undefined, sets:new()).

next(Ballot, Accepted) ->
  receive
    { Leader, BallotN } ->
      case (BallotN > Ballot) of
        true  -> BallotR = BallotN ;
        false -> BallotR = Ballot
      end,
      Leader ! { self(), BallotR, Accepted },
      next(BallotR, Accepted) ;
    { Leader, BallotN, SlotN, Cmd } ->
      case (BallotN == Ballot) of
        true  ->
          AValue = { BallotN, SlotN, Cmd },
          AcceptedN = sets:add_element(AValue, Accepted) ;
        false ->
          AcceptedN = Accepted
      end,
      Leader ! { self(), Ballot, SlotN },
      next(Ballot, AcceptedN)
  end.
