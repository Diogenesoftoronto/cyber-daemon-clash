(in-package #:org.cyber.daemon.clash)

;; TODO:
;; copying code that  do not fully understand to eventually
;; understand it. The goal here is to have a proper deployment that
;; fits the structure of my game. This will require checking out how
;; shirakumo deploy library aims to achieve.
(deploy:define-hook (:deploy cyber-daemon-clash -1) (directory)
  (org.shirakumo.zippy:compress-zip (pathname-utils (data-root) "cyberspace"
						    make-pathname
						    :name "cyberspace" :type "zip" :defaults directory)
				    :strip-root T :if-exists
				    :supercede)
  (deploy:copy-directory-tree
   org.shirakumo.alloy.renderers.opengl::*shaders-directory*
   (pathname-utils.subdirectory directory "pool" "alloy")
   :copy-root NIL))
#+linux
(trial:dont-deploy
 org.shirakumo.file-select.gtk::gtk
 org.shirakumo.file-select.gtk::glib
 org.shirakumo.file-select.gtk::gmodule
 org.shirakumo.file-select.gtk::gio)

(depot:with-depot (depot (find-cyberspace))
  (v:info :cyber.quest "Setting up default cyberspace, this might take
  n time where n is maybe long")
  (setup-cyberspace NIL depot))
