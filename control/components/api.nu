
(macro ug ()
       ((dict message:"unimplemented") JSONValue))

(function uuidgen () ((RadUUID new) stringValue))

;;; usergrid-compatible API
(macro fetch-token ()
       `(and (set auth ((REQUEST headers) Authorization:))
             (set parts (auth componentsSeparatedByString:" "))
             (eq (parts count) 2)
             (eq (parts 0 "Bearer"))
             (progn (set mongo (RadMongoDB new))
                    (mongo connect)
                    (set token (mongo findOne:(dict _id:(parts 1)) inCollection:(+ SITE ".access_tokens"))))
             token))

;; http://apigee.com/docs/usergrid/content/app-services-resources
(get "/management/version" "deus api version 0.1\n")

;; usergrid management api
(get "/management/token"
     (set QUERY ((REQUEST query) urlQueryDictionary))
     (puts (QUERY description))
     (set username (QUERY username:))
     (set password (QUERY password:))
     (set mongo (RadMongoDB new))
     (mongo connect)
     (set account (mongo findOne:(dict username:username
                                       password:(password md5HashWithSalt:PASSWORD_SALT))
                    inCollection:(+ SITE ".users")))
     (if account
         (then (account removeObjectForKey:"password")
               (account removeObjectForKey:"_id")
               (set token (dict _id:((RadUUID new) stringValue) account:account))
               (mongo insertObject:token intoCollection:(+ SITE ".access_tokens"))
               ((dict access_token:(token _id:)
                           account:account
                        expires_in:(* 7 24 3600)) JSONRepresentation))
         (else ((dict message:"access denied") JSONRepresentation))))

(get    "/management/organizationid:/applicationid:/token" (ug))
(post   "/management/users"
        ((dict message:"unimplemented") JSONRepresentation))

(put    "/management/users/userid:" (ug))
(get    "/management/users/userid:" (ug))
(put    "/management/users/userid:/password" (ug))
(get    "/management/users/resetpw" (ug))
(post   "/management/users/resetpw" (ug))
(get    "/management/users/userid:/activate" (ug))
(get    "/management/users/userid:/reactivate" (ug))
(get    "/management/users/userid:/feed" (ug))
(get    "/management/authorize" (ug))

;; create an organization
(post "/management/organizations"
      (set startTime ((NSDate date) timeIntervalSince1970))
      ;(unless (set token (fetch-token)) (return ((dict message:"unauthorized") JSONRepresentation)))
      (set POST ((REQUEST body) urlQueryDictionary))
      (set organization-name (POST organization:))
      (set mongo (RadMongoDB new))
      (mongo connect)
      (if (set organization (mongo findOne:(dict organization:organization-name) inCollection:(+ SITE ".organizations")))
          (then ((dict message:"organization already exists") JSONRepresentation))
          (else ;; extract the organization's owner from the POST
                (set owner (dict username:(POST username:)
                                    email:(POST email:)
                                     name:(POST name:)
                                 password:((POST password:) md5HashWithSalt:PASSWORD_SALT)
                                     uuid:(uuidgen)
                            applicationID:(uuidgen)
                                activated:YES
                                 disabled:NO
                               properties:(dict)
                                adminUser:YES))
                (mongo insertObject:owner intoCollection:(+ SITE ".users"))
                
                (set organization (dict name:(POST organization:)
                                        uuid:(uuidgen)))
                (mongo insertObject:organization intoCollection:(+ SITE ".organizations"))
                
                (set ownership (dict admin_uuid:(owner uuid:)
                              organization_uuid:(organization uuid:)))
                (mongo insertObject:ownership intoCollection:(+ SITE ".administration"))
                
                (set result (dict action:"new organization"
                                  status:"ok"
                                    data:(dict owner:owner
                                        organization:organization)
                               timestamp:((set endTime ((NSDate date) timeIntervalSince1970)) intValue)
                                duration:((* 1000 (- endTime startTime)) intValue)))
                (result JSONRepresentation))))

(get "/management/organizations/organizationid:"
     (set mongo (RadMongoDB new))
     (mongo connect)
     (if (set organization (mongo findOne:(dict organization:organizationid) inCollection:(+ SITE ".organizations")))
         (then ((dict message:"organization found" results:organization) JSONRepresentation))
         (else ((dict message:"organization not found") JSONRepresentation))))


(get    "/management/organizations/organizationid:/activate" (ug))
(get    "/management/organizations/organizationid:/reactivate" (ug))
(post   "/management/organizations/organizationid:/credentials" (ug))
(get    "/management/organizations/organizationid:/credentials" (ug))
(get    "/management/organizations/organizationid:/feed" (ug))

;; create an application
(post "/management/organizations/organizationid:/applications"
      (set token (fetch-token))
      ((dict message:"Create an application") JSONRepresentation))




(delete "/management/organizations/organizationid:/applications/applicationid:" (ug))
(post   "/management/organizations/organizationid:/applications/applicationid:/credentials" (ug))
(get    "/management/organizations/organizationid:/applications/applicationid:/credentials" (ug))
(get    "/management/organizations/organizationid:/applications" (ug))
(put    "/management/organizations/organizationid:/users/userid:" (ug))
(get    "/management/organizations/organizationid:/users" (ug))
(delete "/management/organizations/organizationid:/users/userid:" (ug))

;; usergrid access api
(post   "/organizationid:/applicationid:/users/userid:/activities" (ug))
(post   "/organizationid:/applicationid:/groups/groupid:/activities" (ug))

(function dbname (organization application)
          (+ organization ":" application))

(function collectionname (database collection)
          (+ database "." collection))

(post   "/organizationid:/applicationid:/collectionid:"
        (set databaseid (dbname organizationid applicationid))
        (set mongo (RadMongoDB new))
        (mongo connect)
        (mongo insertObject:((NSString stringWithData:(REQUEST body) encoding:NSUTF8StringEncoding) JSONValue)
             intoCollection:(collectionname databaseid collectionid))
        ((dict message:"ok") JSONRepresentation))


(get    "/organizationid:/applicationid:/collectionid:/entityid:" (ug))
(put    "/organizationid:/applicationid:/collectionid:/entityid:" (ug))
(delete "/organizationid:/applicationid:/collectionid:/entityid:" (ug))


(get "/organizationid:/applicationid:/collectionid:"
     (set databaseid (dbname organizationid applicationid))
     (set mongo (RadMongoDB new))
     (mongo connect)
     (set entities (mongo findArray:nil inCollection:(collectionname databaseid collectionid)))
     (entities JSONRepresentation))

(put    "/organizationid:/applicationid:/collectionid:" (ug))


(get    "/organizationid:/applicationid:/collectionid:/entityid:/relationship" (ug))
(post   "/organizationid:/applicationid:/collectionid:/entityid:/relationship/entityid2:" (ug))
(post   "/organizationid:/applicationid:/collectionid:/entityid:/relationship/collectionid2:/entityid2:" (ug))
(delete "/organizationid:/applicationid:/collectionid:/entityid:/relationship/entityid2:" (ug))
(delete "/organizationid:/applicationid:/collectionid:/entityid:/relationship/collectionid2:/entityid2:" (ug))

(post   "/organizationid:/applicationid:/events" (ug))
(post   "/organizationid:/applicationid:/groups" (ug))
(post   "/organizationid:/applicationid:/groups/groupid:/users/userid:" (ug))
(get    "/organizationid:/applicationid:/groups/groupid:" (ug))
(put    "/organizationid:/applicationid:/groups/groupid:" (ug))
(delete "/organizationid:/applicationid:/groups/groupid:/users/userid:" (ug))
(get    "/organizationid:/applicationid:/groups/groupid:/feed" (ug))

(post   "/organizationid:/applicationid:/roles" (ug))
(get    "/organizationid:/applicationid:/roles" (ug))
(delete "/organizationid:/applicationid:/roles/roleid:" (ug))
(get    "/organizationid:/applicationid:/roles/roleid:" (ug))
(post   "/organizationid:/applicationid:/roles/roleid:" (ug))
(delete "/organizationid:/applicationid:/roles/roleid:/permissions" (ug))

(post   "/organizationid:/applicationid:/roles/roleid:/users/userid:" (ug))
(post   "/organizationid:/applicationid:/users/userid:/roles/roleid:" (ug))
(get    "/organizationid:/applicationid:/roles/roleid:/users" (ug))
(delete "/organizationid:/applicationid:/roles/roleid:/users/userid:" (ug))

(post   "/organizationid:/applicationid:/users" (ug))
(post   "/organizationid:/applicationid:/users/userid:/password" (ug))
(get    "/organizationid:/applicationid:/users/userid:" (ug))
(put    "/organizationid:/applicationid:/users/userid:" (ug))
(delete "/organizationid:/applicationid:/users/userid:" (ug))
(get    "/organizationid:/applicationid:/users" (ug))

(post   "/organizationid:/applicationid:/groups/groupid:/users/userid:" (ug))
(post   "/organizationid:/applicationid:/collectionid:/entityid:/relationship:/entityid:" (ug))
(post   "/organizationid:/applicationid:/collectionid:/entityid:/relationship:/collectionid2:/entityid2:" )
(delete "/organizationid:/applicationid:/collectionid:/entityid:/relationship:/entityid2:" (ug))
(delete "/organizationid:/applicationid:/collectionid:/entityid:/relationship:/collectionid2:/entityid2:" (ug))
(get    "/organizationid:/applicationid:/users/userid:/relationship:" (ug))
(get    "/organizationid:/applicationid:/users/userid:/feed" (ug))



