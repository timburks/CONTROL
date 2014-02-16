;; helpers

((set date-formatter
      ((NSDateFormatter alloc) init))
 setDateFormat:"EEEE MMMM d, yyyy")

((set rss-date-formatter
      ((NSDateFormatter alloc) init))
 setDateFormat:"EEE, d MMM yyyy hh:mm:ss ZZZ")

(macro mongo-connect ()
       `(progn (unless (defined mongo)
                       (set mongo (RadMongoDB new))
                       (mongo connect))))

;; basic site structure

(macro htmlpage (title *body)
       `(progn (REQUEST setContentType:"text/html")
               (unless (defined account) (set account (get-user SITE)))
               (&html (&head (&meta charset:"utf-8")
                             (&title ,title)
                             (&meta name:"viewport" content:"width=device-width, initial-scale=1.0")
                             (&meta name:"description" content:"CONTROL")
                             (&meta name:"author" content:"Tim Burks")
                             (&script src:"/foundation/js/custom.modernizr.js")
                             (&link href:"/foundation/css/normalize.css" rel:"stylesheet")
                             (&link href:"/foundation/css/foundation.min.css" rel:"stylesheet"))
                      (&body ,@*body
                             (&script src:"/foundation/js/jquery.js")
                             (&script src:"/foundation/js/foundation.min.js")
                             (&script "$(document).foundation();")))))

(macro navbar (name)
       `(progn
              (if (and (defined account) account)
                  (set apps (mongo findArray:(dict $query:(dict owner_id:(account _id:))
                                                 $orderby:(dict name:1))
                                inCollection:(+ SITE ".apps"))))
              (&div class:""
                    (&nav class:"top-bar"
                          (&ul class:"title-area"
                               (&li class:"name" (&h1 (&a href:"/control" "CONTROL")))
                               (&li class:"toggle-topbar menu-icon"
                                    (&a href:"#" (&span "Menu"))))
                          (&section class:"top-bar-section"
                                    (if (defined apps)
                                        (&ul class:"left"
                                             (&li class:"divider")
                                             (&li (&a href:"/control/nginx.conf" "nginx"))
                                             (&li class:"divider")
                                             (&li (&a href:"/control/browse" "mongodb"))
                                             (&li class:"divider")
                                             (&li class:"has-dropdown" (&a href:"#" "apps")
                                                  (&ul class:"dropdown"
                                                       (apps map:
                                                             (do (app)
                                                                 (&li (&a href:(+ "/control/apps/manage/" (app _id:))
                                                                          (app name:)))))
                                                       (&li class:"divider")
                                                       (&li (&a href:"/control/apps/add" "Add an app"))))))
                                    (&ul class:"right"
                                         (if (and (defined account) account)
                                             (then (&& (&li (&a href:"#"
                                                                "signed in as " (account username:)))
                                                       (&li (&a href:"/control/signout" " sign out"))
                                                       (&li (&a href:"/control/adduser" " add user"))
                                                       (&li (&a href:"/control/restart" " restart"))))
                                             (else (&li href:"/control/signin" "sign in")))))))))

