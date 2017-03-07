%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(scout).
-export([start/3]).

start(Leader, Acceptors, Ballot) ->
  WaitFor = sets:from_list(Acceptors),
  [ P ! { scout2acceptor, self(), Ballot } || P <- WaitFor ],
  next(Leader, Ballot, WaitFor, sets:new(), sets:size(WaitFor)).

next(Leader, Ballot, WaitFor, Accepted, Size) ->
  receive
    { acceptor2scout, PID, BallotN, AValue } ->
      case (BallotN == Ballot andalso sets:is_element(PID, WaitFor)) of
        true  ->
          AcceptedN = sets:add_element(AValue, Accepted),
          WaitForN  = sets:remove_element(PID),
          case (sets:size(WaitForN) < (Size / 2)) of
            true  -> Leader ! { adopted, self(), Ballot, Accepted } ;
            false -> next(Leader, Ballot, WaitForN, AcceptedN, Size)
          end ;
        false ->
          Leader ! { preempted, self(), BallotN }
      end
  end,
  done.
