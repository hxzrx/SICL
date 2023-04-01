(cl:in-package #:sicl-expression-to-ast)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting a symbol that has a definition as a symbol macro.

(defmethod convert-with-description
    (client
     cooked-form
     (description trucler:symbol-macro-description)
     environment)
  (let* ((expansion (trucler:expansion description))
         (expander (symbol-macro-expander expansion))
         (raw-expanded-form
           (expand-macro expander cooked-form environment))
         (cooked-expanded-form
           (c:reconstruct raw-expanded-form cooked-form)))
    (setf (c:origin cooked-expanded-form) (c:origin cooked-form))
    (with-preserved-toplevel-ness
      (convert client cooked-expanded-form environment))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting a symbol that has a definition as a constant variable.

(defmethod convert-with-description
    (client
     cooked-form
     (info trucler:constant-variable-description)
     environment)
  (let ((new-cooked-form (c:cook (trucler:value info))))
    (setf (c:origin new-cooked-form) (c:origin cooked-form))
    (convert-constant client new-cooked-form environment)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting a cooked special form.

(defmethod convert-with-description
    (client
     cooked-form
     (info trucler:special-operator-description)
     environment)
  (let ((builder (make-builder client environment)))
    (s-expression-syntax:parse builder t cooked-form)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting a compound form that calls a local macro.
;;; A local macro can not have a compiler macro associated with it.
;;;
;;; If we found a local macro in ENVIRONMENT, it means that
;;; ENVIRONMENT is not the global environment.  And it must be
;;; the same kind of agumentation environment that was used when the
;;; local macro was created by the use of MACROLET.  Therefore, the
;;; expander should be able to handle being passed the same kind of
;;; environment.

(defmethod convert-with-description
    (client
     cooked-form
     (info trucler:local-macro-description)
     environment)
  (let* ((expander (trucler:expander info))
         (raw-expanded-form
           (expand-macro expander cooked-form environment))
         (cooked-expanded-form
           (c:reconstruct raw-expanded-form cooked-form)))
    (setf (c:origin cooked-expanded-form) (c:origin cooked-form))
    (with-preserved-toplevel-ness
      (convert client cooked-expanded-form environment))))
