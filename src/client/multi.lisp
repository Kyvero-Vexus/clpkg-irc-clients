;;; multi.lisp --- multi-server connection manager

(defpackage #:clpkg-irc-clients/multi
  (:use #:cl)
  (:import-from #:clpkg-irc-clients/client
                #:irc-client #:irc-client-p #:make-irc-client
                #:client-connect! #:client-disconnect! #:client-state)
  (:export
   #:server-manager #:server-manager-p #:make-server-manager
   #:sm-clients #:sm-active-count
   #:manager-add! #:manager-remove! #:manager-get
   #:manager-connect-all! #:manager-disconnect-all!))

(in-package #:clpkg-irc-clients/multi)

(defstruct (server-manager
             (:constructor make-server-manager (&key (clients nil)))
             (:conc-name sm-))
  (clients '() :type list)) ; alist of (name . irc-client)

(declaim (ftype (function (server-manager string irc-client) (values server-manager &optional)) manager-add!)
         (ftype (function (server-manager string) (values server-manager &optional)) manager-remove!)
         (ftype (function (server-manager string) (values (or null irc-client) &optional)) manager-get)
         (ftype (function (server-manager) (values fixnum &optional)) sm-active-count)
         (ftype (function (server-manager) (values server-manager &optional)) manager-connect-all!)
         (ftype (function (server-manager) (values server-manager &optional)) manager-disconnect-all!))

(defun manager-add! (manager name client)
  (declare (type server-manager manager) (type string name) (type irc-client client))
  (let ((existing (assoc name (sm-clients manager) :test #'string=)))
    (if existing
        (setf (cdr existing) client)
        (push (cons name client) (sm-clients manager))))
  manager)

(defun manager-remove! (manager name)
  (declare (type server-manager manager) (type string name))
  (setf (sm-clients manager)
        (remove name (sm-clients manager) :key #'car :test #'string=))
  manager)

(defun manager-get (manager name)
  (declare (type server-manager manager) (type string name))
  (cdr (assoc name (sm-clients manager) :test #'string=)))

(defun sm-active-count (manager)
  (declare (type server-manager manager))
  (count-if (lambda (pair)
              (eq :connected (client-state (cdr pair))))
            (sm-clients manager)))

(defun manager-connect-all! (manager)
  (declare (type server-manager manager))
  (dolist (pair (sm-clients manager))
    (let ((client (cdr pair)))
      (clpkg-irc-clients/client::%ensure-init
       client "localhost" 6667 nil)
      (client-connect! client)))
  manager)

(defun manager-disconnect-all! (manager)
  (declare (type server-manager manager))
  (dolist (pair (sm-clients manager))
    (client-disconnect! (cdr pair)))
  manager)
