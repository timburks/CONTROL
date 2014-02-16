(load "agentbox")

(set apps (mongo findArray:nil inCollection:(+ SITE ".apps")))

(puts (apps description))

