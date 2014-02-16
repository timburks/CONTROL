(set quotable (NSSet setWithArray:(array "Control" "Err503" "HeadRequire")))

;; use this class to write pound configuration files
(class PoundBlock is NSObject
     (ivar (id) name (id) properties (id) children)
     
     (- initWithName:n properties:p children:c is
        (super init)
        (set @name n)
        (set @properties p)
        (set @children c)
        self)
     
     (- initWithName:n properties:p is
        (self initWithName:n properties:p children:nil))
     
     (- write is (self writeWithIndent:""))
     
     (- writeWithIndent:indent is
        (set INDENT "    ")
        (if @name (puts (+ indent @name)))
        (set inner (if @name
                       (then (+ indent INDENT))
                       (else indent)))
        (((@properties allKeys) sort) each:
         (do (key)
             (set value (@properties key))
             (puts (if (quotable containsObject:key)
                       (then (+ inner key " \"" value "\""))
                       (else (+ inner key " " value))))))
        (@children each:
             (do (child)
                 (child writeWithIndent:inner)))
        (if @name (puts (+ indent "End")))))

(set top ((PoundBlock alloc)
          initWithName:nil
          properties:(dict LogLevel:4
                           LogFacility:"local4"
                           Daemon:0
                           Alive:3
                           Control:"/var/run/poundctl.socket")
          children:(array ((PoundBlock alloc)
                           initWithName:"ListenHTTP"
                           properties:(dict Address:"0.0.0.0"
                                            Port:80
                                            Err503:"/etc/pound/unavailable.html"
                                            xHTTP:1))
                          ((PoundBlock alloc)
                           initWithName:"Service"
                           properties:(dict HeadRequire:"deus.xmachine.net")
                           children:(array ((PoundBlock alloc)
                                            initWithName:"Backend"
                                            properties:(dict Address:"127.0.0.1"
                                                             Port:2010)))))))



(top write)
