;;; verify-cap-sasl-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

(let* ((path "/home/slime/projects/clpkg-irc-clients/src/core/cap-sasl.coal")
       (c (slurp path)))
  (dolist (needle '("module Core.CapSasl"
                    "data CapState"
                    "data SaslState"
                    "data CapEvent"
                    "data SaslEvent"
                    "step-cap"
                    "step-sasl"))
    (must-contain c needle path)))

(format t "CAP/SASL SURFACE CHECKS PASSED~%")
(sb-ext:exit :code 0)
