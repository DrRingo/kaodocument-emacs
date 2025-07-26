;;; kaodocument-emacs.el --- Org-mode LaTeX classes for KAODocument (KAOReport/KAOBook) -*- lexical-binding: t; -*-

;; Author: Ringo Stark <binhthanhgo@gmail.com>
;; URL: https://github.com/drringo/kaodocument-emacs
;; Version: 0.2
;; Package-Requires: ((emacs "26.1"))
;; Keywords: org-mode, latex, export, template

;;; Commentary:
;;
;; This package provides custom org-latex-classes for exporting Org-mode documents
;; using the KAODocument LaTeX templates (KAOReport and KAOBook). It also includes helper macros and
;; instructions for using the included LaTeX style/class files.
;;
;; Place the 'templates', 'macros', and 'assets' folders in the same directory as this file.
;;
;; Usage:
;;   (require 'kaodocument-emacs)
;;   (kaodocument-emacs-setup)
;;
;;; Code:

(defgroup kaodocument-emacs nil
  "Org-mode LaTeX classes and templates for KAODocument (KAOReport/KAOBook)."
  :group 'org)

(defconst kaodocument-emacs--repo-dir
  (if (featurep 'straight)
      (straight--repos-dir "kaodocument-emacs")
    (file-name-directory (or load-file-name buffer-file-name))))

(defcustom kaodocument-emacs-template-dir
  (expand-file-name "templates" kaodocument-emacs--repo-dir)
  "Directory containing KAODocument LaTeX templates and Org templates.")

(defcustom kaodocument-emacs-macro-file
  (expand-file-name "macros/kaoreport-macro.org" kaodocument-emacs--repo-dir)
  "Org macro file to insert automatically when exporting.")

;;;###autoload
(defun kaodocument-emacs-setup ()
  "Register KAODocument LaTeX classes (KAOReport and KAOBook) for Org-mode and enable auto-macros."
  (interactive)
  ;; Debug: Print template directory path
  (message "KAODocument template directory: %s" kaodocument-emacs-template-dir)
  (message "KAODocument template directory exists: %s" (file-exists-p kaodocument-emacs-template-dir))
  ;; Create templates directory if it doesn't exist
  (unless (file-exists-p kaodocument-emacs-template-dir)
    (make-directory kaodocument-emacs-template-dir t)
    (message "Created KAODocument template directory: %s" kaodocument-emacs-template-dir))
  ;; KAOReport
  (add-to-list 'org-latex-classes
               '("kaoreport"
                 "\\documentclass[12pt,a4paper]{kaohandt}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  ;; KAOBook
  (add-to-list 'org-latex-classes
               '("kaobook"
                 "\\documentclass[12pt,a4paper]{kaobook}"
                 ("\\part{%s}" . "\\part*{%s}")
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")))
  ;; Enable auto macro/header insertion and template copying
  (add-hook 'org-export-before-processing-hook #'kaodocument-emacs--auto-insert-macros)
  (add-hook 'org-export-before-processing-hook #'kaodocument-emacs--auto-copy-templates)
  (add-hook 'org-export-before-processing-hook #'kaodocument-emacs--auto-insert-org-template))

(defun kaodocument-emacs--auto-insert-macros (_backend)
  "Automatically insert macro file at the top of Org buffer if exporting with KAODocument."
  (when (derived-mode-p 'org-mode)
    (let* ((latex-class-keywords (org-collect-keywords '("LATEX_CLASS")))
           (latex-class (when latex-class-keywords
                          (car (cdr (car latex-class-keywords))))))
      (when (or (string= latex-class "kaoreport")
                (string= latex-class "kaobook"))
        (save-excursion
          (goto-char (point-min))
          (insert-file-contents-literally kaodocument-emacs-macro-file)
          (insert "\n"))))))

(defun kaodocument-emacs--auto-copy-templates (_backend)
  "Copy required .sty/.cls files to the Org file directory if not present."
  (let* ((orgfile (or (buffer-file-name) default-directory))
         (target-dir (file-name-directory orgfile)))
    (when (and kaodocument-emacs-template-dir (file-exists-p kaodocument-emacs-template-dir))
      (let ((files (directory-files kaodocument-emacs-template-dir t "\\.\\(sty\\|cls\\)$")))
        (dolist (f files)
          (let ((dest (expand-file-name (file-name-nondirectory f) target-dir)))
            (unless (file-exists-p dest)
              (copy-file f dest t))))))))

(defun kaodocument-emacs--auto-insert-org-template (_backend)
  "Automatically insert appropriate Org template based on LaTeX class."
  (when (derived-mode-p 'org-mode)
    (let* ((latex-class-keywords (org-collect-keywords '("LATEX_CLASS")))
           (latex-class (when latex-class-keywords
                          (car (cdr (car latex-class-keywords))))))
      (when (and kaodocument-emacs-template-dir (file-exists-p kaodocument-emacs-template-dir))
        (let ((template-file
               (cond
                ((string= latex-class "kaoreport")
                 (expand-file-name "kaoreport-template.org" kaodocument-emacs-template-dir))
                ((string= latex-class "kaobook")
                 (expand-file-name "kaobook-template.org" kaodocument-emacs-template-dir))
                (t nil))))
          (when (and template-file (file-exists-p template-file))
            (save-excursion
              (goto-char (point-min))
              (let ((template-content (with-temp-buffer
                                        (insert-file-contents-literally template-file)
                                        (buffer-string))))
                (let ((lines (split-string template-content "\n" t)))
                  (dolist (line lines)
                    (unless (or (string-match "^#\\+TITLE:" line)
                                (string-match "^#\\+AUTHOR:" line)
                                (string-match "^#\\+DATE:" line)
                                (string-match "^\\* " line)
                                (string-match "^#\\+BEGIN_COMMENT" line)
                                (string-match "^#\\+END_COMMENT" line))
                      (insert line "\n"))))))))))))

(provide 'kaodocument-emacs)
;;; kaodocument-emacs.el ends here

