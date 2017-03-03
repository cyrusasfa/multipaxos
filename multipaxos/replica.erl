%%% Frederick Lindsey (fl1414) and Cyrus Vahidi (cv114)

-module(replica).
-export([start/1]).

start(Database) ->
  receive
    {bind, Leaders} ->
       next(...)
  end.

next(...) ->
  receive
    {request, C} ->      % request from client
      ...
    {decision, S, C} ->  % decision from commander
      ... = decide (...)
  end, % receive

  ... = propose(...),
  ...

propose(...) ->
  WINDOW = 5,
  ...

decide(...) ->
  ...
       perform(...),
  ...

perform(...) ->
  ...
      Database ! {execute, Op},
      Client ! {response, Cid, ok}
