;;;; unparser.lisp

(uiop:define-package #:streams/unparser
  (:use #:cl
        #:streams/specials
        #:streams/classes
        #:streams/common
        #:marie))

(in-package #:streams/unparser)

(defun table-keys (table)
  "Return the direct keys under TABLE."
  (when (hash-table-p table)
    (loop :for k :being :the :hash-key :in table :collect k)))

(defun children (table &optional object)
  "Return all items in TABLE using KEY that are also tables."
  (when (hash-table-p table)
    (let ((keys (table-keys table)))
      (loop :for key :in keys
            :for value = (gethash key table)
            :when (hash-table-p value)
            :collect (if object value key)))))

(defun metadatap (value)
  "Return true if VALUE is the : namespace."
  (when*
    (consp value)
    (mem (car value) '(":"))))

(defun modsp (value)
  "Return true if VALUE is a datatype or format form."
  (when*
    (consp value)
    (mem (car value) '("d" "f"))))

(defun prefixedp (value)
  "Return true if VALUE is prefixed by certain namespaces."
  (rmap-or value #'metadatap #'modsp))

(defun marshall (list)
  "Return a list where non-cons items are made conses."
  (mapcar #'(lambda (item)
              (if (consp item) item (list item)))
          list))

(defun join (list)
  "Return a list where items in LIST are flattened to one level."
  (reduce #'(lambda (x y)
              (cond ((metadatap y) (append x (list y)))
                    ((modsp y) (append x (list y)))
                    (t (append x y))))
          (marshall list)))

(defun wrap (list)
  "Return a new list where items in LIST are conditionally listified."
  (mapcar #'(lambda (item)
              (cond ((or (atom item)
                         (and (consp item)
                              (not (prefixedp item))
                              (not (stringp (car item)))))
                     (list item))
                    ((metadatap item)
                     (cons (cat (car item) (cadr item))
                           (cddr item)))
                    (t item)))
          list))

(defun stage (list)
  "Return a new list from LIST where the items preprocessed for wrapping and joining."
  (labels ((fn (args acc)
             (cond ((null args) (nreverse acc))
                   ((modsp (car args))
                    (fn (cdr args)
                        (cons (join (car args)) acc)))
                   ((metadatap (car args))
                    (fn (cdr args)
                        (cons (join (wrap (fn (car args) nil)))
                              acc)))
                   (t (fn (cdr args)
                          (cons (car args) acc))))))
    (fn list nil)))

(defun make-regex (exprs)
  "Return a list containing raw regex expressions from VALUE."
  (flet ((fn (expr)
           (destructuring-bind (regex &optional env val)
               expr
             (cat "/" regex "/" (or env "")
                  (if val (cat " " val) "")))))
    (mapcar #'fn exprs)))

(defun make-transform (exprs)
  (flet ((fn (expr) (cat "[" expr "]")))
    (mapcar #'fn exprs)))

(defun normalize (list)
  "Return special merging on items of LIST."
  (labels ((fn (val)
             (cond ((metadatap val) (cons (car val) (cadr val)))
                   (t val))))
    (join (wrap (stage (mapcar #'fn list))))))

(defun attach (list)
  "Return the list (X Y ...) from (X (Y ...)) from LIST."
  (labels ((fn (val)
             (cond ((modsp val) (cons (car val) (cadr val)))
                   (t val))))
    (fn list)))

(defun combine (items)
  "Apply COMBINE on ITEMS."
  (mapcar #'attach items))

(defun compose (items)
  "Apply additional merging operations to items in LIST."
  (labels ((fn (args acc)
             (cond ((null args) (nreverse acc))
                   ((metadatap (car args))
                    (fn (cdr args)
                        (cons (list (caar args)
                                    (combine (cadr (car args))))
                              acc)))
                   (t (fn (cdr args)
                          (cons (attach (car args))
                                acc))))))
    (fn items nil)))

(defun accumulate (keys acc &optional data)
  "Return an accumulator value suitable for CONSTRUCT."
  (flet ((fn (k a d)
           (cond ((mem k '("=")) a)
                 ((mem k '("/")) (cons (make-regex d) a))
                 ((mem k '("[]")) (cons (make-transform d) a))
                 (t (cons k a)))))
    (destructuring-bind (key &optional &rest _)
        keys
      (declare (ignore _))
      (let ((value (fn key acc data)))
        (cond ((mem key '("/" "[]")) value)
              (t (cons data value)))))))

(defun make-head (list)
  "Return a list with custom head merging."
  (when (consp (cdr list))
    (destructuring-bind (ns &optional &rest _)
        list
      (declare (ignore _))
      (cond ((string= ns "@")
             (cons (cat ns (cadr list))
                   (cddr list)))
            (t list)))))

(defun* (construct t) (key table &optional keys)
  "Return the original expressions in TABLE under KEY."
  (labels ((fn (tab keys acc)
             (let ((v (gethash (car keys) tab)))
               (cond ((null keys) (nreverse acc))
                     ((hash-table-p v)
                      (fn tab
                          (cdr keys)
                          (cons (fn v
                                    (table-keys v)
                                    (list (car keys)))
                                acc)))
                     (t (fn tab
                            (cdr keys)
                            (accumulate keys acc v)))))))
    (when-let* ((ht (gethash key table))
                (entries (or keys (table-keys ht))))
      (loop :for v :in (fn ht entries nil)
            :for kv = (make-head (cons key v))
            :when kv
            :collect (normalize (compose kv))))))

(defun* (convert t) (terms)
  "Return the original expression from TERMS."
  (flet ((fn (v)
           (destructuring-bind (((ns key) &rest _) &rest __)
               v
             (declare (ignore _ __))
             (car (construct ns (atom-table *universe*) (list key))))))
    (cond ((valid-terms-p terms #'base-namespace-p) (fn terms))
          (t terms))))

(defun* (build-string t) (value)
  "Return the string version of expression VALUE."
  (labels ((fn (args &optional acc)
             (cond ((null args) (string* (nreverse acc)))
                   ((consp (car args))
                    (fn (cdr args)
                        (cons (fn (car args) nil)
                              acc)))
                   (t (fn (cdr args) (cons (car args) acc))))))
    (fn value)))

(defun* (collect t) (&rest keys)
  "Return the original expressions in TABLE."
  (declare (ignorable keys))
  (let* ((table (atom-table *universe*))
         (children (children table)))
    (mapcar #'build-string
            (loop :for child :in children
                  :with cache
                  :nconc (loop :for terms :in (construct child table keys)
                               :unless (mem (build-string terms) cache)
                               :collect (loop :for term :in terms
                                              :for v = (convert term)
                                              :when (valid-terms-p term #'base-namespace-p)
                                              :do (pushnew (build-string v) cache :test #'equal)
                                              :collect v))))))
