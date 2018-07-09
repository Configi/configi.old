(local C (require "u-cfg"))
(local S {})
(global _ENV nil)
(defn test [type]
  (tset C (.. "test :: " type)
    (fn []
        (C.equal 0 1))))
(tset S "test" test)
S
