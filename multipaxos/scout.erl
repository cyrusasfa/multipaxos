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
    { phase1, response, Acceptor, BallotI, AcceptedAcceptor } ->
      case (BallotI == Ballot andalso sets:is_element(Acceptor, WaitFor)) of
        true  ->
          AcceptedO = sets:union(AcceptedAcceptor, Accepted),
          WaitForO  = sets:remove_element(Acceptor),
          case (sets:size(WaitForO) < (Size / 2)) of
            true  -> Leader ! { adopted, Ballot, Accepted } ;
            false -> next(Leader, Ballot, WaitForO, AcceptedO, Size)
          end ;
        false ->
          Leader ! { preempted, BallotI }
      end
  end,
  done.
