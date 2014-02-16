(load "RadHTTP:macros")
(load "RadCrypto")
(load "RadMongoDB")

(set SITE "control")
(set PASSWORD_SALT SITE)

(if (eq (uname) "Linux")
    (then (set CONTROL-PATH "/home/control"))
    (else (set CONTROL-PATH "/AgentBox")))

(class NSString
 (- (id) md5HashWithSalt:(id) salt is
    (((self dataUsingEncoding:NSUTF8StringEncoding)
      hmacMd5DataWithKey:(salt dataUsingEncoding:NSUTF8StringEncoding))
     hexEncodedString)))
