;; This is load at run time as the is stuff is not expected to be compiled without errors.

(directional move
	     (stick :one-of ((:l-h :l-v)))
	     (keys :one-of ((:w :a :s :d))))

(trigger hide
	 (button :one-of (:a))
	 (key :one-of (:space)))
