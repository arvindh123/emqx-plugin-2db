%%--------------------------------------------------------------------
%% Copyright (c) 2013-2018 EMQ Enterprise, Inc. (http://emqx.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_plugin_2db_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-define(APP, emqx_plugin_2db).

start(_StartType, _StartArgs) ->
    {ok, Sup} = emqx_plugin_2db_sup:start_link(),
    Env = element(2,application:get_key(env)),
    Odbc = element(2,lists:keyfind(odbc,1,Env)),
    Topics = element(2,lists:keyfind(topics,1,Env)),
    ReqkeysList = element(2,lists:keyfind(reqlist,1,Env)),
    Que1s = element(2,lists:keyfind(que1,1,Env)),
    Que2s = element(2,lists:keyfind(que2,1,Env)),
    emqx_plugin_2db:load(Odbc,Topics,ReqkeysList,Que1s,Que2s),
    {ok, Sup}.

stop(_State) ->
    emqx_plugin_2db:unload().
