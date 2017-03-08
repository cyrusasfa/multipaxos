%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(commander).
-export([start/6]).

start(Leader, Acceptors, Replicas, Ballot, Slot, Cmd) ->
  WaitFor = sets:from_list(Acceptors),
  [ P ! { phase2, request, self(), Ballot, Slot, Cmd } || P <- WaitFor ],
  next(Leader, Replicas, Ballot, Slot, Cmd, WaitFor, sets:size(WaitFor)).

next(Leader, Replicas, Ballot, Slot, Cmd, WaitFor, Size) ->
  receive
    { phase2, response, PID, Ballot, Slot, Cmd } ->
      case (sets:is_element(PID, WaitFor)) of
        true  ->
          WaitForN  = sets:remove_element(PID),
          case (sets:size(WaitForN) < (Size / 2)) of
            true  -> [ R ! { decision, self(), Slot, Cmd } || R <- Replicas ];
            false -> next(Leader, Replicas, Ballot, Slot, Cmd, WaitForN, Size)
          end ;
        false ->
          Leader ! { preempted, self(), Ballot }
      end
  end,
  done.
