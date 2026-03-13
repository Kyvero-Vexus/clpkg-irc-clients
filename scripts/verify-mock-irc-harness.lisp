;;; verify-mock-irc-harness.lisp

(load "/home/slime/projects/clpkg-irc-clients/src/harness/mock-server.lisp")
(use-package :clpkg-irc-clients/harness)

(defun ok (x) (format t "PASS ~A~%" x))

(let* ((lines '("NICK alice" "JOIN #lisp" "MODE #lisp +o alice"))
       (out (run-e2e-scenario lines)))
  (assert (= 3 (length out)))
  (assert (string= "ACK:NICK alice" (first out)))
  (assert (string= "ACK:JOIN #lisp" (second out)))
  (assert (string= "ACK:MODE #lisp +o alice" (third out)))
  (ok "mock-server e2e transcript"))

(sb-ext:exit :code 0)
