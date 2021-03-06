-module(mock_feedback_service).
-author('Yura Zhloba <yzh44yzh@gmail.com>').

-export([start/0, accept/3]).
-include("logger.hrl").
-include("types.hrl").

%%% module API

start() ->
    ssl:start(),
    {ok, AProps} = application:get_env(dp_push, apns),
    {ok, CProps} = application:get_env(dp_push, cert),
    Port = proplists:get_value(feedback_port, AProps),
    Certfile = proplists:get_value(certfile, CProps),
    Password = proplists:get_value(password, CProps),
    ?INFO("start ~p at port ~p~n", [?MODULE, Port]),
    {ok, LSocket} = ssl:listen(Port, [{certfile, Certfile}, {password, Password},
				      {reuseaddr, true}, {active, false}]),
    spawn(?MODULE, accept, [LSocket, Certfile, Password]).

accept(LSocket, Certfile, Password) ->
    {ok, Socket} = ssl:transport_accept(LSocket),
    ssl:ssl_accept(Socket),
    ?INFO("~p send data to ~p~n", [?MODULE, Socket]),
    ssl:send(Socket, get_data()),
    ssl:close(Socket),
    ?MODULE:accept(LSocket, Certfile, Password).

get_data() ->
    DT1 = dp_push_apns:test_token(1),
    DT2 = dp_push_apns:test_token(2),
    list_to_binary([
      [70,12,47,78,0,32,146,83,222,18,247,29,48,13,5,161,17,53,224,158,9,
       182,50,196,120,213,50,49,55,35,31,4,167,199,180,222,148,125],
      [70,12,47,78,0,32,146,83,222,18,247,29,48,13,5,161,17,53,224,158,9,
       182,50,196,120,213,50,49,55,35,31,4,167,199,180,222,148,120],
      [70,12,47,78,0,32,146,83,222,18,247,29,48,13,5,161,17,53,224,158,9,
       182,50,196,120,213,50,49,55,35,31,4,167,199,180,222,148,115],
      <<1,2,3,4,0,32,DT1:256/integer>>,
      <<1,2,3,4,0,32,DT2:256/integer>>
     ]).
