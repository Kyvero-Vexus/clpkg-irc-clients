;;; verify-bot-router.lisp

(load "/home/slime/projects/clpkg-irc-clients/src/bot/router.lisp")
(use-package :clpkg-irc-clients/bot)

(defun ok (x) (format t "PASS ~A~%" x))

;; Register + dispatch
(let ((r (make-command-router :prefix "!"))
      (result nil))
  (router-register! r (make-command-handler
                        :name "ping"
                        :description "Responds with pong"
                        :handler-fn (lambda (cmd) (declare (ignore cmd)) (setf result "pong"))))
  (router-dispatch r (make-bot-command :name "ping" :source "alice" :channel "#test"))
  (assert (string= "pong" result))
  (ok "register + dispatch"))

;; List commands
(let ((r (make-command-router)))
  (router-register! r (make-command-handler :name "help" :description "Help"))
  (router-register! r (make-command-handler :name "about" :description "About"))
  (assert (equal '("about" "help") (router-list-commands r)))
  (ok "list commands"))

;; Command not found
(let ((r (make-command-router)))
  (handler-case (router-dispatch r (make-bot-command :name "unknown"))
    (command-not-found (c) (assert (string= "unknown" (clpkg-irc-clients/bot::command-not-found-name c)))
      (ok "command not found"))
    (:no-error (&rest _) (declare (ignore _)) (error "Expected command-not-found"))))

;; Plugin loading
(let ((r (make-command-router))
      (p (make-plugin :name "test-plugin" :version "1.0"
                      :commands (list (make-command-handler :name "greet" :description "Greet")))))
  (router-load-plugin! r p)
  (assert (equal '("greet") (router-list-commands r)))
  (ok "plugin loading"))

(format t "BOT ROUTER CHECKS PASSED~%")
(sb-ext:exit :code 0)
