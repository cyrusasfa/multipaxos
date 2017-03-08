%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(acceptor).
-export([start/0]).

start() ->
  next(undefined, sets:new()).

next(Ballot, Accepted) ->
  receive
    { scout2acceptor, Leader, BallotN } ->
      case (BallotN > Ballot) of
        true  -> BallotR = BallotN ;
        false -> BallotR = Ballot
      end,
      Leader ! { acceptor2scout, self(), BallotR, Accepted },
      AcceptedN = Accepted ;
    { commander2acceptor, Leader, BallotN, SlotN, Cmd } ->
      case (BallotN == Ballot) of
        true  ->
          AcceptedN = sets:add_element({ BallotN, SlotN, Cmd }, Accepted) ;
        false ->
          AcceptedN = Accepted
      end,
      Leader ! { acceptor2commander, self(), Ballot, SlotN },
      BallotR = Ballot
  end,
  next(BallotR, AcceptedN).
