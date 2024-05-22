
;; let's try to get trial running with a basic black box
(in-package #:org.cyber.daemon.clash)

(defclass main (trial:main)
  ())

(define-shader-entity my-character (vertex-entity transformed-entity listener)
		      ;; discs are basically circles heh
		      ((vertex-array :initform (// 'trial 'unit-cube))))

;; Create a daemon entity! We should think about what properties a daemon has:
;; A daemon can move (transformed-entity), it has an action-set (some behaviours) and a daemon
;; has a sprite that, it has a location. It also has a name, for now we will use
;; the name of the defined shader entity. At some point putting this into a
;; a macro like define-daemon would be cool. It can be collided with so it should have
;; a collision body. I can use the collision body defined in the example. I may have to
;; explicitly import it from trial-examples or just copy the collision file from trial.
;; Since daemons are sprites vertex-entity is the form they take.
(define-shader-entity a-daemon (sprite-enity transformed-entity collision-body listener)
		      (() 
		       ()))


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
;; since we are building a 2d game I have changed to use a 2d camera
(defmethod setup-scene ((main main) scene)
	   (enter (make-instance 'my-character) scene)
	   (enter (make-instance '2d-camera scene)
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
	   ;; in lisp mode that way you can, ;; automagically recompile and eval each run. It seems
	   ;; Shinmura has it at the end of her stuff so I will leave it without it being commented.
	   (maybe-reload-scene)
