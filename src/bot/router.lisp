;;; router.lisp --- bot command router + plugin protocol

(defpackage #:clpkg-irc-clients/bot
  (:use #:cl)
  (:export
   #:bot-command #:bot-command-p #:make-bot-command
   #:bc-name #:bc-args #:bc-source #:bc-channel
   #:command-handler #:command-handler-p #:make-command-handler
   #:ch-name #:ch-description #:ch-handler-fn
   #:command-router #:command-router-p #:make-command-router
   #:router-register! #:router-dispatch #:router-list-commands
   #:plugin #:plugin-p #:make-plugin
   #:pg-name #:pg-version #:pg-commands
   #:router-load-plugin!
   #:command-not-found))

(in-package #:clpkg-irc-clients/bot)

;;; ─── Conditions ───

(define-condition command-not-found (error)
  ((name :initarg :name :reader command-not-found-name))
  (:report (lambda (c s) (format s "Unknown command: ~A" (command-not-found-name c)))))

;;; ─── Types ───

(defstruct (bot-command
             (:constructor make-bot-command (&key name args source channel))
             (:conc-name bc-))
  (name "" :type string)
  (args '() :type list)
  (source "" :type string)
  (channel "" :type string))

(defstruct (command-handler
             (:constructor make-command-handler (&key name description handler-fn))
             (:conc-name ch-))
  (name "" :type string)
  (description "" :type string)
  (handler-fn (lambda (cmd) (declare (ignore cmd)) nil) :type function))

(defstruct (command-router
             (:constructor make-command-router (&key (prefix "!")))
             (:conc-name cr-))
  (prefix "!" :type string)
  (handlers (make-hash-table :test 'equal) :type hash-table))

(defstruct (plugin
             (:constructor make-plugin (&key name version commands))
             (:conc-name pg-))
  (name "" :type string)
  (version "0.1.0" :type string)
  (commands '() :type list))

;;; ─── Operations ───

(declaim (ftype (function (command-router command-handler) (values command-router &optional))
                router-register!)
         (ftype (function (command-router bot-command) (values t &optional))
                router-dispatch)
         (ftype (function (command-router) (values list &optional))
                router-list-commands)
         (ftype (function (command-router plugin) (values command-router &optional))
                router-load-plugin!))

(defun router-register! (router handler)
  "Register a command handler with the router."
  (declare (type command-router router) (type command-handler handler))
  (setf (gethash (ch-name handler) (cr-handlers router)) handler)
  router)

(defun router-dispatch (router command)
  "Dispatch a command to its handler. Signals command-not-found if unregistered."
  (declare (type command-router router) (type bot-command command))
  (let ((handler (gethash (bc-name command) (cr-handlers router))))
    (unless handler
      (error 'command-not-found :name (bc-name command)))
    (funcall (ch-handler-fn handler) command)))

(defun router-list-commands (router)
  "List all registered command names."
  (declare (type command-router router))
  (let (names)
    (maphash (lambda (k v) (declare (ignore v)) (push k names))
             (cr-handlers router))
    (sort names #'string<)))

(defun router-load-plugin! (router plugin)
  "Load all commands from a plugin into the router."
  (declare (type command-router router) (type plugin plugin))
  (dolist (handler (pg-commands plugin))
    (router-register! router handler))
  router)
