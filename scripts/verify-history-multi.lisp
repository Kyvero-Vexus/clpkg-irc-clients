;;; verify-history-multi.lisp

(load "/home/slime/projects/clpkg-irc-clients/src/net/connection.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/events.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/commands.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/client.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/history.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/multi.lisp")

(use-package :clpkg-irc-clients/history)
(use-package :clpkg-irc-clients/multi)
(use-package :clpkg-irc-clients/client)

(defun ok (x) (format t "PASS ~A~%" x))

;; History push + retrieve
(let ((buf (make-history-buffer :capacity 5)))
  (history-push! buf (make-history-entry :source "alice" :message "hello" :timestamp 1))
  (history-push! buf (make-history-entry :source "bob" :message "world" :timestamp 2))
  (assert (= 2 (hb-count buf)))
  (assert (= 2 (length (history-entries buf))))
  (ok "history push + count"))

;; History ring buffer eviction
(let ((buf (make-history-buffer :capacity 3)))
  (dotimes (i 5)
    (history-push! buf (make-history-entry :message (format nil "msg~D" i) :timestamp i)))
  (assert (= 3 (hb-count buf)))
  (ok "history eviction"))

;; History search
(let ((buf (make-history-buffer)))
  (history-push! buf (make-history-entry :message "Common Lisp rocks" :timestamp 1))
  (history-push! buf (make-history-entry :message "Python is ok" :timestamp 2))
  (let ((results (history-search buf "lisp")))
    (assert (= 1 (length results)))
    (ok "history search")))

;; Multi-server manager
(let ((mgr (make-server-manager)))
  (manager-add! mgr "libera" (make-irc-client :nick "a" :user "a" :realname "a" :host "irc.libera.chat"))
  (manager-add! mgr "oftc" (make-irc-client :nick "b" :user "b" :realname "b" :host "irc.oftc.net"))
  (assert (irc-client-p (manager-get mgr "libera")))
  (assert (irc-client-p (manager-get mgr "oftc")))
  (assert (null (manager-get mgr "nonexistent")))
  (ok "manager add + get"))

;; Manager connect/disconnect all
(let ((mgr (make-server-manager)))
  (manager-add! mgr "s1" (make-irc-client :nick "a" :user "a" :realname "a" :host "x"))
  (manager-add! mgr "s2" (make-irc-client :nick "b" :user "b" :realname "b" :host "y"))
  (manager-connect-all! mgr)
  (assert (= 2 (sm-active-count mgr)))
  (manager-disconnect-all! mgr)
  (assert (= 0 (sm-active-count mgr)))
  (ok "manager connect/disconnect all"))

;; Manager remove
(let ((mgr (make-server-manager)))
  (manager-add! mgr "s1" (make-irc-client :nick "a" :user "a" :realname "a" :host "x"))
  (manager-remove! mgr "s1")
  (assert (null (manager-get mgr "s1")))
  (ok "manager remove"))

(format t "HISTORY+MULTI CHECKS PASSED~%")
(sb-ext:exit :code 0)
