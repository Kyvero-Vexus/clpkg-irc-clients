;;; events.lisp --- typed IRC event hierarchy + dispatch

(defpackage #:clpkg-irc-clients/events
  (:use #:cl)
  (:export
   #:irc-event #:irc-event-p #:make-irc-event
   #:ev-kind #:ev-source #:ev-target #:ev-payload #:ev-timestamp
   #:event-listener #:event-listener-p #:make-event-listener
   #:el-kind #:el-handler
   #:event-dispatcher #:event-dispatcher-p #:make-event-dispatcher
   #:ed-listeners
   #:dispatch-event #:register-listener))

(in-package #:clpkg-irc-clients/events)

(deftype event-kind ()
  '(member :connect :disconnect :message :join :part :quit :nick :mode
           :kick :topic :invite :notice :privmsg :ctcp :numeric :error :raw))

(defstruct (irc-event
             (:constructor make-irc-event (&key kind source target payload timestamp))
             (:conc-name ev-))
  (kind :raw :type event-kind)
  (source "" :type string)
  (target "" :type string)
  (payload "" :type string)
  (timestamp 0 :type integer))

(defstruct (event-listener
             (:constructor make-event-listener (&key kind handler))
             (:conc-name el-))
  (kind :raw :type event-kind)
  (handler (lambda (ev) (declare (ignore ev))) :type function))

(defstruct (event-dispatcher
             (:constructor make-event-dispatcher (&key (listeners nil)))
             (:conc-name ed-))
  (listeners '() :type list))

(declaim (ftype (function (event-dispatcher event-kind function) (values event-dispatcher &optional))
                register-listener)
         (ftype (function (event-dispatcher irc-event) (values list &optional))
                dispatch-event))

(defun register-listener (dispatcher kind handler)
  (declare (type event-dispatcher dispatcher)
           (type event-kind kind)
           (type function handler))
  (push (make-event-listener :kind kind :handler handler)
        (ed-listeners dispatcher))
  dispatcher)

(defun dispatch-event (dispatcher event)
  "Dispatch event to all matching listeners. Returns list of handler results."
  (declare (type event-dispatcher dispatcher) (type irc-event event))
  (let ((results '()))
    (dolist (listener (ed-listeners dispatcher))
      (when (eq (el-kind listener) (ev-kind event))
        (push (funcall (el-handler listener) event) results)))
    (nreverse results)))
