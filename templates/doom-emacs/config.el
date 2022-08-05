;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(load "~/.doom.d/nix.init.el")

(setq display-line-numbers-type 'absolute)

;; Org directory
(setq org-directory "~/org/")
;; Agenda folder
(setq org-agenda-files '("~/org/inbox.org"))
;; Record time and note when a task is completed
(setq org-log-done 'note)
;; Record time and note when the scheduled date of a task is modified
(setq org-log-reschedule 'note)
;; Record time and note when the deadline of a task is modified
(setq org-log-redeadline 'note)
;; Record time and note when clocking out of a task
(setq org-log-clock-out 'note)
;; Record time when creating new tasks
(setq org-treat-insert-todo-heading-as-state-change t)
;; Always load inline images when opening org files
(setq org-startup-with-inline-images t)

(after! org
  (setq org-todo-keywords
        '(;; Sequence for TASKS
          ;; TODO means it's an item that needs addressing
          ;; WAITING means it's dependent on something else happening
          ;; DELEGATED means someone else is doing it and I need to follow up with them
          ;; ASSIGNED means someone else has full, autonomous responsibility for it
          ;; CANCELLED means it's no longer necessary to finish
          ;; DONE means it's complete
          (sequence "TODO(t@/!)" "WAITING(w@/!)" "DELEGATED(e@/!)" "|" "ASSIGNED(.@/!)" "CANCELLED(x@/!)" "DONE(d@/!)")

          ;; Sequence for POSSESSIONS
          ;; PURCHASE means to buy; it's functionally the wishlist
          ;; PURCHASED means it's been purcahsed, but not shipped yet
          ;; TRANSIT means it's in the mail but not here yet
          ;; GIFT means it's in my posession but I still need to gift it
          ;; SELL means you want to get rid of it, put it up on Craigslist
          ;; LOANED means someone currently has it
          ;; UNWANTED is for no longer wanted
          ;; OWN is for stuff you actually own (may be overlap for reference and own)
          ;; GIFTED is given to someone as a gift
          ;; SOLD is sold to someone
          ;; DISCARDED is for thrown out
          (sequence "PURCHASE(p@/!)" "PURCHASED(j@/!)" "TRANSIT(u@/!)" "GIFT(h@/!)" "SELL(k@/!)" "LOANED(n@/!)" "|" "UNWANTED(a@/!)" "OWN(o@/!)" "GIFTED(g@/!)"  "SOLD(c@/!)" "DISCARDED(q@/!)")

          ;; Sequence for MULTIMEDIA
          ;; CONSUME means to read (articles, books, quote, etc.), play (games), listen (music), or watch (a series or movie)
          ;; SUBSCRIBE means to add it to a newsreader or list of some sort
          ;; CONSUMING means currently consuming
          ;; SHARE means to share on G+, Facebook, reddit, blog about, etc.
          ;; IGNORED means not read and no desire to read in the future
          ;; REFERENCE is for stuff you don't own but want to be available later
          ;; SHARED means sent to someone or posted
          (sequence "CONSUME(r@/!)" "SUBSCRIBE(b@/!)" "CONSUMING(l@/!)" "SHARE(s@/!)" "|" "IGNORED(i@/!)" "REFERENCE(f@/!)" "SHARED(,@/!)")

          ;; Sequence for EVENTS
          ;; VISIT means that there is something you would physically like to do, no dates associated
          ;; DIDNOTGO means the event was cancelled or I didn't go
          ;; MEETING means a real time meeting, i.e. at work, or on the phone for something official
          ;; VISITED means the event took place and is no longer scheduled
          (sequence "VISIT(v@/!)" "|" "DIDNOTGO(z@/!)" "MEETING(m@/!)" "VISITED(y@/!)")))

  (setq org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-include-deadlines t
        org-agenda-block-separator nil
        org-agenda-compact-blocks t
        org-agenda-start-day nil ;; i.e. today
        org-agenda-span 2
        org-agenda-start-on-weekday nil
        org-agenda-use-tag-inheritance nil))

;; Enable non-monospaced fonts on org-mode
(add-hook! 'org-mode-hook 'mixed-pitch-mode)
