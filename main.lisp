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
  (ensure-directories-exist path)
  (cond ((or reset
             (not (probe-file path)) (< (file-write-date path)
                (file-write-date (merge-pathnames "daemons.lisp"
                (data-root)))))
         (load-mapping (merge-pathnames "daemons.lisp" (data-root)))
	 (when
         (and (probe-file path) (null reset))
           (load-mapping path))
         (save-daemons :path path))
        (T
         (load-mapping path))))

(defun save-daemons (&key (path (daemon-path)))
  (ensure-directories-exist path) (save-mapping path))



(define-event daemon-died (event))
(setf +daemons-list+ (list))
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
(define-shader-entity daemon (animated-sprite transformed-entity
  collision-body listener)
  (daemon-list :default-initarg :daemon-list (list)))
;; daemons should have some initialization standards, for example sometype
;; of indeterminate location, and resource contraints.
;; Definining constriants will be difficult. The daemon should also have
;; a set of base behaviours that are available to take.  

;; Test daemon inherits methods of a-daemon
(define-shader-entity test-daemon (vertex-entity daemon)
  
  (:default-initargs :sprite-data (asset 'daemonbench 'daemon))) 

(setf +broadcasted-daemons+ '()) ;; broadcasted daemons are ones that are visible to all
;; daemons, when you ping you are added to the broadcasted daemons.

;; 
(defun extend-list-with-entry (obj place accessor)
  (let
      ((accessed (getf place accessor)))
    (push obj accessed)))

;; -> returns bool for it being nil or not, really considering creating the pbool type for real booleans
(defun nil? (q &optional p &rest args)
  (if (not q)
      (if (not p)
          (loop for (r s) on args by #'cddr
                always (nil? r s))
	 T)
    NIL))

(defun not-nil? (q &optional p &rest args) (not (nil? q p args)))

;; This function must do resource constraint checking, if resource are out then this should immediately stop.
(defun send-message (sender sendee message &rest messages &key accessor &allow-other-keys)
  (cond
    ((nil? message (car messages) (cdr messages)) ;; both NIL?
     (loop for m in messages do (send-message sender sendee m)))  
    ((not-nil? message (car messages) (cdr messages))
     (send-message sender sendee message)
     (loop for m in message do (send-message sender sendee m))) ;; [cond form 1]
    ((equal message 'ping) ;; condition
     (send-message sendee sender 'pong) ;; action 'clauses'...
     (extend-list-with-entry sendee sender accessor))
    ((equal message 'pong)
     (extend-list-with-entry sendee sender accessor))
    ((not message)
     (send-message sender sendee message))))

;; In addition, to adding messages to the daemon-list of the accessor, process-message should also do some work with the messages
;; i.e. process-message should PARSE the messages and then do actions or behaviours based on them, this may be possible
;; via a passed in parse function. NOTE: One thing to remember is that send-message and process-message should be given their
;; accessors otherwise they cannot extend their lists with the extender, WARNING: current implementation will result in infinite recursion.
;; This function must do resource constraint checking, if resource are out then this should immediately stop.
(defun process-message (reciever recievee message &rest messages &key accessor parser &allow-other-keys)
  (cond
    ((nil? message (car messages) (cdr messages)) ;; both NIL?
     (loop for m in messages do (process-message reciever recievee m)))  
    ((not-nil? message (car messages) (cdr messages))
     (process-message reciever recievee message)
     (loop for m in message do (process-message reciever recievee m))) ;; [cond form 1]
    ((equal message 'ping) ;; condition
     (process-message recievee reciever 'pong) ;; action 'clauses'...
     (extend-list-with-entry recievee reciever accessor))
    ((equal message 'pong)
     (extend-list-with-entry recievee reciever accessor))
    ((not message)
     (process-message reciever recievee message))))

(define-handler (setf daemon-list)
    ()) ;; filter from the global daemons, a list of daemons that have been pinged/sent orrecieved messages to/from this daemon.

;; Not sure what i should really be putting here will have to figure
;; it out. This looks for other daemons.
(define-handler (daemon ping) (other-daemon)
  (send-message 'daemon 'other-daemon)) 

(define-handler (daemon spawn) ()
  (push (make-instance (class-of daemon)) +daemon-list+))

(define-handler (daemon sleep) (tt)
  ()) ;; will do nothing until 
;; I need to find a way to add them as part of the scene as they spawn.
;; I wonder if adding them to the daemon list is what i should do?
;; Also I want this to return not just an instance of a-daemon,
;; but I want it to be like 'this' when it is called on test-daemon
;; for example, I want it to spawn a test daemon and add it to the daemon list.
   
(define-handler (daemon tick) (tt)
  ;; vx horizontal, vy vertical axis spinning.  
  (setf (orientation daemon) (qfrom-angle +vx+ tt)))

;; Daemon list contains all the daemons. I
;; was going to use this as a sb-ext:defglobal but this is not known at comptime.

;; (let (bindings*) body)
;; (let ((ds (list))) body)
;; (let ((ds (list))) (loop ...) ds)

(setf +daemon-list+ (let ((ds (list))) (loop repeat 5
					    do (push 'test-daemon ds)))
			  ds)

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
  (loop for dd in +daemon-list+ do
	(enter (make-instance 'dd) scene))
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
