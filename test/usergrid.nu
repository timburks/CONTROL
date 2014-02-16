(load "RadKit")

(class NSObject
 (- JSONData is
    (set error (NuReference new))
    (NSJSONSerialization dataWithJSONObject:self options:nil error:error)))

(class NSData
 (- JSONValue is
    (set error (NuReference new))
    ((NSJSONSerialization JSONObjectWithData:self options:nil error:error))))

(class NSURLRequest
 (- curlCommand is
    (set command "curl -s")
    ;; method
    (command appendString:" -X ")
    (command appendString:(self HTTPMethod))
    ;; path
    (command appendString:" \"")
    (command appendString:((self URL) absoluteString))
    (command appendString:"\"")
    ;; body
    (if (set body (self HTTPBody))
        (then (set httpBodyString ((((NSMutableString alloc) initWithData:body encoding:NSUTF8StringEncoding)
                                    stringByReplacingOccurrencesOfString:"\\" withString:"\\\\")
                                   stringByReplacingOccurrencesOfString:"\"" withString:"\\\""))
              (command appendString:" -d \"")
              (command appendString:httpBodyString)
              (command appendString:"\"")))
    ;; headers
    ((self allHTTPHeaderFields) each:
     (do (field value)
         (command appendString:" -H \"")
         (command appendString:field)
         (command appendString:":")
         (command appendString:value)
         (command appendString:"\"")))
    command))

;; Use this to extract the access token from an authentication result
;;  perl -n -e'/"access_token":"(.*?)"/ && print $1'

(class UGConnection is NSObject
 ;; @server
 ;; @organization
 ;; @application
 ;; @token
 ;; @tokenExpiration
 
 ;; Support methods (private)
 
 (- isAuthenticated is
    (and @token
         @tokenExpiration
         (> @tokenExpiration (NSDate date))))
 
 (- performRequest:request is
    (if @token
        (request setValue:"Bearer #{@token}" forHTTPHeaderField:"Authorization"))
    ;; take a round-trip with NSArchiving just to prove that we can
    (set data (NSKeyedArchiver archivedDataWithRootObject:request))
    (set request (NSKeyedUnarchiver unarchiveObjectWithData:data))
    (if NO
        (then (set result (NSURLConnection sendSynchronousRequest:request
                                                returningResponse:(set response (NuReference new))
                                                            error:(set error (NuReference new))))
              (unless result
                      (puts "ERROR: #{((error value) description)}"))
              (set string (NSString stringWithData:result encoding:NSUTF8StringEncoding)))
        (else ;; use curl
              (set command (request curlCommand))
              (puts command)
              (set string (NSString stringWithShellCommand:command))))
    (puts "RESPONSE LENGTH: #{(string length)}")
    (puts "RESPONSE: #{string}")
    (if (string length)
        (then (set value (string JSONValue)))
        (else (set value (dict))))
    ;(puts (value description))
    value)
 
 (- performGet:path is
    (set URL (NSURL URLWithString:path))
    (set request (NSMutableURLRequest requestWithURL:URL))
    (self performRequest:request))
 
 (- performPost:path is
    (set URL (NSURL URLWithString:path))
    (set request (NSMutableURLRequest requestWithURL:URL))
    (request setHTTPMethod:"POST")
    (self performRequest:request))
 
 (- performPost:path
       withData:data is
    (set URL (NSURL URLWithString:path))
    (set request (NSMutableURLRequest requestWithURL:URL))
    (request setHTTPMethod:"POST")
    (request setValue:"application/octet-stream" forHTTPHeaderField:"Content-Type")
    (request setHTTPBody:data)
    (self performRequest:request))
 
 (- performPost:path
 withDictionary:dictionary is
    (set URL (NSURL URLWithString:path))
    (set request (NSMutableURLRequest requestWithURL:URL))
    (request setHTTPMethod:"POST")
    (request setHTTPBody:((dictionary urlQueryString) dataUsingEncoding:NSUTF8StringEncoding))
    (self performRequest:request))
 
 (- performPost:path
       withJSON:entity is
    (set URL (NSURL URLWithString:path))
    (set request (NSMutableURLRequest requestWithURL:URL))
    (request setHTTPMethod:"POST")
    (request setHTTPBody:(entity JSONData))
    (self performRequest:request))
 
 (- performPut:path
      withJSON:entity is
    (set URL (NSURL URLWithString:path))
    (set request (NSMutableURLRequest requestWithURL:URL))
    (request setHTTPMethod:"PUT")
    (request setHTTPBody:(entity JSONData))
    (self performRequest:request))
 
 (- performPut:path
      withData:data is
    (set URL (NSURL URLWithString:path))
    (set request (NSMutableURLRequest requestWithURL:URL))
    (request setHTTPMethod:"PUT")
    ;(request setValue:"application/octet-stream" forHTTPHeaderField:"Content-Type")
    (request setHTTPBody:data)
    (self performRequest:request))
 
 (- performDelete:path is
    (set URL (NSURL URLWithString:path))
    (set request (NSMutableURLRequest requestWithURL:URL))
    (request setHTTPMethod:"DELETE")
    (self performRequest:request))
 
 ;; Usergrid Management API
 
 (- makeAdmin:admin is
    (self performPost:(+ @server
                         "/management/users")
       withDictionary:admin))
 
 (- makeOrganization:organization is
    (self performPost:(+ @server
                         "/management/organizations")
       withDictionary:organization))
 
 (- getOrganization is
    (self performGet:(+ @server
                        "/management/organizations/" @organization)))
 
 (- getOrganizationCredentials is
    (self performGet:(+ @server
                        "/management/organizations/" @organization
                        "/credentials")))
 
 (- generateOrganizationCredentials is
    (self performPost:(+ @server
                         "/management/organizations/" @organization
                         "/credentials")))
 
 (- getApplicationCredentials is
    (self performGet:(+ @server
                        "/management/organizations/" @organization
                        "/applications/" @application
                        "/credentials")))
 
 (- generateApplicationCredentials is
    (self performPost:(+ @server
                         "/management/organizations/" @organization
                         "/applications/" @application
                         "/credentials")))
 
 (- getApplications is
    (self performGet:(+ @server
                        "/management/organizations/" @organization "/applications")))
 
 (- makeApplication is
    (self performPost:(+ @server
                         "/management/organizations/" @organization "/applications")
             withJSON:(dict name:@application)))
 
 (- deleteApplication is
    (self performDelete:(+ @server
                           "/management/organizations/" @organization
                           "/applications/" @application)))
 
 (- getAccessTokenForOrganizationWithAdmin:username
                                  password:password is
    (set query (dict grant_type:"password"
                       username:username
                       password:password))
    (set path (+ @server
                 "/management/token?" (query urlQueryString)))
    (if (set results (self performGet:path))
        (if (set token (results access_token:))
            (then (set expires (results expires_in:))
                  (set @tokenExpiration (NSDate dateWithTimeIntervalSinceNow:(expires intValue)))
                  (set @token (results access_token:)))
            (else (set @token nil))))
    results)
 
 (- getAccessTokenForOrganizationWithClientID:clientID
                                       secret:clientSecret is
    (set query (dict grant_type:"client_credentials"
                      client_id:clientID
                  client_secret:clientSecret))
    (set path (+ @server
                 "/management/token?" (query urlQueryString)))
    (if (set results (self performGet:path))
        (set expires (results expires_in:))
        (set @tokenExpiration (NSDate dateWithTimeIntervalSinceNow:(expires intValue)))
        (set @token (results access_token:)))
    results)
 
 (- getAccessTokenForApplicationWithClientID:clientID
                                      secret:clientSecret is
    (set query (dict grant_type:"client_credentials"
                      client_id:clientID
                  client_secret:clientSecret))
    (set path (+ @server "/" @organization "/" @application
                 "/token?" (query urlQueryString)))
    (if (set results (self performGet:path))
        (set expires (results expires_in:))
        (set @tokenExpiration (NSDate dateWithTimeIntervalSinceNow:(expires intValue)))
        (set @token (results access_token:)))
    results)
 
 ;; Usergrid Application API
 
 (- getApplication is
    (self performGet:(+ @server "/" @organization "/" @application)))
 
 ;; GET entities
 
 (- getEntitiesInCollection:collection
                      limit:limit is
    (set query (dict limit:limit ql:"select *"))
    (self performGet:(+ @server "/" @organization "/" @application "/" collection "?" (query urlQueryString))))
 
 (- getEntitiesInCollection:collection
            withQueryString:queryString
                      limit:limit is
    (set query (dict limit:limit ql:queryString))
    (self performGet:(+ @server "/" @organization "/" @application "/" collection "?" (query urlQueryString))))
 
 (- getEntityInCollection:collection
                   withID:id is
    (self performGet:(+ @server "/" @organization "/" @application "/" collection "/" (id urlEncodedString))))
 
 ;; POST entities
 
 (- postEntities:entities
    toCollection:collection is
    (self performPost:(+ @server "/" @organization "/" @application "/" collection)
             withJSON:entities))
 
 (- postEntity:entity
  toCollection:collection is
    (self performPost:(+ @server "/" @organization "/" @application "/" collection)
             withJSON:entity))
 
 ;; PUT entities
 
 (- putEntities:entities
   inCollection:collection is
    (entities each:
              (do (entity)
                  (self putEntity:entity inCollection:collection)))
    ;; this doesn't work
    ;;  (self performPut:(+ @server "/" @organization "/" @application "/" collection)
    ;;          withJSON:entities)
    )
 
 (- putEntity:entity
 inCollection:collection is
    (set name (entity name:))
    (self performPut:(+ @server "/" @organization "/" @application "/" collection "/" name)
            withJSON:entity))
 
 ;; DELETE entities
 
 (- deleteEntitiesInCollection:collection is
    (self deleteEntitiesInCollection:collection
                     withQueryString:"select *"))
 
 (- deleteEntitiesInCollection:collection
               withQueryString:queryString is
    (set query (dict ql:queryString))
    (self performDelete:(+ @server "/" @organization "/" @application "/" collection "?" (query urlQueryString))))
 
 (- deleteEntityInCollection:collection
                      withID:id is
    (self performDelete:(+ @server "/" @organization "/" @application "/" collection "/" id)))
 
 ;; POST connections
 
 (- postConnection:connection is
    (self performPost:(+ @server "/" @organization "/" @application "/" connection)))
 
 )

(macro perform (name *action)
       `(progn (puts (+ "# " ,name))
               (set RESULTS (progn ,@*action))
               RESULTS))

(macro verbose (name *action)
       `(progn (puts (+ "# " ,name))
               (set RESULTS (progn ,@*action))
               (puts (RESULTS description))
               RESULTS))


