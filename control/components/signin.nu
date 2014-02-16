
;; ======= USER SIGNIN SYSTEM ========

(set signin-form
     '(htmlpage "Sign In"
                (navbar "Sign In")
                (&div class:"row"
                      (&div class:"large-3 columns" (&p))
                      (&div class:"large-9 columns"
                            (&h2 message)
                            (&form id:"email-form" method:"post" action:"/control/signin"
                                   (&table (&tr (&td (&label for:"username" "Username "
                                                           style:"margin-right:2em"))
                                                (&td (&input id:"username"
                                                           type:"text"
                                                          width:20
                                                           name:"username"
                                                          title:"username"
                                                          value:username)))
                                           (&tr (&td (&label for:"password" "Password "
                                                           style:"margin-right:2em"))
                                                (&td (&input id:"password"
                                                           type:"password"
                                                          width:20
                                                           name:"password"
                                                          title:"password"
                                                          value:password)))
                                           (&tr (&td)
                                                (&td (&button type:"submit" "&nbsp;Sign in&nbsp;")))))))))

(set adduser-form
     '(htmlpage "Add User"
                (navbar "Add User")
                (&div class:"row"
                      (&div class:"large-3 columns" (&p))
                      (&div class:"large-9 columns"
                            (&div class:"hero-unit"
                                  (&h2 message)
                                  (&form id:"email-form" method:"post" action:"/control/adduser"
                                         (&table (&tr (&td (&label for:"username" "Username "
                                                                 style:"margin-right:2em"))
                                                      (&td (&input id:"username"
                                                                 type:"text"
                                                                 name:"username"
                                                                title:"username"
                                                                width:20 )))
                                                 (&tr (&td (&label for:"password" "Password "
                                                                 style:"margin-right:2em"))
                                                      (&td (&input id:"password"
                                                                 type:"password"
                                                                 name:"password"
                                                                title:"password"
                                                                width:20)))
                                                 (&tr (&td (&label for:"password2" "Password (again) "
                                                                 style:"margin-right:2em"))
                                                      (&td (&input id:"password2"
                                                                 type:"password"
                                                                 name:"password2"
                                                                title:"password"
                                                                width:20)))
                                                 (&tr (&td)
                                                      (&td (&button type:"submit" "&nbsp;Add user&nbsp;"))))))))))

(function create-cookie (name)
          (dict name:name
               value:((RadUUID new) stringValue)
          expiration:(NSDate dateWithTimeIntervalSinceNow:(* 24 3600 10))))

(function display-cookie (cookie)
          (+ "" (cookie name:) "=" (cookie value:) "; path=\/control\/; expires=" ((cookie expiration:) rfc1123) ";"))

(macro get-user (name)
       `(cond ((eq nil (set cookie ((REQUEST cookies) ,name))) nil)
              ((eq nil (set session (mongo findOne:(dict cookie:cookie) inCollection:(+ SITE ".sessions")))) nil)
              (else (mongo findOne:(dict _id:(session account_id:)) inCollection:(+ SITE ".users")))))

(macro require-account ()
       (unless (set account (get-user SITE)) (return nil)))

(get "/control/signin"
     (REQUEST setContentType:"text/html")
     (set username "")
     (set password "")
     (set message "Please sign in.")
     (eval signin-form))

(post "/control/signin"
      (REQUEST setContentType:"text/html")
      (set ip-address ((REQUEST headers) "X-Forwarded-For"))
      (set username ((REQUEST post) "username"))
      (set password ((REQUEST post) "password"))
      (puts ((REQUEST post) description))
      (cond ((or (not username) (not password))
             (set message "Missing username or password. Try that again.")
             (eval signin-form))            
            ((set account (mongo findOne:(dict username:username
                                               password:(password md5HashWithSalt:PASSWORD_SALT))
                            inCollection:(+ SITE ".users")))             
             (set session-cookie (create-cookie SITE))
(puts "setting cookie: #{(display-cookie session-cookie)}")
             (RESPONSE setValue:(display-cookie session-cookie) forHTTPHeader:"Set-Cookie")             
             (set session (dict account_id:(account _id:) cookie:(session-cookie value:)))
(puts "MATCH")
             (mongo updateObject:session
                    inCollection:(+ SITE ".sessions")
                   withCondition:(dict account_id:(account _id:))
               insertIfNecessary:YES
           updateMultipleEntries:NO)
             (RESPONSE redirectResponseToLocation:"/control")
)
            (else (set message "Password mismatch. Try that again.")
                  (eval signin-form))))

(get "/control/signout"
     (if (set cookie ((REQUEST cookies) SITE))
         (mongo removeWithCondition:(dict cookie:cookie) fromCollection:(+ SITE ".sessions")))
     (RESPONSE redirectResponseToLocation:"/control"))

(get "/control/whoami"
     (set account (get-user SITE))
     (REQUEST setContentType:"text/plain")
     (account description))

(get "/control/adduser"
     (set account (get-user SITE))
     (unless account (return nil))
     (set message "Add a user to AgentBox.")
     (eval adduser-form))

(post "/control/adduser"
      (set account (get-user SITE))
      (unless account (return nil))
      (set ip-address ((REQUEST headers) X-Forwarded-For:))
      (set username ((REQUEST post) username:))
      (set password ((REQUEST post) password:))
      (set confirmation ((REQUEST post) password2:))
      
      (cond ((or (not username) (eq (username length) 0))
             (set message "Please specify a username.")
             (eval adduser-form))
            ((or (not password) (< (password length) 4))
             (set message "Passwords must be at least 4 characters.")
             (eval adduser-form))
            ((!= password confirmation)
             (set message "Password and password confirmation entries must match.")
             (eval adduser-form))
            (else ;; create the account
                  (set account (create-user username password))
                  (puts "account created")
                  (set session-cookie (create-cookie SITE))
                  (RESPONSE setValue:(display-cookie session-cookie) forHTTPHeader:"Set-Cookie")
                  (puts "cookie created")
                  (set session (dict account_id:(account _id:) cookie:(session-cookie value:)))
                  (puts "session created")
                  (mongo updateObject:session
                         inCollection:(+ SITE ".sessions")
                        withCondition:(dict account_id:(account _id:))
                    insertIfNecessary:YES
                updateMultipleEntries:NO)
                  (puts "session saved")
                  (RESPONSE redirectResponseToLocation:"/control"))))
