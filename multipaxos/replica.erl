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
      RequestsO = sets:add_element(Cmd, Requests),
      next(Database, Leaders, SlotIn, SlotOut, RequestsO, Proposals, Decisions);
    { decision, Slot, Cmd } ->
      DecisionsO = maps:put(Slot, Cmd, Decisions),
      { RequestsO, ProposalsO, SlotOutO } =
        decide(SlotOut, Requests, Proposals, DecisionsO, Database),
      next(Database, Leaders, SlotIn, SlotOutO, RequestsO, ProposalsO, DecisionsO)
  after 0 ->
    { SlotInO, RequestsO, ProposalsO } = propose(
      Leaders, SlotIn, SlotOut, Requests, Proposals, Decisions
    ),
    next(Database, Leaders, SlotInO, SlotOut, RequestsO, ProposalsO, Decisions)
  end.

propose(Leaders, SlotIn, SlotOut, Requests, Proposals, Decisions) ->
  Window = 5,
  case (SlotIn < SlotOut + Window andalso sets:size(Requests) > 0) of
    true ->
      case not maps:iskey(SlotIn, Decisions) of
        true ->
          [ Cmd | Rest ] = sets:to_list(Requests),
          RequestsO = sets:from_list(Rest),
          ProposalsO = sets:add_element({ SlotIn, Cmd }, Proposals),
          [ L ! { propose, SlotIn, Cmd }  || L <- Leaders ]
      end,
      propose(Leaders, SlotIn + 1, SlotOut, RequestsO, ProposalsO, Decisions) ;
    false ->
      { SlotIn, Requests, Proposals }
  end.

decide(SlotOut, Requests, Proposals, Decisions, Database) ->
  case maps:is_key(SlotOut, Decisions) of
    true  ->
      Cmd = maps:get(SlotOut, Decisions),
      RequestsO = sets:union(Requests, sets:from_list([
        C || { Slot, C } <- Proposals,
        Slot == SlotOut, C /= Cmd
      ])),
      ProposalsO = Proposals -- sets:from_list([
        { Slot, C } || { Slot, C } <- Proposals,
        Slot == SlotOut
      ]),
      decide(
        perform(SlotOut, Cmd, Database),
        RequestsO, ProposalsO, map:remove(SlotOut, Decisions),
        Database
      );
    false -> { Requests, Proposals, SlotOut }
  end.

perform(SlotOut, { Client, Cid, Op }, Database) ->
    Database ! { execute, Op },
    Client ! { response, Cid, ok},
    SlotOut + 1.
