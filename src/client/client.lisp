;;; client.lisp --- main IRC client object + state tracking

(defpackage #:clpkg-irc-clients/client
  (:use #:cl)
  (:import-from #:clpkg-irc-clients/net
                #:irc-connection #:make-irc-connection #:conn-state
                #:connect! #:disconnect!)
  (:import-from #:clpkg-irc-clients/events
                #:event-dispatcher #:make-event-dispatcher
                #:dispatch-event #:register-listener #:make-irc-event)
  (:import-from #:clpkg-irc-clients/commands
                #:irc-command #:make-irc-command #:icmd-verb #:icmd-args)
  (:export
   #:irc-client #:irc-client-p #:make-irc-client
   #:client-nick #:client-user #:client-realname
   #:client-connection #:client-dispatcher #:client-channels #:client-state
   #:client-connect! #:client-disconnect! #:client-send-command!
   #:client-join! #:client-part! #:client-privmsg! #:client-quit!))

(in-package #:clpkg-irc-clients/client)

(defstruct (irc-client
             (:constructor make-irc-client
                 (&key nick user realname host (port 6667) (tls-p nil)))
             (:conc-name client-))
  (nick "clpkg" :type string)
  (user "clpkg" :type string)
  (realname "CL IRC Client" :type string)
  (connection nil :type (or null irc-connection))
  (dispatcher nil :type (or null event-dispatcher))
  (channels '() :type list)
  (state :disconnected :type keyword))

(declaim (ftype (function (irc-client) (values irc-client &optional)) client-connect!)
         (ftype (function (irc-client) (values irc-client &optional)) client-disconnect!)
         (ftype (function (irc-client irc-command) (values irc-client &optional)) client-send-command!)
         (ftype (function (irc-client string) (values irc-client &optional)) client-join!)
         (ftype (function (irc-client string) (values irc-client &optional)) client-part!)
         (ftype (function (irc-client string string) (values irc-client &optional)) client-privmsg!)
         (ftype (function (irc-client) (values irc-client &optional)) client-quit!))

(defun %ensure-init (client host port tls-p)
  (unless (client-connection client)
    (setf (client-connection client)
          (make-irc-connection :host host :port port :tls-p tls-p)))
  (unless (client-dispatcher client)
    (setf (client-dispatcher client) (make-event-dispatcher)))
  client)

(defun client-connect! (client)
  (declare (type irc-client client))
  (let ((conn (client-connection client)))
    (when conn (connect! conn)))
  (setf (client-state client) :connected)
  client)

(defun client-disconnect! (client)
  (declare (type irc-client client))
  (let ((conn (client-connection client)))
    (when conn (disconnect! conn)))
  (setf (client-state client) :disconnected
        (client-channels client) '())
  client)

(defun client-send-command! (client command)
  (declare (type irc-client client) (type irc-command command))
  ;; Stub: in full implementation, serializes command to connection
  (when (client-dispatcher client)
    (dispatch-event (client-dispatcher client)
                    (make-irc-event :kind :raw
                                   :source (client-nick client)
                                   :payload (icmd-verb command)
                                   :timestamp (get-universal-time))))
  client)

(defun client-join! (client channel)
  (declare (type irc-client client) (type string channel))
  (pushnew channel (client-channels client) :test #'string=)
  client)

(defun client-part! (client channel)
  (declare (type irc-client client) (type string channel))
  (setf (client-channels client)
        (remove channel (client-channels client) :test #'string=))
  client)

(defun client-privmsg! (client target message)
  (declare (type irc-client client) (type string target message))
  (client-send-command! client
                        (make-irc-command :verb "PRIVMSG" :args (list target message))))

(defun client-quit! (client)
  (declare (type irc-client client))
  (client-disconnect! client))
