;;;; sexp.lisp

(uiop:define-package #:streams/sexp
  (:use #:cl
        #:maxpc
        #:streams/common
        #:marie)
  (:export #:parse))

(in-package #:streams/sexp)

(defun not-doublequote (char)
  "Return true if CHAR is not the doublequote character."
  (not (eql #\" char)))

(defun not-integer (string)
  "Return true if string is not an integer."
  (when (find-if-not #'digit-char-p string)
    t))

(defun inp (integer start &optional end)
  "Return true if INTEGER is within START and END, inclusively."
  (if end
      (and (>= integer start)
           (<= integer end))
      (= integer start)))

(defun extra-char-p (char)
  "Return true if CHAR is one of supplementary characters."
  (let ((code (char-code char)))
    (or (inp code #x21 #x22)            ; #\! #\"
        (inp code #x23 #x27)            ; #\# #\$ #\% #\& #\'
        (inp code #x2A #x2F)            ; #\* #\+ #\, #\- #\. #\/
        (inp code #x3A #x40)            ; #\: #\; #\< #\= #\> #\? #\@
        (inp code #x5B #x60)            ; #\[ #\\ #\] #\^ #\_ #\`
        (inp code #x7B #x7E)            ; #\{ #\| #\} #\~
        (>= code #x7F))))               ; other characters

(defun ?msl-char-p ()
  "Return a parser that checks if an argument are letters, numbers, or extra characters."
  (%or (?satisfies 'alphanumericp)
       (?satisfies 'extra-char-p)))

(defun ?string-char ()
  "Return a parser that checks for string character delimiters."
  (%or (?seq (?eq #\\) (?eq #\"))
       (?satisfies 'not-doublequote)))

(defun =atom ()
  "Return a parser that checks for an atom."
  (%or (=string) (maxpc.digit:=integer-number) (=symbol)))

(defun =string ()
  "Return a parser that checks for strings"
  (=destructure (_ s _)
    (=list (?eq #\")
           (=subseq (%any (?string-char)))
           (?eq #\"))))

(defun =symbol ()
  "Return a parser that checks for accepted symbols."
  (=transform (=subseq (?satisfies 'not-integer (=subseq (%some (?msl-char-p)))))
              'intern))

(define-parser =sexp ()
  "Define a parser for the base s-expression."
  (%or 'slist (=atom)))

(define-parser =slist ()
  "Define a parser for the base s-expression lists."
  (=destructure (_ expressions _ _)
    (=list (?eq #\()
           (%any (=destructure (_ expression)
                   (=list (%any (maxpc.char:?whitespace))
                          'sexp)))
           (%any (maxpc.char:?whitespace))
           (?eq #\)))))
