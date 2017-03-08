%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(replica).
-export([start/1]).

start(Database) ->
  receive
    {bind, Leaders} ->
       next(Database, Leaders, 1, 1, sets:new(), sets:new(), maps:new())
  end.

next(Database, Leaders, SlotIn, SlotOut, Requests, Proposals, Decisions) ->
  receive
    { request, Cmd } ->
      RequestsO = sets:add_element(Cmd, Requests) ;
    { decision, Slot, Cmd } ->
      DecisionsO = maps:put(Slot, Cmd, Decisions),
      { RequestsO, ProposalsO } =
        decide(SlotOut, Cmd, Requests, Proposals, DecisionsO)

  end,
  done.

decide(SlotOut, Cmd, Requests, Proposals, Decisions) ->
  case maps:is_key(SlotOut, Decisions) of
    true  ->
      RequestsO = sets:union(Requests, sets:from_list([
        C || { Slot, C } <- Proposals,
        Slot == SlotOut, C /= Cmd
      ])),
      ProposalsO = Proposals -- sets:from_list([
        { Slot, C } || { Slot, C } <- Proposals,
        Slot == SlotOut
      ])
      % perform(Cmd, ),
      ;
    false -> { Requests, Proposals }
  end.

% perform(...) ->
%   ...
%       Database ! {execute, Op},
%       Client ! {response, Cid, ok}
