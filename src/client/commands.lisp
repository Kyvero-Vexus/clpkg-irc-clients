;;; commands.lisp --- high-level IRC commands

(defpackage #:clpkg-irc-clients/commands
  (:use #:cl)
  (:export
   #:irc-command #:irc-command-p #:make-irc-command
   #:icmd-verb #:icmd-args
   #:format-join #:format-part #:format-privmsg #:format-nick
   #:format-quit #:format-mode #:format-raw))

(in-package #:clpkg-irc-clients/commands)

(defstruct (irc-command
             (:constructor make-irc-command (&key verb args))
             (:conc-name icmd-))
  (verb "" :type string)
  (args '() :type list))

(declaim (ftype (function (string) (values irc-command &optional)) format-join)
         (ftype (function (string &optional string) (values irc-command &optional)) format-part)
         (ftype (function (string string) (values irc-command &optional)) format-privmsg)
         (ftype (function (string) (values irc-command &optional)) format-nick)
         (ftype (function (&optional string) (values irc-command &optional)) format-quit)
         (ftype (function (string string) (values irc-command &optional)) format-mode)
         (ftype (function (string) (values irc-command &optional)) format-raw))

(defun format-join (channel)
  (declare (type string channel))
  (make-irc-command :verb "JOIN" :args (list channel)))

(defun format-part (channel &optional (message ""))
  (declare (type string channel message))
  (make-irc-command :verb "PART" :args (if (string= message "") (list channel) (list channel message))))

(defun format-privmsg (target message)
  (declare (type string target message))
  (make-irc-command :verb "PRIVMSG" :args (list target message)))

(defun format-nick (nick)
  (declare (type string nick))
  (make-irc-command :verb "NICK" :args (list nick)))

(defun format-quit (&optional (message ""))
  (declare (type string message))
  (make-irc-command :verb "QUIT" :args (if (string= message "") nil (list message))))

(defun format-mode (target modes)
  (declare (type string target modes))
  (make-irc-command :verb "MODE" :args (list target modes)))

(defun format-raw (line)
  (declare (type string line))
  (make-irc-command :verb "RAW" :args (list line)))
