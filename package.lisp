;; Here is where I need to define what my package will use

(defpackage #:org.cyber.daemon.clash
  (:use #:cl+trial)
  (:shadow #:main #:launch)
  (:local-nicknames
   (#:v #:org.shirakumo.verbose))
  (:export #:main #:launch))
