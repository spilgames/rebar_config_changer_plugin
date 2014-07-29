%%% @doc Prepares application for a 'piqi defs' compile run.
%%%
%%% Should only be used for applications which bundle piqi defs.
%%%
%%% If plugin is included in 'CURRENT' application, plugin:
%%%
%%% 1. replaces erl_opts with defs_erl_opts
%%% 2. replaces pre_hooks with defs_pre_hooks
%%% 3. replaces deps with defs_deps
%%%
%%% After the get-deps/compile run the config is put back.
-module(rebar_config_changer_plugin).

-export(['pre_compile'/2, 'post_compile'/2,
         'pre_get-deps'/2, 'post_get-deps'/2]).

%% =============================================================================
%% Rebar plugin API
%% =============================================================================

'pre_get-deps'(Config, AppFile) ->
    maybe_change_config(Config, AppFile).

'post_get-deps'(Config, AppFile) ->
    maybe_config_restore(Config, AppFile).

'pre_compile'(Config, AppFile) ->
    maybe_change_config(Config, AppFile).

'post_compile'(Config, AppFile) ->
    maybe_config_restore(Config, AppFile).

%% =============================================================================
%% Internals
%% =============================================================================

maybe_change_config(Config, AppFile) ->
    case replaceables(Config) of
        [] -> skip(AppFile);
        Repl -> {ok, change_config(Config, AppFile, Repl)}
    end.

maybe_config_restore(Config, AppFile) ->
    case replaceables(Config) of
        [] -> skip(AppFile);
        _Repl -> {ok, config_restore(Config, AppFile)}
    end.

skip(AppFile) ->
    rebar_log:log(debug, "Not explicit plugin, skipping ~s~n", [AppFile]).

change_config(Config, AppFile, Repl) ->
    lists:foldl(
      fun({DefsKey, NormalKey}, Config1) ->
              Config2 = config_backup(Config1, DefsKey, []),
              DefsVal = rebar_config:get_local(Config2, DefsKey, []),
              rebar_log:log(debug, "Setting ~s:'~p' => '~w'~n",
                            [filename:basename(AppFile), NormalKey, DefsVal]),
              rebar_config:set(Config2, NormalKey, DefsVal)
      end,
      Config,
      Repl
     ).

config_backup(Config, Key, Default) ->
    ConfigBk = rebar_config:get_xconf(Config, config_bk, []),
    Value = rebar_config:get_local(Config, Key, Default),
    ConfigBk2 = [{Key, Value} | ConfigBk],
    rebar_config:set_xconf(Config, config_bk, ConfigBk2).

config_restore(Config1, AppFile) ->
    Config2 = lists:foldl(
      fun({Key, Value}, Config) ->
              rebar_log:log(debug, "Unsetting ~s:'~p' ž> '~w'~n",
                            [filename:basename(AppFile), Key, Value]),
              rebar_config:set(Config, Key, Value)
      end,
      Config1,
      rebar_config:get_xconf(Config1, config_bk)
     ),
    rebar_config:erase_xconf(Config2, config_bk).

replaceables(Config) ->
    rebar_config:get_local(Config, ?MODULE, []).
