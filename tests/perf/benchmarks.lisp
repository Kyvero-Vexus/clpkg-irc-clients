;;; benchmarks.lisp — performance benchmarks + budget verification

(load "/home/slime/projects/clpkg-irc-clients/src/net/connection.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/events.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/commands.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/client.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/history.lisp")
(load "/home/slime/projects/clpkg-irc-clients/src/client/multi.lisp")

(use-package :clpkg-irc-clients/net)
(use-package :clpkg-irc-clients/events)
(use-package :clpkg-irc-clients/commands)
(use-package :clpkg-irc-clients/client)
(use-package :clpkg-irc-clients/history)
(use-package :clpkg-irc-clients/multi)

(defun ms-since (start)
  (/ (- (get-internal-real-time) start)
     (/ internal-time-units-per-second 1000.0)))

(defvar *pass* 0)
(defvar *fail* 0)

(defun budget-check (name elapsed-ms budget-ms)
  (if (<= elapsed-ms budget-ms)
      (progn (incf *pass*)
             (format t "PASS ~A: ~,2fms (budget ~Dms)~%" name elapsed-ms budget-ms))
      (progn (incf *fail*)
             (format t "FAIL ~A: ~,2fms exceeds budget ~Dms~%" name elapsed-ms budget-ms))))

;; B1: Command formatting throughput — 10k commands, budget 100ms
(let ((t0 (get-internal-real-time)))
  (dotimes (_ 10000)
    (format-join "#test")
    (format-privmsg "bob" "hello")
    (format-nick "newnick"))
  (budget-check "format-30k-commands" (ms-since t0) 100))

;; B2: Event dispatch — 10k events to 5 listeners, budget 200ms
(let* ((d (make-event-dispatcher))
       (t0 nil))
  (dotimes (_ 5)
    (register-listener d :message (lambda (ev) (declare (ignore ev)) nil)))
  (setf t0 (get-internal-real-time))
  (dotimes (_ 10000)
    (dispatch-event d (make-irc-event :kind :message :payload "test")))
  (budget-check "dispatch-10k-events-5-listeners" (ms-since t0) 200))

;; B3: Rate limiter check throughput — 100k checks, budget 100ms
(let ((rl (make-rate-limiter :window-s 3600 :max-messages 100000 :window-start 0))
      (t0 (get-internal-real-time)))
  (dotimes (i 100000)
    (rate-limit-check rl i))
  (budget-check "rate-limit-100k-checks" (ms-since t0) 100))

;; B4: History push throughput — 10k entries, budget 100ms
(let ((buf (make-history-buffer :capacity 1000))
      (t0 (get-internal-real-time)))
  (dotimes (i 10000)
    (history-push! buf (make-history-entry
                        :source "alice" :message (format nil "msg-~D" i) :timestamp i)))
  (budget-check "history-push-10k" (ms-since t0) 200))

;; B5: History search — 1000 entries, budget 50ms
(let ((buf (make-history-buffer :capacity 1000)))
  (dotimes (i 1000)
    (history-push! buf (make-history-entry
                        :source "alice" :message (format nil "message number ~D about lisp" i) :timestamp i)))
  (let ((t0 (get-internal-real-time)))
    (history-search buf "lisp")
    (budget-check "history-search-1000" (ms-since t0) 50)))

;; B6: Client connect/disconnect cycle — 1000 cycles, budget 100ms
(let ((c (make-irc-client :nick "perf" :user "perf" :realname "Perf" :host "localhost" :port 6667))
      (t0 nil))
  (clpkg-irc-clients/client::%ensure-init c "localhost" 6667 nil)
  (setf t0 (get-internal-real-time))
  (dotimes (_ 1000)
    (client-connect! c)
    (client-disconnect! c))
  (budget-check "connect-disconnect-1k-cycles" (ms-since t0) 100))

;; B7: Multi-server add/get — 100 servers, budget 50ms
(let ((mgr (make-server-manager))
      (t0 (get-internal-real-time)))
  (dotimes (i 100)
    (manager-add! mgr (format nil "server-~D" i)
                  (make-irc-client :nick "x" :user "x" :realname "x" :host "x")))
  (dotimes (i 100)
    (manager-get mgr (format nil "server-~D" i)))
  (budget-check "multi-add-get-100-servers" (ms-since t0) 50))

;; B8: Channel join/part cycle — 1000 channels, budget 100ms
(let ((c (make-irc-client :nick "perf" :user "perf" :realname "Perf" :host "localhost" :port 6667))
      (t0 (get-internal-real-time)))
  (dotimes (i 1000)
    (client-join! c (format nil "#chan-~D" i)))
  (dotimes (i 1000)
    (client-part! c (format nil "#chan-~D" i)))
  (budget-check "join-part-1k-channels" (ms-since t0) 100))

(format t "~%BENCHMARK RESULTS: ~D/~D within budget~%" *pass* (+ *pass* *fail*))
(assert (= 0 *fail*))
(sb-ext:exit :code 0)
