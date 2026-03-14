;;; verify-net-connection.lisp

(load "/home/slime/projects/clpkg-irc-clients/src/net/connection.lisp")
(use-package :clpkg-irc-clients/net)

(defun ok (x) (format t "PASS ~A~%" x))

;; Connection state transitions
(let ((c (make-irc-connection :host "irc.libera.chat" :port 6697 :tls-p t)))
  (assert (eq :disconnected (conn-state c)))
  (connect! c)
  (assert (eq :connected (conn-state c)))
  (disconnect! c)
  (assert (eq :disconnected (conn-state c)))
  (ok "connect/disconnect"))

;; Reconnect counting
(let ((c (make-irc-connection :host "x" :port 6667 :max-reconnects 2)))
  (reconnect! c)
  (assert (= 1 (conn-reconnect-count c)))
  (reconnect! c)
  (assert (= 2 (conn-reconnect-count c)))
  (handler-case
      (progn (reconnect! c) (error "expected refused"))
    (connection-refused () (ok "reconnect limit"))))

;; Rate limiter
(let ((rl (make-rate-limiter :window-s 10 :max-messages 3 :window-start 100)))
  (assert (rate-limit-check rl 105))
  (rate-limit-record! rl 105)
  (rate-limit-record! rl 106)
  (rate-limit-record! rl 107)
  (handler-case
      (progn (rate-limit-record! rl 108) (error "expected exceeded"))
    (rate-limit-exceeded () (ok "rate limit enforced")))
  ;; Window reset
  (assert (rate-limit-check rl 200))
  (rate-limit-record! rl 200)
  (ok "rate limit window reset"))

(format t "NET CONNECTION CHECKS PASSED~%")
(sb-ext:exit :code 0)
