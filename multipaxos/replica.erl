%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(replica).
-export([start/2]).

start(Database, End_after) ->
  receive
    { bind, Leaders } ->
      timer:send_after(End_after, { finish }),
      next(Database, Leaders, 1, 1, sets:new(), maps:new(), maps:new())
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
      case not maps:is_key(SlotIn, Decisions) of
        true ->
          [ Cmd | Rest ] = sets:to_list(Requests),
          RequestsO = sets:from_list(Rest),
          ProposalsO = maps:put(SlotIn, Cmd, Proposals),
          [ L ! { propose, SlotIn, Cmd } || L <- sets:to_list(Leaders) ] ;
        false ->
          { RequestsO, ProposalsO } = { Requests, Proposals }
      end,
      propose(Leaders, SlotIn + 1, SlotOut,
              RequestsO, ProposalsO, Decisions) ;
    false ->
      { SlotIn, Requests, Proposals }
  end.

decide(SlotOut, Requests, Proposals, Decisions, Database) ->
  case maps:is_key(SlotOut, Decisions) of
    true  ->
      Cmd = maps:get(SlotOut, Decisions),
      RequestsO = sets:union(Requests, sets:from_list([
        C || { Slot, C } <- maps:to_list(Proposals),
        Slot == SlotOut, C /= Cmd
      ])),
      ProposalsO = maps:remove(SlotOut, Proposals),
      decide(
        perform(SlotOut, Cmd, Decisions, Database),
        RequestsO, ProposalsO, maps:remove(SlotOut, Decisions),
        Database
      );
    false ->
      { Requests, Proposals, SlotOut }
  end.

perform(SlotOut, { Client, Cid, Op }, Decisions, Database) ->
  LowerSlot = lowerSlot(SlotOut, { Client, Cid, Op }, Decisions),
  case LowerSlot of
    true  -> SlotOut_ = SlotOut + 1 ;
    false -> SlotOut_ = SlotOut
  end,
  Database ! { execute, Op },
  Client ! { response, Cid, ok },
  SlotOut_ + 1.

lowerSlot(SlotOut, Cmd, Decisions) ->
  length([
    1 || { Slot, C } <- maps:to_list(Decisions),
    Slot < SlotOut, C == Cmd
  ]) > 0.
