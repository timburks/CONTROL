
(function generate-launchd-plist (CONTAINER NAME PORT)
          ((dict Label:(+ "net.control.app." PORT)
              OnDemand:(NSNumber numberWithBool:NO)
              UserName:"control"
      WorkingDirectory:(+ CONTROL-PATH "/workers/" CONTAINER "/" NAME ".app")
  EnvironmentVariables:(dict AGENTBOX-CONTAINER: CONTAINER
                                  AGENTBOX-PORT: PORT
                               AGENTBOX-APPNAME: NAME)
       StandardOutPath:(+ CONTROL-PATH "/workers/" CONTAINER "/var/stdout.log")
     StandardErrorPath:(+ CONTROL-PATH "/workers/" CONTAINER "/var/stderr.log")
      ProgramArguments:(array "sandbox-exec"
                              "-f"
                              (+ CONTROL-PATH "/workers/" CONTAINER "/sandbox.sb")
                              (+ CONTROL-PATH "/workers/" CONTAINER "/" NAME ".app/" NAME)
                              "-p"
                              (PORT stringValue)))
           XMLPropertyListRepresentation))

