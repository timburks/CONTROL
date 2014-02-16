(load "usergrid.nu")

(set ORGANIZATION "sampleorg")
(set ORGANIZATION2 "sampleorg2")
(set APPLICATION "sampleapp")
(set USERNAME "admin")
(set PASSWORD "xmachine")

(set ORGANIZATION-USERNAME "sample")
(set ORGANIZATION-PASSWORD "password")
(set ORGANIZATION-EMAIL    "tim@radtastical.com")

(set ORGANIZATION2-USERNAME "sample2")
(set ORGANIZATION2-PASSWORD "password2")
(set ORGANIZATION2-EMAIL    "tim+2@radtastical.com")

(set usergrid (UGConnection new))
(usergrid setServer:"http://api.xmachine.io")
;(usergrid setServer:"http://localhost:8080")
(usergrid setOrganization:ORGANIZATION)
(usergrid setApplication:APPLICATION)

;; making an organization requires a unique new user

(verbose "MAKE ADMIN"         
         (usergrid makeAdmin:(dict username:"master"
                                      email:"email@example.com"
                                       name:"master"
                                   password:"password")))


(verbose "MAKE ORGANIZATION"
         (usergrid makeOrganization:(dict organization:ORGANIZATION
                                              username:ORGANIZATION-USERNAME
                                                 email:ORGANIZATION-EMAIL
                                                  name:ORGANIZATION-USERNAME
                                              password:ORGANIZATION-PASSWORD)))

(verbose "MAKE ORGANIZATION2"
         (usergrid makeOrganization:(dict organization:ORGANIZATION2
                                              username:ORGANIZATION2-USERNAME
                                                 email:ORGANIZATION2-EMAIL
                                                  name:ORGANIZATION2-USERNAME
                                              password:ORGANIZATION2-PASSWORD)))

(verbose "Sign in" (usergrid getAccessTokenForOrganizationWithAdmin:ORGANIZATION-USERNAME password:ORGANIZATION-PASSWORD))

(verbose "GET USER" (usergrid performGet:(+ (usergrid server) "/management/users/" ORGANIZATION-USERNAME)))

(verbose "GET USER" (usergrid performGet:(+ (usergrid server) "/management/users/" ORGANIZATION2-USERNAME)))



(verbose "GET ORGANIZATION"
         (usergrid getOrganization))

(verbose "MAKE APPLICATION"
         (usergrid makeApplication))

(usergrid postEntity:(dict value:1 name:"one")
        toCollection:"numbers")
(usergrid postEntity:(dict value:2 name:"two")
        toCollection:"numbers")
(usergrid postEntity:(dict value:3 name:"three")
        toCollection:"numbers")

(usergrid getEntitiesInCollection:"numbers" limit:10)

(exit)

(verbose "AUTHENTICATE WITH ADMIN PASSWORD"
         (usergrid getAccessTokenForOrganizationWithAdmin:ORGANIZATION-USERNAME password:ORGANIZATION-PASSWORD))
(exit)

(verbose "MAKE APPLICATION"
         (usergrid makeApplication))