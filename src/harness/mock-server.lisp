;;; mock-server.lisp --- typed mock IRC server + e2e harness baseline

(defpackage #:clpkg-irc-clients/harness
  (:use #:cl)
  (:export
   #:mock-server
   #:make-mock-server
   #:mock-server-p
   #:server-inbound
   #:server-outbound
   #:server-running-p
   #:enqueue-line!
   #:dequeue-line!
   #:pump-once!
   #:run-e2e-scenario))

(in-package #:clpkg-irc-clients/harness)

(defstruct (mock-server
             (:constructor make-mock-server (&key (inbound '()) (outbound '()) (running-p t)))
             (:conc-name server-))
  (inbound '() :type list)
  (outbound '() :type list)
  (running-p t :type boolean))

(declaim (ftype (function (mock-server string) (values mock-server &optional)) enqueue-line!)
         (ftype (function (mock-server) (values (or null string) mock-server &optional)) dequeue-line!)
         (ftype (function (mock-server) (values mock-server &optional)) pump-once!)
         (ftype (function (list) (values list &optional)) run-e2e-scenario))

(defun enqueue-line! (server line)
  (declare (type mock-server server) (type string line))
  (setf (server-inbound server) (append (server-inbound server) (list line)))
  server)

(defun dequeue-line! (server)
  (declare (type mock-server server))
  (let ((q (server-inbound server)))
    (if (null q)
        (values nil server)
        (progn
          (setf (server-inbound server) (rest q))
          (values (first q) server)))))

(defun pump-once! (server)
  (declare (type mock-server server))
  (multiple-value-bind (line s) (dequeue-line! server)
    (if line
        (progn
          (setf (server-outbound s)
                (append (server-outbound s)
                        (list (format nil "ACK:~A" line))))
          s)
        s)))

(defun run-e2e-scenario (lines)
  "Run deterministic mock-server scenario; return outbound transcript." 
  (let ((s (make-mock-server)))
    (dolist (l lines)
      (enqueue-line! s l)
      (pump-once! s))
    (server-outbound s)))
