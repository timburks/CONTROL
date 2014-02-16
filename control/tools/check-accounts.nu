;; check-accounts.nu

;; ensures that all accounts have an associated secret

(load "agentbox")

(set accounts (mongo findArray:nil inCollection:(+ SITE ".users")))
(accounts each:
          (do (account)
              (puts (account description))
              (unless (account secret:)
                      (set secret ((RadUUID new) stringValue))
                      (set update (dict secret:secret))
                      (mongo updateObject:(dict $set:update)
                             inCollection:(+ SITE ".users")
                            withCondition:(dict _id:(account _id:))
                        insertIfNecessary:NO
                    updateMultipleEntries:NO))))

