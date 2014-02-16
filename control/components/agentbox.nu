
(function lookup-user (username password)
          (puts "lookup-user")
          (mongo findOne:(dict username:username) inCollection:(+ SITE ".users")))

(function create-user (username password)
          (puts (+ "create-user" username password))
          (if (set user (lookup-user username password))
              (puts "user exists")
              (return nil))
          (puts "creating user")
          (set user (dict username:username
                          password:(password md5HashWithSalt:PASSWORD_SALT)
                            secret:((RadUUID new) stringValue)))
          (mongo updateObject:user
                 inCollection:(+ SITE ".users")
                withCondition:(dict username:username)
            insertIfNecessary:YES
        updateMultipleEntries:NO)
          (mongo findOne:(dict username:username) inCollection:(+ SITE ".users")))

(function add-app (app)
          (mongo insertObject:app intoCollection:(+ SITE ".apps")))

(function add-version (app appfile-name appfile-data)
          (set version ((RadUUID new) stringValue))
          (mongo writeData:appfile-data
                     named:version
              withMIMEType:"application/zip"
              inCollection:"appfiles"
                inDatabase:SITE)
          (set version
               (dict version:version
                    filename:appfile-name
                  created_at:(NSDate date)))
          
          (set versions (or (app versions:) (array)))
          (versions addObject:version)
          (set update (dict versions:versions))
          (mongo updateObject:(dict $set:update)
                 inCollection:(+ SITE ".apps")
                withCondition:(dict _id:(app _id:))
            insertIfNecessary:NO
        updateMultipleEntries:NO)
          (puts "updating")
          (puts (update description))
          (puts "for app")
          (puts (app description))
          version)

(function get-busy-ports ()
          (set apps (mongo findArray:nil inCollection:(+ SITE ".apps")))
          (set ports (NSMutableSet set))
          (apps each:
                (do (app)
                    (((app deployment:) workers:) each:
                     (do (worker) (ports addObject:(worker port:))))))
          ports)

(function get-next-available-port (busy-ports start)
          (set port (+ 1 start))
          (while (busy-ports containsObject:port)
                 (set port (+ port 1)))
          port)

(function deploy-version (app version-name)
          (set versions (app versions:))
          (set versions (versions select:
                                  (do (version) (eq (version version:) version-name))))
          (if (eq (versions count) 1)
              (then (set appfile-name ((versions 0) filename:))
                    (set app-name (appfile-name stringByDeletingPathExtension))
                    (puts (+ "deploying " version-name " with " appfile-name))
                    (if (app deployment:) (halt-app-deployment app))
                    (set busy-ports (get-busy-ports))
                    (set port 9000)
                    (set workers (array))
                    (unless (set worker-count (app workers:))
                            (set worker-count 1))
                    ((worker-count) times:
                     (do (i)
                         (set container ((RadUUID new) stringValue))
                         (set path (+ CONTROL-PATH "/workers/" container))
                         (puts "Creating directory at path " path)
                         (set result
                              ((NSFileManager defaultManager)
                               createDirectoryAtPath:path withIntermediateDirectories:YES
                               attributes:nil error:nil))
                         (puts (+ "result: " result))
                         
                         (set data
                              (mongo retrieveDataForGridFSFile:version-name
                                                  inCollection:"appfiles"
                                                    inDatabase:SITE))
                         (data writeToFile:(+ path "/" appfile-name) atomically:NO)
                         
                         (set command (+ "cd " path "; unzip " appfile-name))
                         (puts command)
                         (system command)
                         ((NSFileManager defaultManager)
                          createDirectoryAtPath:(+ path "/var") withIntermediateDirectories:YES attributes:nil error:nil)
                         ("" writeToFile:(+ path "/var/stdout.log") atomically:NO)
                         ("" writeToFile:(+ path "/var/stderr.log") atomically:NO)
                         (set command (+ "chmod -R ugo+rX " path))
                         (puts command)
                         (system command)
                         (set command (+ "chown -R control " path "/var"))
                         (puts command)
                         (system command)
                         (set command (+ "chmod -R ug+w " path "/var"))
                         (puts command)
                         (system command)
                         
                         (set port (get-next-available-port busy-ports port))
                         
                         (if (eq (uname) "Linux")
                             (then (set upstart-config (generate-upstart-config container app-name port app))
                                   (upstart-config writeToFile:(+ "/etc/init/agentio-worker-" port ".conf") atomically:NO)
                                   (system (+ "/sbin/initctl start agentio-worker-" port)))
                             (else (set sandbox-sb (generate-sandbox-description container app-name port))
                                   (sandbox-sb writeToFile:(+ CONTROL-PATH "/workers/" container "/sandbox.sb") atomically:NO)
                                   (set launchd-plist (generate-launchd-plist container app-name port))
                                   (launchd-plist writeToFile:(+ "/Library/LaunchDaemons/net.control.app." port ".plist") atomically:NO)
                                   (system (+ "launchctl load /Library/LaunchDaemons/net.control.app." port ".plist"))))
                         (workers << (dict port:port host:"localhost" container:container))))
                    
                    (set deployment (dict version:version-name
                                             name:app-name
                                          workers:workers))
                    (mongo updateObject:(dict $set:(dict deployment:deployment))
                           inCollection:(+ SITE ".apps")
                          withCondition:(dict _id:(app _id:))
                      insertIfNecessary:NO
                  updateMultipleEntries:NO)
                    (restart-nginx)
                    deployment)
              (else
                   (puts (+ "unable to deploy; can't find " version-name))
                   nil)))

(function redeploy ()
          (set apps (mongo findArray:nil inCollection:(+ SITE ".apps")))
          (apps each:
                (do (app)
                    (puts (app name:))
                    (set deployment (app deployment:))
                    (set version-name (deployment version:))
                    (set appfile-name nil)
                    (puts "version name: #{version-name}")
                    ((app versions:) each:
                     (do (version)
                         (if (eq version-name (version version:))
                             (set appfile-name (version filename:)))))
                    (puts "appfile name: #{appfile-name}")
                    (if appfile-name
                        (then ((deployment workers:) each:
                               (do (worker)
                                   (puts "WORKER #{(worker description)}")
                                   (set container (worker container:))
                                   ;; create container directory
                                   (set path (+ CONTROL-PATH "/workers/" container))
                                   (puts "Creating directory at path " path)
                                   (set result
                                        ((NSFileManager defaultManager)
                                         createDirectoryAtPath:path withIntermediateDirectories:YES
                                         attributes:nil error:nil))
                                   (puts (+ "result: " result))
                                   ;; write app zip file into container
                                   (set data
                                        (mongo retrieveDataForGridFSFile:version-name
                                                            inCollection:"appfiles"
                                                              inDatabase:SITE))
                                   (data writeToFile:(+ path "/" appfile-name) atomically:NO)
                                   ;; unzip app
                                   (set command (+ "cd " path "; unzip " appfile-name))
                                   (puts command)
                                   (system command)
                                   ;; create support directories
                                   ((NSFileManager defaultManager)
                                    createDirectoryAtPath:(+ path "/var") withIntermediateDirectories:YES attributes:nil error:nil)
                                   ("" writeToFile:(+ path "/var/stdout.log") atomically:NO)
                                   ("" writeToFile:(+ path "/var/stderr.log") atomically:NO)
                                   (set command (+ "chmod -R ugo+rX " path))
                                   (puts command)
                                   (system command)
                                   (set command (+ "chown -R control " path "/var"))
                                   (puts command)
                                   (system command)
                                   (set command (+ "chmod -R ug+w " path "/var"))
                                   (puts command)
                                   (system command)
                                   (set port (worker port:))
                                   
                                   (set sandbox-sb (generate-sandbox-description container (app name:) port))
                                   (sandbox-sb writeToFile:(+ CONTROL-PATH "/workers/" container "/sandbox.sb") atomically:NO)
                                   
                                   (set launchd-plist (generate-launchd-plist container (app name:) port))
                                   (launchd-plist writeToFile:(+ "/Library/LaunchDaemons/net.control.app." port ".plist") atomically:NO)
                                   (system (+ "launchctl load /Library/LaunchDaemons/net.control.app." port ".plist")))))
                        (else "version is unknown"))
                    (puts ((app deployment:) description))
                    ))
          (restart-nginx))





(function halt-app-deployment (app)
          ;; get deployment
          (set deployment (app deployment:))
          ;; stop workers
          ((deployment workers:) each:
           (do (worker)
               (if (eq (uname) "Linux")
                   (then (set port (worker port:))
                         (set upstart-config-name (+ "/etc/init/agentio-worker-" port ".conf"))
                         (system (+ "/sbin/initctl stop agentio-worker-" port))
                         ((NSFileManager defaultManager) removeItemAtPath:upstart-config-name error:nil))
                   (else (set launchd-plist-name (+ "/Library/LaunchDaemons/net.control.app."
                                                    (worker port:) ".plist"))
                         (system (+ "launchctl unload " launchd-plist-name))
                         ((NSFileManager defaultManager) removeItemAtPath:launchd-plist-name error:nil)))
               (if (set container (worker container:))
                   ((NSFileManager defaultManager) removeItemAtPath:(+ CONTROL-PATH "/workers/" container)
                    error:nil))))
          ;; remove deployment from database
          (mongo updateObject:(dict $unset:(dict deployment:1))
                 inCollection:(+ SITE ".apps")
                withCondition:(dict _id:(app _id:))
            insertIfNecessary:NO
        updateMultipleEntries:NO)
          (restart-nginx))
