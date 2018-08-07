(local C (require "configi"))
(local S {})
(global _ENV nil)
(defn test [type]
  (tset C (.. "test :: " type)
    (fn []
      (C.equal 0 1)
      (C.print "prints something"))))
(tset S "test" test)
S
