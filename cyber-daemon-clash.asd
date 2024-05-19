(asdf:defsystem cyber-daemon-clash
  :components ((:file "package")
               (:file "main"))
  :depends-on (:trial
               :trial-glfw
               :trial-png))

