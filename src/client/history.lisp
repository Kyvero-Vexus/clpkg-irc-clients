;;; history.lisp --- ring buffer message history per channel

(defpackage #:clpkg-irc-clients/history
  (:use #:cl)
  (:export
   #:history-buffer #:history-buffer-p #:make-history-buffer
   #:hb-capacity #:hb-entries #:hb-count
   #:history-entry #:history-entry-p #:make-history-entry
   #:he-source #:he-target #:he-message #:he-timestamp
   #:history-push! #:history-entries #:history-search))

(in-package #:clpkg-irc-clients/history)

(defstruct (history-entry
             (:constructor make-history-entry (&key source target message timestamp))
             (:conc-name he-))
  (source "" :type string)
  (target "" :type string)
  (message "" :type string)
  (timestamp 0 :type integer))

(defstruct (history-buffer
             (:constructor make-history-buffer (&key (capacity 1000)))
             (:conc-name hb-))
  (capacity 1000 :type fixnum)
  (entries '() :type list)
  (count 0 :type fixnum))

(declaim (ftype (function (history-buffer history-entry) (values history-buffer &optional)) history-push!)
         (ftype (function (history-buffer &key (:limit fixnum)) (values list &optional)) history-entries)
         (ftype (function (history-buffer string) (values list &optional)) history-search))

(defun history-push! (buffer entry)
  (declare (type history-buffer buffer) (type history-entry entry))
  (push entry (hb-entries buffer))
  (incf (hb-count buffer))
  (when (> (hb-count buffer) (hb-capacity buffer))
    (setf (hb-entries buffer) (butlast (hb-entries buffer)))
    (decf (hb-count buffer)))
  buffer)

(defun history-entries (buffer &key (limit 50))
  (declare (type history-buffer buffer) (type fixnum limit))
  (subseq (hb-entries buffer) 0 (min limit (hb-count buffer))))

(defun history-search (buffer query)
  "Search history for entries containing query substring."
  (declare (type history-buffer buffer) (type string query))
  (let ((lower-q (string-downcase query)))
    (remove-if-not (lambda (e)
                     (search lower-q (string-downcase (he-message e)) :test #'char=))
                   (hb-entries buffer))))
