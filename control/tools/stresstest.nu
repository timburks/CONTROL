(load "agentbox")

(unless (set user (create-user "test" "test"))
        (set user (lookup-user "test" "test")))

(puts (user description))

(mongo removeWithCondition:(dict owner_id:(user _id:)) fromCollection:(+ SITE ".apps"))

(set colors (array "Red" "Blue" "Green"))

(1 times:
   (do (i)
       (cond ((< i 10)	 (set appname (+ "Sample app 00" i)))
             ((< i 100) (set appname (+ "Sample app 0" i)))
             (t         (set appname (+ "Sample app " i))))
       (add-app (dict name:appname
                    domain:(+ "app" i ".agentbox.net")
               description:"sample app"
                  owner_id:(user _id:)))
       (set app (mongo findOne:(dict name:appname owner_id:(user _id:)) inCollection:(+ SITE ".apps")))
       (set color (colors objectAtIndex:(% i (colors count))))
       (set container (add-version app (+ color ".zip") (NSData dataWithContentsOfFile:(+ "../../apps/" color ".zip"))))
       (set app (mongo findOne:(dict name:appname owner_id:(user _id:)) inCollection:(+ SITE ".apps")))
       (deploy-version app container)))

(redeploy)
