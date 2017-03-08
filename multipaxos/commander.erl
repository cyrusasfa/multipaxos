%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(commander).
-export([start/6]).

start(Leader, Acceptors, Replicas, Ballot, Slot, Cmd) ->
  WaitFor = sets:from_list(Acceptors),
  [ P ! { phase2, request, self(), Ballot, Slot, Cmd } || P <- WaitFor ],
  next(Leader, Replicas, Ballot, Slot, Cmd, WaitFor, sets:size(WaitFor)).

% Replicas = [ PID ]
% Ballot = { Round, Leader }
% WaitFor = [ PID ]
next(Leader, Replicas, Ballot, Slot, Cmd, WaitFor, Size) ->
  receive
    { phase2, response, PID, BallotI, Slot, Cmd } ->
      case (BallotI == Ballot andalso sets:is_element(PID, WaitFor)) of
        true  ->
          WaitForO  = sets:remove_element(PID, WaitFor),
          case (sets:size(WaitForO) < (Size / 2)) of
            true  -> [ R ! { decision, self(), Slot, Cmd } || R <- Replicas ];
            false -> next(Leader, Replicas, Ballot, Slot, Cmd, WaitForO, Size)
          end ;
        false ->
          Leader ! { preempted, self(), Ballot }
      end
  end,
  done.
