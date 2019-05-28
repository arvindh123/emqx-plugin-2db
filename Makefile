PROJECT = emqx_plugin_2db
PROJECT_DESCRIPTION = EMQ X Plugin 2db
PROJECT_VERSION = 1.00


BUILD_DEPS = emqx cuttlefish

dep_emqx = git-emqx https://github.com/emqx/emqx $(BRANCH)
dep_cuttlefish = git-emqx https://github.com/emqx/cuttlefish v2.2.1

ERLC_OPTS += +debug_info

NO_AUTOPATCH = cuttlefish

COVER = true

$(shell [ -f erlang.mk ] || curl -s -o erlang.mk https://raw.githubusercontent.com/emqx/erlmk/master/erlang.mk)

include erlang.mk

app:: rebar.config

app.config::
	./deps/cuttlefish/cuttlefish -l info -e etc/ -c etc/emqx_plugin_2db.conf -i priv/emqx_plugin_2db.schema -d data
