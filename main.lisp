(in-package #:org.cyber.daemon.clash)

(defclass main (trial:main)
  ())

;; Create a daemon entity! We should think about what properties a daemon
;; has: A daemon can move (transformed-entity), it has an action-set (some
;; behaviours) and a daemon has a sprite that, it has a location. It also has
;; a name, for now we will use the name of the defined shader entity. At some
;; point putting this into a macro like define-daemon would be cool. It
;; can be collided with so it should have a collision body. I can use the
;; collision body defined in the example. I may have to explicitly import
;; it from trial-examples or just copy the collision file from trial.
;; Since daemons are sprites vertex-entity is the form they take.  



;; Presumably there is an pool of assets for daemons that you
;; can add to much like example asset pool that shinmera uses in the trial
;; examples.
(define-pool daemonbench) 

 
;; I just copied the code from trial for the load-keymap function
;; the save-keymap function. 
(defun daemon-path ()
  (make-pathname :name "daemons" :type "lisp"
                 :defaults (config-directory)))

(defun load-daemons (&key (path (daemon-path)) reset)
  (ensure-directories-exist path) (cond ((or reset
             (not (probe-file path)) (< (file-write-date path)
                (file-write-date (merge-pathnames "daemons.lisp"
                (data-root)))))
         (load-mapping (merge-pathnames "daemons.lisp" (data-root))) (when
         (and (probe-file path) (null reset))
           (load-mapping path))
         (save-daemons :path path))
        (T
         (load-mapping path))))

(defun save-daemons (&key (path (daemon-path)))
  (ensure-directories-exist path) (save-mapping path))

;; Daemon list contains all the daemons. I
;; was going to use this as a sb-ext:defglobal but this is not known at comptime.
(setf +daemon-list+ (load-daemons)) 

(define-event daemon-died (event))
 
;; I need to make sure that there is
;; actually daemon-sprite.json file in the data/.  
(define-asset (daemonbench sprite) sprite-data #p"daemon-sprite.png")
;; Instead of workbench use a different set of animation to use, make
;; them importable into the game, check Kandria for how Shinmera deals with
;; these.Shinmera just says to use play here but I am not sure exactly how
;; that works. Okay, sorta figured it out, she means to use play instead of
;; enter. The thing that I need to figure out is more advanced animations. Like
;; switching-animations. 

(define-action-set daemon-set) 
(define-action dmove
  (directional-action daemon-set)) 
(define-action ping (daemon-set))
(define-action spawn (daemon-set))
;; This really will need to be a macro i think because i need to
;; specify a particular daemon in the daemon pool in order to construct them
;; dynamically... I think maybe i could use a struct and constructor for them?
(define-shader-entity a-daemon (animated-sprite transformed-entity
  collision-body listener)
  (:default-initargs :sprite-data (asset 'daemonbench 'a-daemon))) 
;; daemons should have some initialization standards, for example sometype
;; of indeterminate location, and resource contraints.
;; Definining constriants will be difficult. The daemon should also have
;; a set of base behaviours that are available to take.  

;; Test daemon inherits methods of a-daemon
(define-shader-entity test-daemon (vertex-entity a-daemon)
  (vertex-array :initform (// 'trial 'unit-cube))) 

;; Not sure what i should really be putting here will have to figure
;; it out. This looks for other daemons.
(define-handler (a-daemon ping) (tt)
  ()) 

(define-handler (a-daemon spawn)
    (push (make-instance 'a-daemon) +daemon-list+))
;; I need to find a way to add them as part of the scene as they spawn.
;; I wonder if adding them to the daemon list is what i should do?
;; Also I want this to return not just an instance of a-daemon,
;; but I want it to be like 'this' when it is called on test-daemon
;; for example, I want it to spawn a test daemon and add it to the daemon list.
   
(define-handler (a-daemon tick) (tt)
  ;; vx horizontal, vy vertical axis spinning.  
  (setf (orientation a-daemon) (qfrom-angle +vx+ tt)))


;; shinmera does stuff with this, not sure will check later.  
(define-event character-died (event)) 

(define-shader-entity my-character 
  (vertex-entity transformed-entity listener)
  ;; discs are basically circles heh 
  ((vertex-array :initform (// 'trial 'unit-cube))))

(define-handler (my-character tick) (dt)

  (let ((movement (directional 'move))
	(speed 2.5))
    (incf (vx (location my-character)) (* dt speed (- (vx movement))))
    (incf (vz (location my-character)) (* dt speed (vy movement)))))

;; This is our action set. It is the actions that a person can take in the game,
;; specifically/usually actions that a player can take via an input device like
;; a game pad or... a keyboard etc. You get the point.
(define-action-set in-game) (define-action move (directional-action in-game))
(define-action hide (in-game))

;; We will define a a method here for setting a scene 
;; since we are building a 2d game I have changed to use a 2d camera 
(defmethod setup-scene
  ((main main) scene)
	;; The idea is that this should play the animation for each of the daemons.
	;; consider dolist as this makes more sense than, `for` because of the lack
	;; of syntax.
  (loop for dd in +daemon-list+
	(enter (make-instance 'dd)) scene)
    (enter (make-instance 'my-character) scene) 
    (enter (make-instance '2d-camera) scene)
  	 ;; Consider using a custom camera that will zoom into particular
  	 ;; 'selected' characters or at least focus on them.  
    (enter (make-instance 'render-pass) scene))

(setf +app-system+ "cyber-daemon-clash")

;; This function launches the game, passing arguments or doing things here can
;; let you pass values into the game before launch. For example the location
;; of assets, or the location of a keymap file, suppose you load specific maps
;; and actions depending on the device instead of a particular file... these
;; are all possible.

(defun launch (&rest args)
  (let ((*package* #.*package*))
    (load-keymap) (setf (active-p (action-set 'in-game)) T) 
    (apply #'trial:launch 'main args)))

;; You can evaluate this with sly via sly-eval-region, which is mapped to
;; C-c C-r. You will need to remember to recompile the code before doing this
;; though. A thing you can do is map this to a keyboard macro for faster game
;; dev in lisp mode that way you can, automagically recompile and eval each
;; run. It seems Shinmera has it at the end of her stuff.

(maybe-reload-scene)
