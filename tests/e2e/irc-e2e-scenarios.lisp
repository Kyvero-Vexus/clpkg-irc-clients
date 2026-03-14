;;; irc-e2e-scenarios.lisp — E2E scenario suite for IRC client stack

(load "/home/slime/projects/clpkg-irc-clients/src/net/connection.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/events.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/commands.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/client.lisp")

(use-package :clpkg-irc-clients/net)
(use-package :clpkg-irc-clients/events)
(use-package :clpkg-irc-clients/commands)
(use-package :clpkg-irc-clients/client)

(defvar *pass* 0)
(defvar *fail* 0)

(defun ok (x) (incf *pass*) (format t "PASS E~2,'0D: ~A~%" *pass* x))
(defun fail! (x) (incf *fail*) (format t "FAIL: ~A~%" x))

;;; E01: Connect and register nick
(let ((c (make-irc-client :nick "test" :user "test" :realname "E2E" :host "localhost" :port 6667)))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (client-connect! c)
  (assert (eq :connected (client-state c)))
  (ok "connect + register"))

;;; E02: Join channel
(let ((c (make-irc-client :nick "test" :user "test" :realname "E2E" :host "localhost" :port 6667)))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (client-connect! c)
  (client-join! c "#lisp")
  (assert (member "#lisp" (client-channels c) :test #'string=))
  (ok "join channel"))

;;; E03: Part channel
(let ((c (make-irc-client :nick "test" :user "test" :realname "E2E" :host "localhost" :port 6667)))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (client-connect! c)
  (client-join! c "#test")
  (client-part! c "#test")
  (assert (not (member "#test" (client-channels c) :test #'string=)))
  (ok "part channel"))

;;; E04: Send PRIVMSG
(let ((c (make-irc-client :nick "test" :user "test" :realname "E2E" :host "localhost" :port 6667)))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (client-connect! c)
  (client-privmsg! c "#lisp" "hello")
  (ok "send privmsg"))

;;; E05: Quit cleanly
(let ((c (make-irc-client :nick "test" :user "test" :realname "E2E" :host "localhost" :port 6667)))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (client-connect! c)
  (client-quit! c)
  (assert (eq :disconnected (client-state c)))
  (ok "quit cleanly"))

;;; E06: Event dispatch on message
(let* ((d (make-event-dispatcher))
       (received nil))
  (register-listener d :message (lambda (ev) (setf received (ev-payload ev))))
  (dispatch-event d (make-irc-event :kind :message :payload "test"))
  (assert (string= "test" received))
  (ok "event dispatch message"))

;;; E07: Event filtering (no false dispatch)
(let* ((d (make-event-dispatcher))
       (count 0))
  (register-listener d :join (lambda (ev) (declare (ignore ev)) (incf count)))
  (dispatch-event d (make-irc-event :kind :quit))
  (assert (= 0 count))
  (ok "event filtering"))

;;; E08: Multiple listeners on same event
(let* ((d (make-event-dispatcher))
       (results '()))
  (register-listener d :nick (lambda (ev) (push (ev-payload ev) results)))
  (register-listener d :nick (lambda (ev) (push (format nil "2:~A" (ev-payload ev)) results)))
  (dispatch-event d (make-irc-event :kind :nick :payload "new"))
  (assert (= 2 (length results)))
  (ok "multiple listeners"))

;;; E09: Command formatting (JOIN)
(let ((c (format-join "#cl")))
  (assert (string= "JOIN" (icmd-verb c)))
  (ok "format JOIN"))

;;; E10: Command formatting (PART with message)
(let ((c (format-part "#cl" "bye")))
  (assert (string= "PART" (icmd-verb c)))
  (assert (= 2 (length (icmd-args c))))
  (ok "format PART with message"))

;;; E11: Command formatting (NICK)
(let ((c (format-nick "newnick")))
  (assert (string= "NICK" (icmd-verb c)))
  (ok "format NICK"))

;;; E12: Command formatting (MODE)
(let ((c (format-mode "#lisp" "+o alice")))
  (assert (string= "MODE" (icmd-verb c)))
  (ok "format MODE"))

;;; E13: Rate limiter allows within window
(let ((rl (make-rate-limiter :window-s 10 :max-messages 5 :window-start 100)))
  (assert (rate-limit-check rl 105))
  (rate-limit-record! rl 105)
  (ok "rate limit allows"))

;;; E14: Rate limiter denies over limit
(let ((rl (make-rate-limiter :window-s 10 :max-messages 1 :window-start 100)))
  (rate-limit-record! rl 105)
  (handler-case
      (progn (rate-limit-record! rl 106) (error "expected exceeded"))
    (rate-limit-exceeded () (ok "rate limit denies"))))

;;; E15: Reconnect with count tracking
(let ((conn (make-irc-connection :host "x" :port 6667 :max-reconnects 1)))
  (reconnect! conn)
  (assert (= 1 (conn-reconnect-count conn)))
  (handler-case
      (progn (reconnect! conn) (error "expected refused"))
    (connection-refused () (ok "reconnect limit"))))

;;; E16: Multi-channel tracking
(let ((c (make-irc-client :nick "test" :user "test" :realname "E2E" :host "localhost" :port 6667)))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (client-join! c "#a")
  (client-join! c "#b")
  (client-join! c "#c")
  (assert (= 3 (length (client-channels c))))
  (client-part! c "#b")
  (assert (= 2 (length (client-channels c))))
  (ok "multi-channel tracking"))

;;; E17: Duplicate join idempotent
(let ((c (make-irc-client :nick "test" :user "test" :realname "E2E" :host "localhost" :port 6667)))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (client-join! c "#dup")
  (client-join! c "#dup")
  (assert (= 1 (count "#dup" (client-channels c) :test #'string=)))
  (ok "join idempotent"))

;;; E18: Raw command passthrough
(let ((c (format-raw "PING :test")))
  (assert (string= "RAW" (icmd-verb c)))
  (ok "raw command"))

(format t "~%E2E RESULTS: ~D/~D PASSED~%" *pass* (+ *pass* *fail*))
(assert (= 0 *fail*))
(sb-ext:exit :code 0)
