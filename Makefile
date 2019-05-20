PROJECT = emqx_plugin_2db
PROJECT_DESCRIPTION = EMQ X Plugin 2 DB
PROJECT_VERSION = 2.3.11

BUILD_DEPS = emqx cuttlefish
dep_emqx = git https://github.com/emqx/emqx master
dep_cuttlefish = git https://github.com/emqx/cuttlefish v2.0.11

ERLC_OPTS += +debug_info
ERLC_OPTS += +'{parse_transform, lager_transform}'

NO_AUTOPATCH = cuttlefish

COVER = true

include erlang.mk

app:: rebar.config

app.config::
	./deps/cuttlefish/cuttlefish -l info -e etc/ -c etc/emqx_plugin_2db.conf -i priv/emqx_plugin_2db.schema -d data
