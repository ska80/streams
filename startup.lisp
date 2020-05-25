;;;; startup.lisp

(uiop:define-package #:streams/startup
  (:use #:cl
        #:streams/specials
        #:streams/classes
        #:streams/logger
        #:streams/dispatcher
        #:marie))

(in-package #:streams/startup)

(defun initialize-universe ()
  "Initialize the universe."
  (setf *universe* (make-universe)))

(initialize-universe)

(defun* read-log (path)
  "Read the log file specified under PATH."
  (let ((exprs (uiop:read-file-lines path)))
    (loop :for expr :in exprs :do (dispatch expr nil))))

(defun* restore-log (&key (machine *machine*))
  "Re-initialize the universe"
  (let ((path (log-path* :machine machine)))
    (when path
      (read-log (log-path* :machine machine)))))

(restore-log)
