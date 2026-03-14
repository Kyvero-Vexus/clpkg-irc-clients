;;; connection.lisp --- typed TCP/TLS connection + rate limiter + reconnect

(defpackage #:clpkg-irc-clients/net
  (:use #:cl)
  (:export
   ;; Connection record
   #:irc-connection #:irc-connection-p #:make-irc-connection
   #:conn-host #:conn-port #:conn-tls-p #:conn-state
   #:conn-reconnect-delay-s #:conn-max-reconnects
   #:conn-reconnect-count #:conn-last-connect-at
   ;; Rate limiter
   #:rate-limiter #:rate-limiter-p #:make-rate-limiter
   #:rl-window-s #:rl-max-messages #:rl-message-count #:rl-window-start
   #:rate-limit-check #:rate-limit-record!
   ;; Conditions
   #:connection-refused #:connection-timeout #:rate-limit-exceeded
   ;; State transitions
   #:connect! #:disconnect! #:reconnect!))

(in-package #:clpkg-irc-clients/net)

(define-condition connection-refused (error)
  ((host :initarg :host :reader connection-refused-host)
   (port :initarg :port :reader connection-refused-port)))

(define-condition connection-timeout (error)
  ((host :initarg :host :reader connection-timeout-host)
   (timeout-s :initarg :timeout-s :reader connection-timeout-value)))

(define-condition rate-limit-exceeded (error)
  ((count :initarg :count :reader rate-limit-exceeded-count)
   (max :initarg :max :reader rate-limit-exceeded-max)))

(defstruct (irc-connection
             (:constructor make-irc-connection
                 (&key host port (tls-p nil) (state :disconnected)
                       (reconnect-delay-s 5) (max-reconnects 10)
                       (reconnect-count 0) (last-connect-at 0)))
             (:conc-name conn-))
  (host "localhost" :type string)
  (port 6667 :type fixnum)
  (tls-p nil :type boolean)
  (state :disconnected :type keyword)
  (reconnect-delay-s 5 :type fixnum)
  (max-reconnects 10 :type fixnum)
  (reconnect-count 0 :type fixnum)
  (last-connect-at 0 :type integer))

(defstruct (rate-limiter
             (:constructor make-rate-limiter
                 (&key (window-s 30) (max-messages 10)
                       (message-count 0) (window-start 0)))
             (:conc-name rl-))
  (window-s 30 :type fixnum)
  (max-messages 10 :type fixnum)
  (message-count 0 :type fixnum)
  (window-start 0 :type integer))

(declaim (ftype (function (rate-limiter integer) (values boolean &optional)) rate-limit-check)
         (ftype (function (rate-limiter integer) (values rate-limiter &optional)) rate-limit-record!)
         (ftype (function (irc-connection) (values irc-connection &optional)) connect!)
         (ftype (function (irc-connection) (values irc-connection &optional)) disconnect!)
         (ftype (function (irc-connection) (values irc-connection &optional)) reconnect!))

(defun rate-limit-check (rl now)
  "Return T if message is allowed under rate limit."
  (declare (type rate-limiter rl) (type integer now))
  (if (> (- now (rl-window-start rl)) (rl-window-s rl))
      t
      (< (rl-message-count rl) (rl-max-messages rl))))

(defun rate-limit-record! (rl now)
  "Record a message send, resetting window if expired."
  (declare (type rate-limiter rl) (type integer now))
  (when (> (- now (rl-window-start rl)) (rl-window-s rl))
    (setf (rl-window-start rl) now
          (rl-message-count rl) 0))
  (unless (< (rl-message-count rl) (rl-max-messages rl))
    (error 'rate-limit-exceeded
           :count (rl-message-count rl)
           :max (rl-max-messages rl)))
  (incf (rl-message-count rl))
  rl)

(defun connect! (conn)
  "Transition connection to :connected state (stub — no real socket)."
  (declare (type irc-connection conn))
  (setf (conn-state conn) :connected
        (conn-last-connect-at conn) (get-universal-time))
  conn)

(defun disconnect! (conn)
  "Transition connection to :disconnected."
  (declare (type irc-connection conn))
  (setf (conn-state conn) :disconnected)
  conn)

(defun reconnect! (conn)
  "Attempt reconnect with count tracking."
  (declare (type irc-connection conn))
  (when (>= (conn-reconnect-count conn) (conn-max-reconnects conn))
    (error 'connection-refused
           :host (conn-host conn)
           :port (conn-port conn)))
  (incf (conn-reconnect-count conn))
  (connect! conn))
