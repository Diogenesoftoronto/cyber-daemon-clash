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


;; gratefull threads :)
(defstruct dread
  (id 1 :type integer)
  (status :waiting :type symbol))

(defparameter *default-threads-state* (list (make-dread)))
;; TODO: figure out how to do to get this working as a more accurate
;; type for threads.

(defstruct threads (state *default-threads-state* :type list)
	   (amount (length *default-threads-state*) :type integer :read-only
	    T))
;; TODO: use eval-when for some compile time checking, do not know how to do
;; that yet
(defun push-thread (instance thread) (if (dread-p thread)
					 (push thread (threads-state instance))
					 (error "You pushed an undreadful
	   object to the threads state. Shame.")))

(defparameter *default-threads* (make-threads))
(defclass machine () (
		      (title :initarg :title :initform 'IBM-704
			     :accessor title)
		      (kflops :initarg :speed :initform 12 :accessor kflops) ;; kiloflops
		      (memory :initarg :memory :initform 18 :accessor
			      memory)
		      (threads :initarg :threads :initform
			       *default-threads* :accessor threads))) ;; Threads are another struct which includes state like whether the threads are busy or not, what they are busy doing like the task/message they are processing, and other stuff like the amount of threads.
;; (defun make-person (name &key lisper)
;;   (make-instance 'person :name name :lisper lisper))

(defun make-machine (title memory &key speed threads) (make-instance
						       'machine :title
						       title :memory
						       memory :speed
						       speed :threads
						       threads))

;; (defun make-machine () (make-instance 'machine))
;; would be cool to have different arities but alas this is a dream.

(defparameter *default-machine* (make-instance 'machine))

;; This really will need to be a macro i think because i need to specify a particular daemon in the daemon pool in order to construct them dynamically... I think maybe i could use a struct and constructor for them? daemons should have some initialization standards, for example sometype of indeterminate location, and resource contraints. Definining constriants will be difficult. The daemon should also have a set of base behaviours that are available to take.

(defclass daemon (transformed-entity
		  listener)
  ((name :initarg :name :initform 'lucifer) ;; TODO: Make it so that
   ;; this only happens once. perhaps define that in the function, also
   ;; when someone tries to setf name to lucifer, check to see if the
   ;; function has been run before and add some nice easter eggs like
   ;; 'there can only be one' 'sorry your daemon funds are insufficient'
   ;; and other funnny names.
   (machine :initarg :machine :initform *default-machine* :accessor machine))
  (:documentation "Daemons are actors that have 'process' messages
with a processor, they must belong to machines which constrain their behavior."))

(defvar *daemon-list* (list (make-instance 'daemon)))

;; WARNING: you need to make sure that there is
;; actually daemon-sprite.json file in the data/.  
(define-asset (daemonbench daemon) sprite-data #p"daemon-sprite.png")

;; Instead of workbench use a different set of animation to use, make
;; them importable into the game, check Kandria for how Shinmera deals
;; with these.Shinmera just says to use play here but I am not sure
;; exactly how that works. Okay, sorta figured it out, she means to
;; use play instead of enter. The thing that I need to figure out is
;; more advanced animations. Like switching-animations.


(define-action-set daemon-set) 
(define-action dmove
  (directional-action daemon-set)) 
(define-action ping (daemon-set))
(define-action spawn (daemon-set))
;; (define-action sleep (daemon-set))

;; Test daemon inherits methods of a-daemon
(define-shader-entity test-daemon (animated-sprite daemon)
  ((sprite :initarg :sprite-data :initform (asset 'daemonbench 'daemon)))) 

(defvar *broadcasted-daemons*) ;; broadcasted daemons are ones that are visible to all
;; daemons, when you ping you are added to the broadcasted daemons.

(defmethod extend-list-with-entry (obj place (accessor daemon))
  (let
      ((accessed (getf place accessor)))
    (push obj accessed)))

;; -> returns bool for it being nil or not, really considering
;; -> creating the pbool type for real booleans
(defun nil? (q &optional p &rest args)
  (if (not q)
      (if (not p)
          (loop for (r s) on args by #'cddr
                always (nil? r s))
	  T)
      NIL))

(defun not-nil? (q &optional p &rest args) (not (nil? q p args)))

;; This function must do resource constraint checking, if resource are out then this should immediately stop.
;; The Accessor is usually thought of as the daemon class, there is potential to turn this into a defmethod, but for now, a function is sufficient.
(defmethod send-message (sender sendee message &rest messages &key accessor &allow-other-keys)
  (cond
    ((equal message 'ping) ;; condition
     (send-message sendee sender 'pong) ;; action 'clauses'...
     (extend-list-with-entry sendee sender accessor))  
    ((equal message 'pong)
     (extend-list-with-entry sender sendee accessor)))
  (loop for m in messages do (setf accessor message)))

;; In addition, to adding messages to the daemon-list of the accessor,
;; process-message should also do some work with the messages
;; i.e. process-message should PARSE the messages and then do actions
;; or behaviours based on them, this may be possible
;; via a passed in parse function. NOTE: One thing to remember is that
;; send-message and process-message should be given their accessors
;; otherwise they cannot extend their lists with the extender,
;; WARNING: current implementation will result in infinite recursion.
;; This function must do resource constraint checking, if resource are
;; out then this should immediately stop.
;; Another thing to consider, perhaps currying would be useful for
;; this function, it could simplify the amount of code here and
;; preserve a sort of state of messages.

(defmethod process-message ((accessor daemon) processor &rest messages)
  (loop for message in messages do (processor accessor message)))

(defmethod processor ((mutator daemon) message)
  (when (check-constriants mutator)
    (princ message))) ;; the base processor should print the message 


(defparameter *memory-constraints* 1024) ;; in kb
(defparameter *cpu-constraints* 2) ;; maybe this is like time? decaseconds?
;; You could actually curry these to different machines if you had to,
;; for example if you need to constrain the memory for a particular
;; server, and capacity etc was also changed you could partially save
;; the state of memory as a machine so that all machines being passed
;; in would have some of the same state. TODO: these machines should
;; be getting the machine's memory, etc and then checking against the
;; global defparameter memory or perhaps, some thing scoped to the
;; machine if the machine is a curried function with state?

(defmethod has-memory? ((machine machine)) (> *memory-constraints* (getf machine 'cpu *memory-constraints*)))
(defmethod has-proccessing-capacity? ((machine machine)) (> *cpu-constraints* (getf machine 'cpu *cpu-constraints*)))
(defmethod has-waiting-thread? ((machine machine)) (equal 'WAITING (getf machine 'thread-status 'WAITING)))

(defun check-constriants (machine)
  (cond
    ((has-memory? machine) T)
    ((has-proccessing-capacity? machine) T)
    ((has-waiting-thread? machine) T)))
;; If a computer has the memory, and the processing capacity (I think this means that it is ready to process it?)


(defmethod (setf daemon-list)
    ()) ;; filter from the global daemons, a list of daemons that have been pinged/sent orrecieved messages to/from this daemon.

;; Not sure what i should really be putting here will have to figure
;; it out. This looks for other daemons.
(define-handler (daemon ping) ()
  (send-message 'daemon 'other-daemon 'ping :accessor 'daemon-list)) 

(define-handler (daemon spawn) ()
  (push (make-instance (class-of daemon)) *daemon-list*))

;; (define-handler (daemon sleep) ()
;;   ()) ;; will do nothing until 
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
;; (setf *daemon-list* (let ((ds (list))) (loop repeat 5
;; 					     do (push 'test-daemon ds))
;; 		      ds))

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
  (enter (make-instance 'my-character) scene) 
  (enter (make-instance '2d-camera  :location (vec 0 0 -2)) scene)
  (enter (make-instance 'render-pass) scene))

(setf +app-system+ "cyber-daemon-clash")
;; Consider using a custom camera that will zoom into particular
;; 'selected' characters or at least focus on them.  

;; The idea is that this should play the animation for each of the daemons.
;; consider dolist as this makes more sense than, `for` because of the lack
;; of syntax.
;; (loop for dd in *daemon-list*
;; 	do (enter dd scene))
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
