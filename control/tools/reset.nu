(load "agentbox")

(mongo dropCollection:"apps" inDatabase:SITE)
(mongo dropCollection:"deployments" inDatabase:SITE)

