;;; verify-irc-message-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

(let* ((path "/home/slime/projects/clpkg-irc-clients/src/core/irc-message.coal")
       (c (slurp path)))
  (dolist (needle '("module Core.IrcMessage"
                    "data Prefix"
                    "data Command"
                    "CmdNumeric"
                    "data IrcMessage"
                    "parse-irc-line"
                    "serialize-irc-message"))
    (must-contain c needle path)))

(format t "IRC MESSAGE SURFACE CHECKS PASSED~%")
(sb-ext:exit :code 0)
