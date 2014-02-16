
(function generate-sandbox-description (CONTAINER APPNAME PORT)
          (set TEMPLATE <<-END
;;
;; sample rules for sandboxing web apps
;; Copyright (c) 2010 Radtastical Inc.  All Rights reserved.
;;
;; WARNING: The sandbox rules in this file currently constitute
;; Apple System Private Interface and are subject to change at any time and
;; without notice.
;;

(version 1)

(allow default)

END)
          TEMPLATE)
