;; pages

(class NSArray
 (- subarraysOfN:n is
    (set a (array))
    (set current (array))
    (self each:
          (do (item)
              (if (eq (current count) 0)
                  (a << current))
              (current << item)
              (if (eq (current count) n)
                  (set current (array)))))
    a))

(function html-escape (s)
          ((((s stringByReplacingOccurrencesOfString:"&" withString:"&amp;")
             stringByReplacingOccurrencesOfString:"<" withString:"&lt;")
            stringByReplacingOccurrencesOfString:">" withString:"&gt;")
           stringByReplacingOccurrencesOfString:"\"" withString:"&quot;"))

(macro require-user ()
       `(unless (set account (get-user SITE))
                (return (RESPONSE redirectResponseToLocation:"/control/signin"))))

(macro require-authorization ()
       `(progn (set authorization ((REQUEST headers) Authorization:))
               (set parts (authorization componentsSeparatedByString:" "))
               (set credentials (NSString stringWithData:(NSData dataWithBase64EncodedString:(parts 1))
                                                encoding:NSUTF8StringEncoding))
               (set parts (credentials componentsSeparatedByString:":"))
               (set username (parts 0))
               (set password (parts 1))
               (set account (mongo findOne:(dict username:username
                                                 password:(password md5HashWithSalt:PASSWORD_SALT))
                              inCollection:(+ SITE ".users")))
               (unless account (return "unauthorized"))))

(get "/control"
     (require-user)
     (set apps (mongo findArray:(dict $query:(dict owner_id:(account _id:))
                                    $orderby:(dict name:1))
                   inCollection:(+ SITE ".apps")))
     (set worker-count 0)
     (apps each:
           (do (app)
               (set worker-count (+ worker-count (((app deployment:) workers:) count)))))
     (htmlpage "AgentBox"
               (&& (navbar "Home")
                   (&div class:"row"
                         (&div class:"large-12 columns"
                               (&p "Monitoring " (apps count) " apps. "
                                   "Running " worker-count " instances.")))
                   ((apps subarraysOfN:3) map:
                    (do (row)
                        (&div class:"row"
                              (row map:
                                   (do (app)
                                       (&div class:"large-4 columns end"
                                             (&div class:"panel" style:"margin:5px"
                                                   (progn
                                                         (if (and (app path:) ((app path:) length))
                                                             (then (set link (+ "/" (app path:))))
                                                             (else (set link (+ "http://" (((app domains:) componentsSeparatedByString:" ") 0)))))
                                                         (&div
                                                              (&h3 (&a href:link (app name:)))
                                                              (&p (app description:))
                                                              (&p (&a href:(+ "/control/apps/manage/" (app _id:)) "Manage it."))
                                                              ))))))
                              )))
                   )))

(get "/control/apps/add"
     (require-user)
     (htmlpage "Add an app"
               (&& (navbar "Add")
                   (&div class:"row"
                         (&div class:"large-12 columns"
                               (&h1 "Add an app")
                               (&form action:"/control/apps/add/"
                                          id:"edit" method:"post"
                                      (&dl (&dt (&label for:"app_name" "App name"))
                                           (&dd (&input id:"app_name" name:"name" size:"40" type:"text"))
                                           (&dt (&label for:"app_path" "App path"))
                                           (&dd (&input id:"app_path" name:"path" size:"40" type:"text"))
                                           (&dt (&label for:"app_domains" "App domains"))
                                           (&dd (&input id:"app_domains" name:"domains" size:"40" type:"text"))
                                           (&dt (&label for:"app_workers" "App workers"))
                                           (&dd (&select id:"app_workers" name:"workers"
                                                         ((array 1 2 3 4 5 6 7 8 9 10) map:
                                                          (do (i) (&option value:i i selected:(eq i 3))))))
                                           (&dt (&label for:"app_description" "Description"))
                                           (&dd (&textarea id:"app_description" name:"description"
                                                         rows:"5" cols:"60")))
                                      (&input name:"save" type:"submit" value:"Save")
                                      " or "
                                      (&a href:"/control" "Cancel")))))))

(post "/control/apps/add"
      (require-user)
      (set app (dict name:((REQUEST post) name:)
                     path:((REQUEST post) path:)
                  domains:((REQUEST post) domains:)
              description:((REQUEST post) description:)
                  workers:(((REQUEST post) workers:) intValue)
                 owner_id:(account _id:)))
      (set appid (add-app app))
      (RESPONSE redirectResponseToLocation:(+ "/control/apps/manage/" appid)))

(get "/control/apps/manage/appid:"
     (require-user)
     (set appid ((REQUEST bindings) appid:))
     (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
     (htmlpage (+ "Manage " (app name:))
               (&div (navbar "Manage")
                     (&div class:"row"
                           (&div class:"large-12 columns"
                                 (&h1 (app name:))
                                 (&table class:"table table-bordered"
                                         (&tr (&td "Path")
                                              (&td (app path:)))
                                         (&tr (&td width:"20%" "Domains")
                                              (&td
                                                  (((app domains:) componentsSeparatedByString:" ")
                                                   map:(do (domain)
                                                           (&span
                                                                 (&a href:(+ "http://" domain) domain) "&nbsp;")))))
                                         (&tr (&td "Description")
                                              (&td (app description:))))
                                 (&h3 "Versions")
                                 (if ((app versions:) count)
                                     (then (&table class:"table table-bordered"
                                                   ((app versions:) map:
                                                    (do (version)
                                                        (&tr (&td (version filename:))
                                                             (&td style:"font-size:80%;"
                                                                  (rss-date-formatter stringFromDate:(version created_at:))
                                                                  (&br)
                                                                  (version version:))
                                                             (&td (&a href:(+ "/control/apps/manage/delete/" appid "/" (version version:))
                                                                      "Delete"))
                                                             (&td (&a href:(+ "/control/apps/manage/deploy/" appid "/" (version version:))
                                                                      "Deploy")))))))
                                     (else (&p "No versions have been uploaded.")))
                                 (if (app deployment:)
                                     (+
                                       (&span style:"float:right" (&a href:(+ "/control/apps/manage/stop/" (app _id:)) "Stop"))
                                       (&h3 "Deployment")
                                       (&table class:"table table-bordered"
                                               (&tr (&td "name") (&td ((app deployment:) name:)))
                                               (&tr (&td "version") (&td ((app deployment:) version:)))
                                               (((app deployment:) workers:) map:
                                                (do (worker)
                                                    (+ (&tr (&td (&strong "worker"))
                                                            (&td (worker host:) ":" (worker port:)))
                                                       (&tr (&td) (&td (&a href:(+ "/control/apps/manage/" appid "/" (worker container:))
                                                                           (worker container:))))))))))
                                 (&form action:(+ "/control/apps/upload/" appid)
                                        method:"post"
                                       enctype:"multipart/form-data"
                                        (&p "To upload a new version of this app:")
                                        (&input type:"file" name:"appfile" size:40)
                                        (&input type:"submit" name:"upload" value:"upload"))
                                 (&hr style:"margin-top:2em;")
                                 (&a href:(+ "/control/apps/edit/" appid) "Edit this app")
                                 " | "
                                 (&a href:(+ "/control/apps/delete/" appid) "Delete this app"))))))

(get "/control/apps/manage/stop/appid:"
     (require-user)
     (set appid ((REQUEST bindings) appid:))
     (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
     (unless app (return nil))
     (halt-app-deployment app)
     (RESPONSE redirectResponseToLocation:(+ "/control/apps/manage/" appid)))

(get "/control/apps/manage/delete/appid:/version:"
     (require-user)
     (set appid ((REQUEST bindings) appid:))
     (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
     (unless app (return nil))
     (set version ((REQUEST bindings) version:))
     (set versions (app versions:))
     (set versions (versions select:
                             (do (v) (ne (v version:) version))))
     (set update (dict $set:(dict versions:versions)))
     (mongo updateObject:update
            inCollection:(+ SITE ".apps")
           withCondition:(dict _id:(oid appid))
       insertIfNecessary:NO
   updateMultipleEntries:NO)
     (mongo removeFile:version
          inCollection:"appfiles"
            inDatabase:SITE)
     (RESPONSE redirectResponseToLocation:(+ "/control/apps/manage/" appid)))

(get "/control/apps/manage/deploy/appid:/version:"
     (require-user)
     (set appid ((REQUEST bindings) appid:))
     (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
     (unless app (return nil))
     (set version ((REQUEST bindings) version:))
     (deploy-version app version)
     (RESPONSE redirectResponseToLocation:(+ "/control/apps/manage/" appid)))

(post "/control/apps/upload/appid:"
      (require-user)
      (set appid ((REQUEST bindings) appid:))
      (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
      (unless app (return nil))
      (puts "uploading")
      (set d ((REQUEST body) multipartDictionary))
      (puts (d description))
      (if (and (set appfile (d appfile:))
               (set appfile-data (appfile data:))
               (appfile-data length)
               (set appfile-name (appfile filename:)))
          (then ;; save appfile
                (puts "saving")
                (add-version app appfile-name appfile-data)))
      (RESPONSE redirectResponseToLocation:(+ "/control/apps/manage/" appid)))

;; this macro wraps api handlers and generates formatted responses from the results.
(macro auth (*body) ;; the body should return a (dict)
       `(progn (RESPONSE setValue:"application/xml" forHTTPHeader:"Content-Type")
               (set authorization ((REQUEST headers) Authorization:))
               (set parts (authorization componentsSeparatedByString:" "))
               (case (parts 0)
                     ("Basic" (set credentials (NSString stringWithData:(NSData dataWithBase64EncodedString:(parts 1))
                                                               encoding:NSUTF8StringEncoding))
                              (set parts (credentials componentsSeparatedByString:":"))
                              (set username (parts 0))
                              (set password (parts 1))
                              (mongo-connect)
                              (set account (mongo findOne:(dict username:username
                                                                password:(password md5HashWithSalt:PASSWORD_SALT))
                                             inCollection:(+ SITE ".users"))))
                     ("Bearer" (set secret (parts 1))
                               (mongo-connect)
                               (set account (mongo findOne:(dict secret:secret)
                                              inCollection:(+ SITE ".users"))))
                     (else (set account (get-user SITE))))
               (if account
                   (then ((progn ,@*body) XMLPropertyListRepresentation))
                   (else (RESPONSE setStatus:401)
                         ((dict message:"Unauthorized") XMLPropertyListRepresentation)))))

(macro noauth (*body) ;; the body should return a (dict)
       `(progn (RESPONSE setValue:"application/xml" forHTTPHeader:"Content-Type")
               ((progn ,@*body) XMLPropertyListRepresentation)))

;;=== Me ===

(get "/control/api/account"
     (auth (account removeObjectForKey:"password")
           (account removeObjectForKey:"_id")
           (dict message:"OK" account:account)))

;;=== Administrators ===

(post "/control/api/admin"
      (noauth (set admin ((REQUEST body) propertyListValue))
              (mongo-connect)
              (if (mongo countWithCondition:(dict) inCollection:"users" inDatabase:SITE)
                  (then (dict message:"Admin already exists"))
                  (else (mongo insertObject:(dict username:(admin username:)
                                                  password:((admin password:) md5HashWithSalt:PASSWORD_SALT)
                                                    secret:((RadUUID new) stringValue)
                                                  verified:YES
                                                     admin:YES)
                             intoCollection:(+ SITE ".users"))
                        (dict message:"ok")))))

(post "/control/api/appname:"
      (require-authorization)
      (set app (mongo findOne:(dict name:appname) inCollection:(+ SITE ".apps")))
      (unless app (return "error: app #{appname} not found"))
      (puts "uploading")
      (if (and (set appfile-data (REQUEST body))
               (appfile-data length)
               (set appfile-name (+ (app name:) ".zip")))
          (then ;; save appfile
                (puts "saving")
                (set version (add-version app appfile-name appfile-data))
                (version version:))
          (else "error: invalid app data")))

(post "/control/api/appname:/deploy/version:"
      (require-authorization)
      (set app (mongo findOne:(dict name:appname) inCollection:(+ SITE ".apps")))
      (unless app (return "can't find app"))
      (set version ((REQUEST bindings) version:))
      (if (deploy-version app version)
          (then "deployed")
          (else "error: unable to deploy app")))

(get "/control/apps/edit/appid:"
     (require-user)
     (set appid ((REQUEST bindings) appid:))
     (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
     (unless app (return nil))
     (htmlpage (+ "Editing " (app name:))
               (&div (navbar "Edit")
                     (&div class:"row"
                           (&div class:"large-12 columns"
                                 (&h1 "Editing " (app name:))
                                 (&form action:(+ "/control/apps/edit/" appid)
                                            id:"edit" method:"post"
                                        (&dl (&dt (&label for:"app_name" "App name"))
                                             (&dd (&input id:"app_name" name:"name" size:"40" type:"text" value:(app name:)))
                                             (&dt (&label for:"app_path" "App path"))
                                             (&dd (&input id:"app_path" name:"path" size:"40" type:"text" value:(app path:)))
                                             (&dt (&label for:"app_domains" "App domains"))
                                             (&dd (&input id:"app_domains" name:"domains" size:"40" type:"text" value:(app domains:)))
                                             (&dt (&label for:"app_workers" "Number of workers"))
                                             (&dd (&select id:"app_workers" name:"workers"
                                                           ((array 1 2 3 4 5 6 7 8 9 10) map:
                                                            (do (i) (&option value:i i selected:(eq i (app workers:)))))))
                                             (&dt (&label for:"app_description" "Description"))
                                             (&dd (&textarea  id:"app_description" name:"description"
                                                            rows:"5" cols:"60" (app description:))))
                                        (&input name:"save" type:"submit" value:"Save")
                                        " or "
                                        (&a href:"/control" "Cancel")))))))

(post "/control/apps/edit/appid:"
      (require-user)
      (set appid ((REQUEST bindings) appid:))
      (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
      (unless app (return nil))
      (set post (REQUEST post))
      (set update (dict name:(post name:)
                        path:(post path:)
                     domains:(post domains:)
                 description:(post description:)
                     workers:((post workers:) intValue)))
      (mongo updateObject:(dict $set:update)
             inCollection:(+ SITE ".apps")
            withCondition:(dict _id:(oid appid))
        insertIfNecessary:NO
    updateMultipleEntries:NO)
      (RESPONSE redirectResponseToLocation:(+ "/control/apps/manage/" appid)))

(get "/control/apps/delete/appid:"
     (require-user)
     (set appid ((REQUEST bindings) appid:))
     (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
     (unless app (return nil))
     (htmlpage "delete this app?"
               (&div (navbar "delete this app?")
                     (&div class:"row"
                           (&div class:"large-12 columns"
                                 (&h1 "Do you really want to delete this app?")
                                 (&table (&tr (&td "name") (&td (app name:)))
                                         (&tr (&td "domains" (&td (app domains:))))
                                         (&tr (&td "description" (&td (app description:)))))
                                 (&h2 "WARNING: there is no undo.")
                                 (&form action:(+ "/control/apps/delete/" appid)
                                        method:"POST"
                                        (&input type:"submit" name:"submit" value:"OK")
                                        "&nbsp;"
                                        (&input type:"submit" name:"submit" value:"Cancel")))))))

(post "/control/apps/delete/appid:"
      (require-user)
      (set appid ((REQUEST bindings) appid:))
      (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
      (unless app (return nil))
      (set post (REQUEST post))
      (puts (post description))
      (if (eq (post submit:) "OK")
          (then (mongo removeWithCondition:(dict _id:(oid appid)) fromCollection:(+ SITE ".apps"))
                ;; TODO stop and remove the app workers
                ((app versions:) each:
                 (do (version)
                     (mongo removeFile:(version version:)
                          inCollection:"appfiles"
                            inDatabase:SITE)))
                (htmlpage "item deleted"
                          (&div (navbar "item deleted")
                                (&div class:"row"
                                      (&div class:"large-12 columns"
                                            (&h2 "It's gone.")))))))
      (else (RESPONSE redirectResponseToLocation:(+ "/control/apps/manage/" appid))))

(def upstart-filename (worker)
     (+ "/etc/init/agentio-worker-" (worker port:) ".conf"))

(def log-filename (worker)
     (+ "/var/log/upstart/agentio-worker-" (worker port:) ".log"))

(get "/control/apps/manage/appid:/container:"
     (require-user)
     (set appid ((REQUEST bindings) appid:))
     (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
     (unless app (return nil))
     (set container ((REQUEST bindings) container:))
     (set worker nil)
     (if (app deployment:)
         (then (set worker (((app deployment:) workers:) find:(do (w) (eq (w container:) container))))
               (htmlpage "worker detail"
                         (&div (navbar "worker detail")
                               (&div class:"row"
                                     (&div class:"large-12 columns"
                                           (&h1 "Worker for " (&a href:(+ "/control/apps/manage/" appid) (app name:)))
                                           (&table (&tr (&td "container") (&td (worker container:)))
                                                   (&tr (&td "host") (&td (worker host:)))
                                                   (&tr (&td "port") (&td (worker port:))))
                                           (&table (if (eq (uname) "Linux")
                                                       (then (+ (&tr (&td "upstart configuration")
                                                                     (&td (&a href:(+ "/control/apps/manage/" appid "/" container "/upstart.conf") 
(upstart-filename worker))))
                                                                (&tr (&td "logfile")
                                                                     (&td (&a href:(+ "/control/apps/manage/" appid "/" container "/logfile") 
(log-filename worker))))))
                                                       (else (+ (&tr (&td (&a href:(+ "/control/apps/manage/" appid "/" container "/launchd.plist") "launchd.plist")))
                                                                (&tr (&td (&a href:(+ "/control/apps/manage/" appid "/" container "/sandbox.sb") "sandbox.sb")))
                                                                (&tr (&td (&a href:(+ "/control/apps/manage/" appid "/" container "/stdout.log") "stdout.log")))
                                                                (&tr (&td (&a href:(+ "/control/apps/manage/" appid "/" container "/stderr.log") "stderr.log"))))))))))))
         (else "not found")))

(get "/control/apps/manage/appid:/container:/file:"
     (require-user)
     (set appid ((REQUEST bindings) appid:))
     (set app (mongo findOne:(dict _id:(oid appid) owner_id:(account _id:)) inCollection:(+ SITE ".apps")))
     (unless app (return nil))
     (set container ((REQUEST bindings) container:))
     (set worker nil)
     (set text nil)
     (if (app deployment:)
         (then (set worker (((app deployment:) workers:) find:(do (w) (eq (w container:) container))))
               (set file ((REQUEST bindings) file:))
               (set text
                    (case file
                          ("upstart.conf" (NSString stringWithContentsOfFile:(+ "/etc/init/agentio-worker-" (worker port:) ".conf")))
                          ("sandbox.sb" (NSString stringWithContentsOfFile:(+ CONTROL-PATH "/workers/" container "/sandbox.sb")))
                          ("launchd.plist" (NSString stringWithContentsOfFile:(+ "/Library/LaunchDaemons/net.agentio.app." (worker port:) ".plist")))
                          ("logfile" (NSString stringWithContentsOfFile:(+ "/var/log/upstart/agentio-worker-" (worker port:) ".log")))
                          ("stdout.log" (NSString stringWithContentsOfFile:(+ CONTROL-PATH "/workers/" container "/var/stdout.log")))
                          ("stderr.log" (NSString stringWithContentsOfFile:(+ CONTROL-PATH "/workers/" container "/var/stderr.log")))
                          (t nil))))
         (else (set text nil)))
     (if text
         (then (REQUEST setContentType:"text/html")
               (htmlpage file
                         (&div (navbar file)
                               (&div class:"row"
                                     (&div class:"large-12 columns"
                                           (&h1 file)
                                           (&pre class:"code" (html-escape text)))))))
         (else nil)))

(get "/control/about"
     (require-user)
     (htmlpage "About AgentBox"
               (&div (navbar "About")
                     (&div class:"row"
                           (&div class:"large-12 columns"
                                 (&h1 "About AgentBox")
                                 (&p "Build, test, and deploy cloud-based apps with Xcode and Objective-C.")
                                 (&ul (&li "App servers run Mac OS X.")
                                      (&li "Apps can be built with Xcode and are written in Objective-C and related scripting languages.")
                                      (&li "Apps are managed with launchd.")
                                      (&li "Apps are run in a sandbox that controls their access to local files and network resources.")
                                      (&li "Apps keep all persistent information outside the app itself."
                                           (&ul (&li "Structured data is kept in MongoDB collections accessed over web services.")
                                                (&li "Files are kept in a managed file store.")))
                                      (&li "Apps can be run as multiple concurrent instances to increase capacity.")
                                      (&li "Apps are connected using a load balancer that routes requests to apps."))
                                 (&p (&a href:"http://radtastical.com" "by Radtastical Inc."))
                                 (&p "Copyright ©2012, All rights reserved.")
                                 (&p (&a href:"mailto:tim@radtastical.com" "Contact us.")))))))

(get "/control/browse"
     (require-user)
     (set collections ((mongo collectionNamesInDatabase:SITE) sort))
     (htmlpage "Browse Data Store"
               (&div (navbar "browse data store")
                     (&div class:"row"
                           (&div class:"large-12 columns"
                                 (&h1 "Collections")
                                 (&table class:"table table-striped"
                                         (collections mapWithIndex:
                                                      (do (collection index)
                                                          (&tr (&td (+ index 1) ". "
                                                                    (&a href:(+ "/control/browse/" collection) collection)))))))))))

(get "/control/browse/collection:"
     (require-user)
     (set collection ((REQUEST bindings) collection:))
     (set documents (mongo findArray:nil inCollection:(+ SITE "." collection)))
     (htmlpage (+ "browsing " collection)
               (&div (navbar "browsing collection")
                     (&div class:"row"
                           (&div class:"large-12 columns"
                                 (&h1 collection)
                                 (documents map:
                                            (do (document)
                                                (&div (&h4 (document _id:))
                                                      (&pre (document description))))))))))

(get "/control/nginx.conf"
     (require-user)
     (REQUEST setContentType:"text/html")
     (htmlpage "AgentBox nginx.conf"
               (&div (navbar "nginx.conf")
                     (&div class:"row"
                           (&div class:"large-12 columns"
                                 (&h1 "AgentBox nginx.conf " (&a href:"/control/restart-nginx" "(restart)"))
                                 (&pre class:"code" (NSString stringWithContentsOfFile:(nginx-conf-path))))))))

(get "/control/restart-nginx"
     (require-user)
     (restart-nginx)
     (RESPONSE redirectResponseToLocation:"/control"))

;;; site management

(get "/control/restart"
     (require-user)
     (RESPONSE setExit:1)
     (RESPONSE redirectResponseToLocation:"/restart.html"))

(function table-for-dictionary (dictionary)
          (set keys ((dictionary allKeys) sort))
          (&table style:"width:100%"
                  (keys map:
                        (do (key)
                            (&tr (&td key) (&td (&pre (dictionary objectForKey:key))))))))

(get "/control/environment"
     (set environment ((NSProcessInfo processInfo) environment))
     (&html (&head (&link href:"/foundation/css/normalize.css" rel:"stylesheet")
                   (&link href:"/foundation/css/foundation.min.css" rel:"stylesheet"))
            (&body
                  (&div class:"row"
                        (&div class:"large-12 columns"
                              (&h1 "Agent I/O App")
                              (&p "Request path: " (REQUEST path))
                              (&h2 "Request headers")
                              (table-for-dictionary (REQUEST headers))
                              (&h2 "Environment")
                              (table-for-dictionary environment))))))


