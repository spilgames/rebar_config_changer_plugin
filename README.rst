Rebar configuration changer plugin
==================================

**#!?**

What is it
----------

This plugin helps to change ``rebar.config`` during compile run-time.

Use case
--------

An immediate use case for the plugin: let's assume git repository holds a
a service which consists of two parts:

1. Service implementation (erlang_).
2. Service definition (piqi_ or proto_ files).

Everything is good when the repository is treated as a standalone service.
Rebar supports that. However, things start to get fun when you need "only part
of the source" compiled.

There are mainly two things that change when a full-blown service becomes
"source of definitions":

1. ``{deps, [...]}.``. Only subset of dependencies are required to build the
   definition.
2. ``{erl_opts, [{src_dirs, ["src_defs"]}]}``. This is the bad one. By default,
   we keep the "normal" implementation files in ``src``, while ``src_defs``
   holds the compiled definitions (``service_piqi.erl``, etc). When service
   is compiled standalone, ``src_dirs`` is ``["src", "src_defs"]``, so both
   definition and service are compiled. During definition compilation, ``src``
   has to be gone from ``src_dirs``.

It could almost be done in ``rebar.config.script``, but ``erl_opts`` is a
tricky one. Most projects do not have it and assume default (``["src"]``).
However, this value is inherited if parent project has this value set.

Usage
-----

In order to simply replace arbitrary values in your project during compile
time, do this in your project's ``rebar.config``::

    {defs_erl_opts,[debug_info, {src_dirs, ["src_defs"]}]}.
    {rebar_config_changer_plugin, [
        {defs_erl_opts, erl_opts}]
    }.

Only that is not going to change anything. We need to activate the plugin on
the parent::

    {deps,[
        {rebar_config_changer_plugin,"0.0.1",
          {git,"git@github.com:spilgames/rebar_config_changer_plugin.git",
              {tag,"0.0.1"}}},
    ]}.
    {plugins, [rebar_config_changer_plugin]}.


Rebar caveats
----------------

Changing ``deps`` during runtime does not help with the plugin. Rebar reads
dependencies too early for them to be processed on time by the plugin.
Therefore the "definition's" project's dependencies have to be set in
``rebar.config.script``.

----------------

``rebar_app_utils:is_app_dir/1`` does not support ``{src_dirs, ...}`` option
when scanning for dependencies at early stages. If "src" exists,
it always takes precedence, even if ``rebar.config.script`` says otherwise.
If for example you'd want to exclude the "src" directory in a definition's
project you'll have to add a ``your_app.app.src.script`` file to only include
the kernel and stdlib applications as well as empty the mod option.

``your_app.app.src.script`` example::


    DefsApps = {applications, [kernel, stdlib]},
    [{application, App, Props}] = CONFIG,
    Props2 = lists:keyreplace(applications, 1, Props, DefsApps),
    Props3 = lists:keydelete(mod, 1, Props2),
    [{application, App, Props3}]

.. _piqi: http://piqi.org/
.. _proto: https://developers.google.com/protocol-buffers/
.. _erlang: http://www.erlang.org/
