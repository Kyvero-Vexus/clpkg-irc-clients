;;; verify-ctcp-tags-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

(let* ((path "/home/slime/projects/clpkg-irc-clients/src/core/ctcp-tags.coal")
       (c (slurp path)))
  (dolist (needle '("module Core.CtcpTags"
                    "data CtcpMessage"
                    "data MessageTag"
                    "parse-ctcp"
                    "format-ctcp"
                    "parse-message-tags"
                    "serialize-message-tags"))
    (must-contain c needle path)))

(format t "CTCP/TAGS SURFACE CHECKS PASSED~%")
(sb-ext:exit :code 0)
