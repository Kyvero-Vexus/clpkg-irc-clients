;;; verify-state-reducer-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

(let* ((path "/home/slime/projects/clpkg-irc-clients/src/core/state.coal")
       (c (slurp path)))
  (dolist (needle '("module Core.State"
                    "data IrcEvent"
                    "EvJoin"
                    "EvPart"
                    "EvQuit"
                    "EvNick"
                    "EvMode"
                    "apply-mode-delta"
                    "reduce-event"
                    "reduce-events"))
    (must-contain c needle path)))

(format t "STATE REDUCER SURFACE CHECKS PASSED~%")
(sb-ext:exit :code 0)
