;;; verify-client-layer.lisp

(load "/home/slime/projects/clpkg-irc-clients/src/net/connection.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/events.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/commands.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/client.lisp")

(use-package :clpkg-irc-clients/events)
(use-package :clpkg-irc-clients/commands)
(use-package :clpkg-irc-clients/client)

(defun ok (x) (format t "PASS ~A~%" x))

;; Event dispatch
(let* ((d (make-event-dispatcher))
       (got nil))
  (register-listener d :message (lambda (ev) (setf got (ev-payload ev))))
  (dispatch-event d (make-irc-event :kind :message :payload "hello"))
  (assert (string= "hello" got))
  (ok "event dispatch"))

;; Non-matching events ignored
(let* ((d (make-event-dispatcher))
       (count 0))
  (register-listener d :join (lambda (ev) (declare (ignore ev)) (incf count)))
  (dispatch-event d (make-irc-event :kind :message :payload "x"))
  (assert (= 0 count))
  (ok "event filtering"))

;; Commands
(let ((c (format-join "#lisp")))
  (assert (string= "JOIN" (icmd-verb c)))
  (assert (string= "#lisp" (first (icmd-args c))))
  (ok "format-join"))

(let ((c (format-privmsg "bob" "hi")))
  (assert (string= "PRIVMSG" (icmd-verb c)))
  (ok "format-privmsg"))

(let ((c (format-quit "bye")))
  (assert (string= "QUIT" (icmd-verb c)))
  (ok "format-quit"))

;; Client lifecycle
(let ((c (make-irc-client :nick "test" :user "test" :realname "Test"
                          :host "localhost" :port 6667)))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (client-connect! c)
  (assert (eq :connected (client-state c)))
  (client-join! c "#test")
  (assert (member "#test" (client-channels c) :test #'string=))
  (client-part! c "#test")
  (assert (not (member "#test" (client-channels c) :test #'string=)))
  (client-quit! c)
  (assert (eq :disconnected (client-state c)))
  (ok "client lifecycle"))

(format t "CLIENT LAYER CHECKS PASSED~%")
(sb-ext:exit :code 0)
