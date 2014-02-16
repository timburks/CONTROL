(load "RadKit")

(set KEYS ((NSData dataWithContentsOfFile:("~/.keys/digitalocean.plist" stringByExpandingTildeInPath)) propertyListValue))

(set ClientID (KEYS ClientID:))
(set APIKey   (KEYS APIKey:))
(puts ClientID)
(puts APIKey)


(class DigitalOcean is NSObject
 ;; internal
 (- init is
    (super init)
    (set @root "https://api.digitalocean.com")
    self)
 (- args is
    (dict client_id:@clientID api_key:@apiKey))
 (- requestForPath:path is
    (NSMutableURLRequest requestWithURL:(NSURL URLWithString:path)))
 ;; public methods
 (- getDomains is
    (self requestForPath:(+ @root "/domains/?" ((self args) URLQueryString))))
 (- getDroplets is
    (self requestForPath:(+ @root "/droplets/?" ((self args) URLQueryString))))
 (- getRegions is
    (self requestForPath:(+ @root "/regions/?" ((self args) URLQueryString))))
 (- getImages is
    (self requestForPath:(+ @root "/images/?" ((self args) URLQueryString))))
 (- getSSHKeys is
    (self requestForPath:(+ @root "/ssh_keys/?" ((self args) URLQueryString))))
 (- getSizes is
    (self requestForPath:(+ @root "/sizes/?" ((self args) URLQueryString))))
 ;; name=
 ;; image_id=
 ;; region_id=
 ;; ssh_key_ids=[,]
 ;; size_id=
 (- createNewDroplet:droplet is
    (droplet addEntriesFromDictionary:(self args))
    (self requestForPath:(+ @root "/droplets/new?" (droplet URLQueryString))))
 
 
 (- destroyDropletWithID:dropletid is
    (self requestForPath:(+ @root "/droplets/" dropletid "/destroy/?" ((self args) URLQueryString))))
 
 ;; name=
 ;; ip_address=
 (- createNewDomain:domain is
    (domain addEntriesFromDictionary:(self args))
    (self requestForPath:(+ @root "/domains/new?" (domain URLQueryString))))
 
 (- destroyDomainWithID:domainid is
    (self requestForPath:(+ @root "/domains/" domainid "/destroy/?" ((self args) URLQueryString))))
 
 )

(function run (command)
          (puts (command description))
          (set client ((RadHTTPClient alloc) initWithRequest:command))
          (set result (client connect))
          (puts ((result UTF8String)))
          (puts ((result object) description)))

(set ocean (DigitalOcean new))
(ocean setClientID:ClientID)
(ocean setApiKey:APIKey)

(if NO
    (run (ocean getRegions))
    (run (ocean getImages))
    (run (ocean getSSHKeys))
    (run (ocean getSizes)))

(if NO
    (run (ocean createNewDroplet:(dict name:"sample.agent.io"
                                   image_id:600573
                                  region_id:3
                                ssh_key_ids:24304
                                    size_id:66))))

;(run (ocean destroyDropletWithID:341416))

(run (ocean getDroplets))


;(run (ocean destroyDomainWithID:55533))

;(run (ocean createNewDomain:(dict name:"sample.agent.io" ip_address:"192.241.225.217")))

(run (ocean getDomains))


;;


