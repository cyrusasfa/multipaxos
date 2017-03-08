%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(acceptor).
-export([start/1]).

start(End_after) ->
  timer:send_after(End_after, { finish }),
  next(undefined, sets:new()).

% Ballot = { Round, Leader }
% PValue = { Ballot, Slot, Cmd }
% Accepted = [ PValue ]
next(Ballot, Accepted) ->
  receive
    % Adopt a ballot number
    { phase1, request, Scout, BallotI } ->
      case (BallotI > Ballot) of
        true  -> BallotO = BallotI;
        false -> BallotO = Ballot
      end,
      Scout ! { phase1, response, self(), BallotO, Accepted },
      AcceptedO = Accepted,
      next(BallotO, AcceptedO) ;

    % Adopt a pvalue
    { phase2, request, Commander, BallotI, SlotI, Cmd } ->
      case (BallotI == Ballot) of
        true  ->
          AcceptedO = sets:add_element({ BallotI, SlotI, Cmd }, Accepted) ;
        false ->
          AcceptedO = Accepted
      end,
      Commander ! { phase2, response, self(), Ballot },
      BallotO = Ballot,
      next(BallotO, AcceptedO) ;
    { finish } ->
      done
  end.
