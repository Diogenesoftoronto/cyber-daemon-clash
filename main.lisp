
;; let's try to get trial running with a basic black box
(in-package #:org.cyber-daemon-clash)

(defclass main (trial:main)
  ())

(defun launch (&rest args)
  (apply #'trial:launch 'main args))
