;;;; specials.lisp

(uiop:define-package #:streams/specials
  (:use #:cl
        #:marie))

(in-package #:streams/specials)

(defvar* +self+
  "streams"
  "The base name of the system.")

(defvar* *universe* nil
  "The top-level structure for everything.")

(defvar* *atom-counter* 100
  "The initial mx-atom counter value.")

(defvar* *sub-atom-counter* 1000
  "The initial mx-sub-atom counter value.")

(defvar* *metadata-counter* 10000
  "The initial metadata counter value.")

(eval-always
  (defconstant* +base-namespace-list+
      '(("c" . "canon")
        ("m" . "machine")
        ("w" . "world")
        ("s" . "stream")
        ("v" . "view")
        ("@" . "atom"))
    "The list of base namespaces.")

  (defconstant* +sub-namespace-list+
      '(("d" . "datatype")
        ("f" . "format"))
    "The list of sub namespaces.")

  (defconstant* +colon-namespace-list+
      '((":" . "colon"))
    "The list of colon namespaces.")

  (defconstant* +namespace-list+
      (append +base-namespace-list+ +sub-namespace-list+)
    "The full list of namespaces, where the individual elements contain the namespace alias and full namespace name"))

(defconstant* +key-indicators+
    '("=" "/" "[]")
  "The list of strings used for setting end values.")

(defvar* *log-directory*
    (home (cat #\. +self+ #\/))
  "The path to the default configuration and storage directory.")

(defconstant* +log-file-suffix+
  "msl"
  "The default file suffix for log files.")

(defconstant* +iso-8601-re+
  "\\d{4}-\\d\\d-\\d\\dT\\d\\d:\\d\\d:\\d\\d(\\.\\d+)?(([+-]\\d\\d:\\d\\d)|Z)?"
  "The regular expression for ISO 8601 dates.")

(defconstant* +mimix-date-re+
  "\\d{4}-\\d\\d-\\d\\d@\\d\\d-\\d\\d-\\d\\d(\\.\\d+)?(([+-]\\d\\d\\d\\d)|Z)?"
  "The regular expression for Mimix dates.")

(defconstant* +day-names+
    '("Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
  "The enumeration of week day names.")

(defparameter* *maximum-log-size*
    5242880
    "The maximum filesize of logging files in bytes.")

(defvar* *machine*
  "my-machine"
  ;;(uiop:hostname)
  "The default name to use as the machine name.")

(defun* system-object (name)
  "Return the system object for the current system."
  (asdf:find-system (intern name (find-package :keyword))))

(defun* self-asdf ()
  "Return the ASDF file path for the current system."
  (uiop:merge-pathnames* (cat +self+ ".asd")
                         (asdf:system-source-directory (system-object +self+))))

(defun* read-self-asdf ()
  "Return the system ASDF file as s-expressions."
  (uiop:read-file-forms (self-asdf)))

(defun* system-version (name)
  "Return the version number extracted from the system resources."
  (let* ((system (system-object name))
         (asdf-base-name (cat name ".asd"))
         (source-directory (asdf:system-source-directory system))
         (forms (uiop:read-file-forms (uiop:merge-pathnames* asdf-base-name source-directory))))
    (getf (assoc 'defsystem forms :test #'equal) :version)))

(defvar* *system-version*
    ;; (uiop:os-cond
    ;;  ((uiop:os-windows-p) (system-version +self+))
    ;;  (t (asdf:system-version (system-object +self+))))
  "2.3.6"
  "The introspected version of this system.")

(defvar* *slynk-port*
  4005
  "The default slynk communication port.")

(defvar* *debug-print*
  t
  "Whether to print debugging information using a dedicated outputter.")
