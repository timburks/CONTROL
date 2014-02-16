;; mongodb administration
;; > use admin
;; > db.addUser("root", "radtastical")
;; > use agentbox
;; > db.addUser("agentbox", "xme")
;;
;; run mongod with --auth option

(set mongo (RadMongoDB new))

;; below see the MongoHQ configuration
;; username: timburks password: mongohqtim
;(set HOSTINFO (dict host:"184.73.224.5" port:27067))

;; MongoLab
;; username: admin password: rad123 account: tim@radtastical.com
;(set HOSTINFO (dict host:"184.106.200.68" port:27007))

;; localhost
;(set HOSTINFO (dict))
;(set HOSTINFO (dict host:"127.0.0.1" port:20101))

(while (mongo connect)
       (NSLog "deus: waiting for database")
       (sleep 1))

;(mongo connectWithOptions:HOSTINFO)
;(mongo authenticateUser:"agentbox" withPassword:"xme" forDatabase:SITE)

(function oid (string)
     ((RadBSONObjectID alloc) initWithString:string))

(function set-property (key value)
     (mongo updateObject:(dict _id:key value:value)
            inCollection:(+ SITE ".properties")
            withCondition:(dict _id:key)
            insertIfNecessary:YES
            updateMultipleEntries:NO))

(function get-property (key)
     (set result (mongo findOne:(dict _id:key) inCollection:(+ SITE ".properties")))
     (result value:))

(function set-username-password (username password)
     (mongo updateObject:(dict username:username
                               password:(password md5HashWithSalt:PASSWORD_SALT))
            inCollection:(+ SITE ".users")
            withCondition:(dict username:"admin")
            insertIfNecessary:YES
            updateMultipleEntries:NO))


