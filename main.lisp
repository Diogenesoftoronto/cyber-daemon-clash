
;; let's try to get trial running with a basic black box
(in-package #:org.cyber.daemon.clash)

(defclass main (trial:main)
  ())

(define-shader-entity my-character (vertex-entity transformed-entity listener)
  ;; discs are basically circles heh
  ((vertex-array :initform (// 'trial 'unit-cube))))

;; (define-handler (my-character tick) (tt)
;;   ;; vx horizontal, vy vertical axis spinning.
;;   (setf (orientation my-character) (qfrom-angle +vx+ tt)))

(define-handler (my-character tick) (dt)

  (let ((movement (directional 'move))
        (speed 10.0))
    (incf (vx (location my-character)) (* dt speed (- (vx movement))))
    (incf (vz (location my-character)) (* dt speed (vy movement)))))
;; This is our action set. It is the actions that a person can take in the game,
;; specifically/usually actions that a player can take via an input device like
;; a game pad or... a keyboard etc. You get the point.
(define-action-set in-game)
(define-action move (directional-action in-game))
(define-action hide (in-game))

;; we will define a a method here for setting a scene
(defmethod setup-scene ((main main) scene)
  (enter (make-instance 'my-character) scene)
  (enter (make-instance '3d-camera :location (vec 0 0 -3)) scene)
  (enter (make-instance 'render-pass) scene))

(setf +app-system+ "cyber-daemon-clash")

;; This function launches the game, passing arguments or doing things here
;; can let you pass values into the game before launch. For example the location
;; of assets, or the location of a keymap file, suppose you load specific maps
;; and actions depending on the device instead of a particular file... these
;; are all possible.
(defun launch (&rest args)
  (let ((*package* #.*package*))
    (load-keymap)
    (setf (active-p (action-set 'in-game)) T)
    (apply #'trial:launch 'main args)))

;; You can evaluate this with sly via sly-eval-region, which is mapped to
;; C-c C-r. You will need to remember to recompile the code before doing this
;; though. A thing you can do is map this to a keyboard macro for faster game dev
;; in lisp mode that way you can, ;; automagically recompile and eval each run.
;; ;; (maybe-reload-scene)
