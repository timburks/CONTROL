
(function generate-upstart-config (CONTAINER NAME PORT APP) <<-END
#
# AUTOMATICALLY GENERATED 
#
start on runlevel [2345]
setuid control
chdir #{CONTROL-PATH}/workers/#{CONTAINER}/#{NAME}.app
env AGENT_DOMAINS='#{(APP domains:)}'
env AGENT_HOST='#{(NSString stringWithShellCommand:"hostname")}'
env AGENT_NAME='#{(APP name:)}'
env AGENT_PATH='#{(APP path:)}'
exec ./#{NAME} -p #{PORT}
respawn
respawn limit 10 90
END)
