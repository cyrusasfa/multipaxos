%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(commander).
-export([start/6]).

start(Leader, Acceptors, Replicas, Ballot, Slot, Cmd) ->
  [ P ! { phase2, request, self(), Ballot, Slot, Cmd } ||
    P <- sets:to_list(Acceptors) ],
  next(Leader, Replicas, Ballot, Slot, Cmd, Acceptors, sets:size(Acceptors)).

% Replicas = [ PID ]
% Ballot = { Round, Leader }
% WaitFor = [ PID ]
next(Leader, Replicas, Ballot, Slot, Cmd, WaitFor, Size) ->
  receive
    { phase2, response, PID, BallotI } ->
      case (BallotI == Ballot andalso sets:is_element(PID, WaitFor)) of
        true  ->
          WaitForO  = sets:del_element(PID, WaitFor),
          case (sets:size(WaitForO) < (Size / 2)) of
            true  -> [ R ! { decision, Slot, Cmd } || R <- sets:to_list(Replicas) ];
            false -> next(Leader, Replicas, Ballot, Slot, Cmd, WaitForO, Size)
          end ;
        false ->
          Leader ! { preempted, Ballot }
      end
  end,
  done.
