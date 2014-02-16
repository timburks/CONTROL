
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

;(deny default)
(allow default)

;(debug deny)

(allow file-read-data file-read-metadata
       (regex "^/usr/local/bin"
              "^/usr/local/lib/.*\.dylib$"
              "^/usr/lib/.*\.dylib$"
              "^/System/Library/Frameworks"
              "^/System/Library/PrivateFrameworks"
              "^/Library/Frameworks"
	      "^/etc"
	      "^/var"
              "/private/var/db/mds/messages/se_SecurityMessages"
	      "^/usr/share/icu/icudt40l.dat"
              "^/private/etc/resolv.conf"
              "^/private/etc/hosts"
              "^/System"
              "^/Library"
              "^#{CONTROL-PATH}/workers/#{CONTAINER}/#{APPNAME}.app"))

(allow file-read-data file-read-metadata file-write-data
       (regex ; Allow files accessed by system dylibs and frameworks
              "^/dev/null$"
              "^(/private)?/var/run/syslog$"
              "^/dev/u?random$"
              "^/dev/autofs_nowait$"
              "^/dev/dtracehelper$"
	      "^#{CONTROL-PATH}/workers/#{CONTAINER}/var"
              "/\.CFUserTextEncoding$"
              "^(/private)?/etc/localtime$"
              "^/usr/share/nls/"
              "^/usr/share/zoneinfo/"))

(allow file-ioctl
       (regex ; Allow access to dtracehelper by dyld
              "^/dev/dtracehelper$"))

(allow mach-lookup
       (global-name "com.apple.bsd.dirhelper")
       (global-name "com.apple.system.DirectoryService.libinfo_v1")
       (global-name "com.apple.system.DirectoryService.membership_v1")
       (global-name "com.apple.system.logger")
       (global-name "com.apple.system.notification_center"))

(allow signal (target self))

(allow mach-lookup)

(allow network-inbound)
(allow network-outbound)

;; only allow the process to bind to a designated port
;;(deny network-bind (local ip4))
(allow network-bind (local ip4 "*:#{PORT}"))

;(deny process-fork)
(allow process-exec)

(allow ipc-posix-shm)
(allow sysctl-read)

END)
          TEMPLATE)
