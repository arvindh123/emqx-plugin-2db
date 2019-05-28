-module(emqx_plugin_2db).

-include_lib("emqx/include/emqx.hrl").

 
-import(string,[len/1]). 

-export([load/5, unload/0]).

%% Hooks functions


-export([on_message_publish/6]).

-export([init/0, deinit/0, connect/2, disconnect/1, write/4, try_get_val/3, try_get_ts/2 ]).

init()->
   
	case odbc:start()  of 
        ok ->
            io:fwrite("Started ODBC ~n"),
            {ok, "Started odbc"};
            
        {error,{already_started,odbc}} ->
            io:fwrite("Already Connceted ~n"),
            {error, "already started odbc"}
    end.

deinit()->
    case odbc:stop() of 
        ok ->
            io:fwrite("Stoped ODBC ~n"),
            {ok, "Stopped odbc"}
    end.

connect(Odbc,NamePid) ->
    case whereis(NamePid) of 
        undefined ->
            case odbc:connect("DSN="++lists:nth(1,Odbc)++";UID="++lists:nth(2,Odbc)++";PWD="++lists:nth(3,Odbc), []) of 
                {ok, Pid}->
                    try register(NamePid, Pid)
                    catch 
                        error:X -> 
                            io:fwrite(X)
                             
                            
                    end,
                    io:fwrite("Connected successfully ~n"),
                    {ok,{"Connected Pid- ", Pid}};
                {error, Value} ->
                    io:fwrite("~p ~n", [Value]),
                    if 
                        Value == 'odbc_not_started' ->
                            case emqx_plugin_2db:init() of 
                                {ok,Val} ->
                                    emqx_plugin_2db:connect(Odbc,NamePid)
                            end;
                        true->
                            io:fwrite("~p ~n", [Value]),
                            {error,Value}
                    end
                    
            end;
        Pid ->
            io:fwrite("Already Connected with PID - ~p~n",[Pid]),
            {ok, Pid}
    end. 
    
disconnect(NamePid) ->
    case whereis(NamePid) of 
        undefined ->
            {ok, {"there no ODBC "}};
        Pid ->
            odbc:disconnect(Pid),
            {ok, {"disconnected -", Pid}}
    end.

write(Odbc,NamePid,Que1,Que2) ->
   
    case whereis(NamePid) of 
        undefined ->
            case emqx_plugin_2db:connect(Odbc,NamePid) of 
                {ok,Reason} ->
                    write(Odbc,NamePid,Que1,Que2);
                {error,Reason} ->
                    {error, Reason}
            end;
        Pid ->
            
            case odbc:param_query(Pid,Que1,Que2)  of 
                
                {error,Reason} ->
                    io:format("odbc:param_query Error in Writing to DB: ~p~n", [Reason]);
                ResultTuple ->
                    ok
                    % io:format("odbc:param_query ResultTuple: ~p~n", [ResultTuple])
                
            end

    end.

try_get_ts(Message,MessageMaps) -> 
    case maps:is_key(<<"ts">>  ,MessageMaps) of  
        true-> 
            TimeBin = maps:get(<<"ts">> ,MessageMaps),
            case  is_binary(TimeBin) of 
                true -> binary_to_list(TimeBin);
                false -> lists:flatten(io_lib:format("~p", [TimeBin]));
                undefined ->lists:flatten(io_lib:format("~p", [TimeBin]))
            end;     
        false-> 
            Timestamp1 = lists:flatten(io_lib:format("~p", [element(1, element(9, Message))])),
            Timestamp2 = lists:flatten(io_lib:format("~p", [element(2, element(9, Message))])),
            Timestamp3 = lists:flatten(io_lib:format("~p", [element(3, element(9, Message))])),
            Timetemp = string:concat(Timestamp1,Timestamp2),
            TimestampStr = string:concat(Timetemp,Timestamp3),
            TimestampStr;
        undefined -> 
            Timestamp1 = lists:flatten(io_lib:format("~p", [element(1, element(9, Message))])),
            Timestamp2 = lists:flatten(io_lib:format("~p", [element(2, element(9, Message))])),
            Timestamp3 = lists:flatten(io_lib:format("~p", [element(3, element(9, Message))])),
            Timetemp = string:concat(Timestamp1,Timestamp2),
            TimestampStr = string:concat(Timetemp,Timestamp3),
            TimestampStr   
    end.

try_get_val(Key,MessageMaps,Dt) -> 
    case maps:is_key(Key ,MessageMaps) of  
        true-> 
            if Dt == "string" -> 
                try 
                    binary_to_list(maps:get(Key,MessageMaps))
                catch 
                    error:X -> 
                        io:fwrite(X),
                        ""
                end;
            true -> 
               maps:get(Key,MessageMaps)
            end;
        false-> 
            if 
                Dt == "int" -> 0; 
                Dt == "string" -> ""; 
                true -> "" 
            end; 
        undefined -> 
            if
                Dt == "int" -> 0; 
                Dt == "string" -> ""; 
                true -> "" 
            end    
    end.

%% Called when the plugin application start
load(Odbc,Topics,ReqkeysList,Que1s,Que2s) ->
    emqx:hook('message.publish', fun ?MODULE:on_message_publish/6, [Odbc,Topics,ReqkeysList,Que1s,Que2s]).



on_message_publish(Message = #message{topic = <<"$SYS/", _/binary>>}, _Odbc, _Topics, _ReqkeysList, _Que1s, _Que2s) ->
    {ok, Message};

on_message_publish(Message, Odbc, Topics,ReqkeysList,Que1s,Que2s) ->
    % io:format("publish ~s~n", [emqx_message:format(Message)]),
    
    TopicBin = element(7, Message),
    
    case lists:keyfind(TopicBin, 1,Topics)  of 
        {Topic, Index} ->
            TopicStr = binary_to_list(TopicBin),
            MessageBin = element(8, Message),
    
            case jsx:is_json(MessageBin)  of  
                true -> 
                    MessageMaps = jsx:decode(MessageBin, [return_maps]),
                    case lists:any(fun (Elem) -> lists:member(Elem, lists:nth(Index,ReqkeysList)) end, maps:keys(MessageMaps) ) of 
                        true->
                            % try
                                UsernameBin = maps:get(username, element(6, Message)),
                                % io:format("UsernameBin.....~p~n ", [UsernameBin]),

                                ClientBin = element(4, Message),
                                % io:format("ClientBin.....~p~n ", [ClientBin]),

                                ClientBinRe = re:replace(ClientBin, "\\s+", "", [global,{return,binary}]),
                                % io:format("ClientBinRe.....~p~n ", [ClientBinRe]),

                                NamePid = binary_to_atom(<<"pid_",  ClientBinRe/binary>>, unicode),
                                % io:format("NamePid.....~p~n ", [NamePid]),

                                ClientStr = binary_to_list(ClientBin),
                                % io:format("ClientStr.....~p~n ", [ClientStr]),

                                UsernameStr = binary_to_list(UsernameBin),
                                % io:format("UsernameStr.....~p~n ", [UsernameStr]),

                                Que1 = lists:nth(Index,Que1s),
                                TQue2 =  lists:nth(Index,Que2s),

                                {ok, Tokens, _} = erl_scan:string(TQue2),  
                                {ok, Parsed} = erl_parse:parse_exprs(Tokens), 
                                Bindings = [{'Message', Message}, {'MessageMaps', MessageMaps}],    
                                {value, Que2, _} = erl_eval:exprs(Parsed, Bindings), 
                            
                                % io:format("Que1.....~p~n ", [Que1]),
                                % io:format("Que2.....~p~n ", [Que2]),

                                write(Odbc,NamePid,Que1,Que2),
                                {ok, Message};
                            % catch 
                            %     error:X -> 
                            %         io:fwrite(X)
                            % end; 
                        false->
                            {error, "no required Key in JSON"}
                    end;
                false ->
                    {error, "not json string"};

                undefined ->
                    {error, "dont'know, undefined"}
            end;
        false->
            {error ,"Topic Not mactched"};
        undefined -> 
            {error ,"Topic undefined"}
    end.




%% Called when the plugin application stop
unload() ->
    emqx:unhook('message.publish', fun ?MODULE:on_message_publish/2).

