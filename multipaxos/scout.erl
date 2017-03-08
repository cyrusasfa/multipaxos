%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(scout).
-export([start/3]).

start(Leader, Acceptors, Ballot) ->
  WaitFor = sets:from_list(Acceptors),
  [ P ! { phase1, request, self(), Ballot } || P <- WaitFor ],
  next(Leader, Ballot, WaitFor, sets:new(), sets:size(WaitFor)).

% Ballot = { Round, Leader }
% PValue = { Ballot, Slot, Cmd }
% Accepted = [ PValue ]
% WaitFor = [ PID ]
next(Leader, Ballot, WaitFor, Accepted, Size) ->
  receive
    { phase1, response, PID, BallotN, PValue } ->
      case (BallotN == Ballot andalso sets:is_element(PID, WaitFor)) of
        true  ->
          AcceptedN = sets:add_element(PValue, Accepted),
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
