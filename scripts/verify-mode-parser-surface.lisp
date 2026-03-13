;;; verify-mode-parser-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

(let* ((path "/home/slime/projects/clpkg-irc-clients/src/core/mode.coal")
       (c (slurp path)))
  (dolist (needle '("module Core.Mode"
                    "data ParseModeError"
                    "data ModeArgCursor"
                    "parse-mode-line"
                    "parse-mode-tokens"))
    (must-contain c needle path)))

(format t "MODE PARSER SURFACE CHECKS PASSED~%")
(sb-ext:exit :code 0)
