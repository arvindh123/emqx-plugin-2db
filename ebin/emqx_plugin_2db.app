{application,emqx_plugin_2db,
             [{description,"EMQ X Plugin 2db"},
              {vsn, "test-tag-82-g744bff4c"},
              {modules, ['emqx_plugin_2db','emqx_plugin_2db_app','emqx_plugin_2db_sup']},
              {registered,[emqx_plugin_2db_sup]},
              {applications,[kernel,stdlib]},
              {mod,{emqx_plugin_2db_app,[]}}]}.
