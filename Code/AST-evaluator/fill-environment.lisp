(cl:in-package #:sicl-ast-evaluator)

;;; We need to start using DEFMACRO early on to define macros, and
;;; since we don't already have it, we must create it "manually".
;;; This version is incorrect, though, because it uses the host
;;; compiler both to create the macro function for DEFMACRO (which is
;;; fine) and for creating the macro function for the macros defined
;;; by DEFMACRO (which is not fine).  As a result, the macros defined
;;; by this version of DEFMACRO must be defined in the NULL lexical
;;; environment.  Luckily, most macros are, and certainly the ones we
;;; need to define with this version of DEFMACRO until we can replace
;;; it with a native version.
;;;
;;; However, there is a different problem as well.  Since macro
;;; functions may call SICL-ENVIRONMENT:GLOBAL-ENVIRONMENT, it needs
;;; to be defined, but since the host compiler is used, the macro
;;; function is compiled in the null lexical environment, so
;;; SICL-ENVIRONMENT:GLOBAL-ENVIRONMENT is not defined.  To fix that
;;; problem, we wrap the macro body in a lexical definition of it that
;;; returns the run-time environment.
(defun define-defmacro (client environment)
  (setf (env:macro-function client environment 'defmacro)
        (compile nil
                 (cleavir-code-utilities:parse-macro
                  'defmacro
                  '(name lambda-list &body body)
                  `((setf (env:macro-function (env:client ,environment) ,environment name)
                          (compile nil
                                     (cleavir-code-utilities:parse-macro
                                      name
                                      lambda-list
                                      `((flet ((sicl-environment:global-environment (dummy)
                                                 (declare (ignore dummy))
                                                 ,',environment))
                                          (declare (ignorable
                                                    (function sicl-environment:global-environment)))
                                          ,@body))))))))))

;;; Eclector defines macros that are generated by the backquote
;;; facility.  These macros must exist in the global environment
;;; so that they can be expanded by the compiler.

(defun define-backquote-macros (client environment)
  (setf (env:fdefinition client environment 'eclector.reader::expand)
        (fdefinition 'eclector.reader::transform))
  (setf (env:macro-function client environment 'eclector.reader::quasiquote)
        (macro-function 'eclector.reader::quasiquote)))

(defun import-function (client environment function-name)
  (setf (env:fdefinition client environment function-name)
        (fdefinition function-name)))

(defun import-environment-functions (client environment)
  (do-external-symbols (symbol '#:env)
    (when (and (fboundp symbol)
               (null (macro-function symbol))
               (not (special-operator-p symbol)))
      (import-function client environment symbol))
    (when (fboundp `(setf ,symbol))
      (import-function client environment `(setf ,symbol)))))

(defun import-conditionals-support (client environment)
  (import-function client environment 'sicl-conditionals:or-expander)
  (import-function client environment 'sicl-conditionals:and-expander)
  (import-function client environment 'sicl-conditionals:cond-expander)
  (import-function client environment 'sicl-conditionals:case-expander)
  (import-function client environment 'sicl-conditionals:ecase-expander)
  (import-function client environment 'sicl-conditionals:ccase-expander)
  (import-function client environment 'sicl-conditionals:typecase-expander)
  (import-function client environment 'sicl-conditionals:etypecase-expander)
  (import-function client environment 'sicl-conditionals:ctypecase-expander))

(defparameter *standard-function-names*
  '(;; Functions on lists (i.e., from the conses dictionary).
    car cdr rplaca rplacd caar cadr cdar cddr
    caaar caadr cadar caddr cdaar cdadr cddar cdddr
    first second third fourth fifth sixth seventh eighth ninth tenth nth
    rest nthcdr
    cons consp atom null endp
    copy-tree tree-equal sublis nsublis
    subst subst-if subst-if-not nsubst nsubst-if nsubst-if-not
    list list* copy-list list-length listp make-list
    append revappend nreconc last butlast nbutlast
    ldiff tailp
    member member-if member-if-not
    mapc mapcar mapcan mapl maplist mapcon
    acons copy-alist
    assoc assoc-if assoc-if-not rassoc rassoc-if rassoc-if-not
    get-properties
    union nunion
    intersection nintersection
    set-difference nset-difference
    set-exclusive-or nset-exclusive-or
    adjoin subsetp
    ;; Sequence functions.
    copy-seq elt fill make-sequence subseq length
    map map-into reduce reverse nreverse sort stable-sort merge
    search replace mismatch concatenate
    count count-if count-if-not
    find find-if find-if-not
    position position-if position-if-not
    substitute substitute-if substitute-if-not
    nsubstitute nsubstitute-if nsubstitute-if-not
    remove remove-if remove-if-not
    delete delete-if delete-if-not
    remove-duplicates delete-duplicates
    ;; Functions on numbers
    = /= < > <= >=
    + - * / 1+ 1-
    min max abs evenp oddp exp expt gcd lcm
    minusp plusp zerop numberp realp rationalp integerp
    floor ffloor ceiling fceiling truncate ftruncate round fround mod rem
    ash integer-length
    logand logandc1 logandc2 lognand
    logior logorc1 logorc2 lognor logxor
    lognot logbitp logcount logtest
    byte byte-size byte-position
    deposit-field dpb ldb ldb-test mask-field
    ;; Data and Control Flow
    apply funcall
    not eq eql equal equalp identity complement constantly
    every some notevery notany
    values values-list
    ;; Symbols
    symbolp keywordp
    make-symbol copy-symbol gensym symbol-name symbol-package
    ;; Printer
    format write prin1 print pprint princ
    write-to-string prin1-to-string princ-to-string
    ;; Misc
    coerce))

(defun import-standard-functions (client environment)
  (loop for function-name in *standard-function-names*
        do (import-function client environment function-name)))

(defun import-cleavir-primops (client environment)
  (setf (sicl-environment:special-operator
         client environment 'cleavir-primop:multiple-value-call)
        '(:special-operator t)))

(defun load-file (relative-filename environment)
  (let ((*package* *package*)
        (filename (asdf:system-relative-pathname
                   '#:sicl relative-filename)))
    (sicl-source-tracking:with-source-tracking-stream-from-file
        (stream filename)
      (let ((first-form (eclector.reader:read stream nil nil)))
        (unless (eq (first first-form) 'in-package)
          (error "File must start with an IN-PACKAGE form."))
        (setf *package* (find-package (second first-form))))
      (loop with eof-marker = (list nil)
            for cst = (eclector.concrete-syntax-tree:read stream nil eof-marker)
            until (eq cst eof-marker)
            do (eval cst environment)))))

(defun host-load (relative-filename)
  (let ((filename (asdf:system-relative-pathname
                   '#:sicl relative-filename)))
    (load filename)))

(defun define-function-global-environment (client environment)
  ;; This function is used by macros in order to find the current
  ;; global environment.  If no argument is given, the run-time
  ;; environment (or startup environment) is returned.  If a macro
  ;; supplies an argument, and then it will typically be the
  ;; environment given to it by the &ENVIRONMENT parameter, then
  ;; the compilation environment is returned.  Macros use this
  ;; function to find information that is truly global, and that
  ;; Trucler does not manage, such as compiler macros. type
  ;; definitions, SETF expanders, etc.
  (setf (env:fdefinition
         client
         environment
         ;; There has got to be an easier way to define the
         ;; package so that it exists before this system is
         ;; compiled.
         'sicl-environment:global-environment)
        (lambda (&optional env)
          (if (null env)
              environment
              (trucler:global-environment client env)))))

(defun import-code-utilities (client environment)
  (import-function client environment 'cleavir-code-utilities:parse-macro)
  (import-function client environment 'cleavir-code-utilities:lambda-list-type-specifier)
  (import-function client environment 'cleavir-code-utilities:separate-function-body))

(defun import-trucler-functions (client environment)
  (import-function client environment 'trucler:describe-function)
  (import-function client environment 'trucler:describe-variable)
  (import-function client environment 'trucler:expansion)
  (import-function client environment 'trucler:symbol-macro-expansion)
  (import-function client environment 'trucler:expander)
  (import-function client environment 'trucler:macro-function))

(defun fill-environment (environment)
  (let ((client (env:client environment)))
    (define-defmacro client environment)
    (define-backquote-macros client environment)
    (import-environment-functions client environment)
    (import-standard-functions client environment)
    (import-cleavir-primops client environment)
    (import-code-utilities client environment)
    (import-trucler-functions client environment)
    (import-conditionals-support client environment)
    (import-function client environment 'error)
    (import-function client environment 'typep)
    (flet ((ld (relative-file-name)
             (format *trace-output* "Loading file ~a~%" relative-file-name)
             (load-file relative-file-name environment)))
      (host-load "Evaluation-and-compilation/packages.lisp")
      (host-load "Data-and-control-flow/packages.lisp")
      (define-function-global-environment client environment)
      ;; Load a file containing a definition of the macro LAMBDA.
      ;; This macro is particularly simple, so it doesn't really
      ;; matter how it is expanded.  This is fortunate, because at the
      ;; time this file is loaded, the definition of DEFMACRO is still
      ;; one we created "manually" and which uses the host compiler to
      ;; compile the macro function in the null lexical environment.
      ;; We define the macro LAMBDA before we redefine DEFMACRO as a
      ;; target macro because PARSE-MACRO returns a LAMBDA form, so we
      ;; need this macro in order to redefine DEFMACRO.
      (ld "Evaluation-and-compilation/lambda.lisp")
      ;; Load a file containing the definition of the macro
      ;; MULTIPLE-VALUE-BIND.  We need it early because it is used in the
      ;; expansion of SETF, which we also need early for reasons explained
      ;; below.
      (ld "Data-and-control-flow/multiple-value-bind-defmacro.lisp")
      ;; Load a file containing definitions of standard conditional
      ;; macros, such as AND, OR, CASE, etc.
      (ld "Conditionals-Clostrum/macros.lisp")
      ;; Load a file containing a definition of the macro SETF.  We
      ;; need the SETF macro early, because it is needed in order to
      ;; define the macro DEFMACRO.  The reason for that, is that the
      ;; expansion of DEFMACRO uses SETF to set the macro function.
      ;; We could have defined DEFMACRO to call (SETF MACRO-FUNCTION)
      ;; directly, but that would have been less "natural", so we do
      ;; it this way instead.
      (ld "Data-and-control-flow-Clostrum/setf-defmacro.lisp")
      ;; At this point, we have all the ingredients (the macros LAMBDA
      ;; and SETF) in order to redefine the macro DEFMACRO as a native
      ;; macro.  SINCE we already have a primitive form of DEFMACRO,
      ;; we use it to define DEFMACRO.  The result of loading this
      ;; file is that all new macros defined subsequently will have
      ;; their macro functions compiled with the target compiler.
      ;; However, the macro function of DEFMACRO is still compiled
      ;; with the host compiler.
      (ld "Evaluation-and-compilation-Clostrum/defmacro-defmacro.lisp")
      ;; As mentioned above, at this point, we have a version of
      ;; DEFMACRO that will compile the macro function of the macro
      ;; definition using the target compiler.  However, the macro
      ;; function of the macro DEFMACRO itself is still the result of
      ;; using the host compiler.  By loading the definition of
      ;; DEFMACRO again, we fix this "problem".
      (ld "Evaluation-and-compilation-Clostrum/defmacro-defmacro.lisp")
      ;; Up to this point, the macro function of the macro LAMBDA was
      ;; compiled using the host compiler.  Now that we have the final
      ;; version of the macro DEFMACRO, we can reload the file
      ;; containing the definition of the macro LAMBDA, which will
      ;; cause the macro function to be compiled with the target
      ;; compiler.
      (ld "Evaluation-and-compilation/lambda.lisp")
      ;; Similarly, the macro MULTIPLE-VALUE-BIND was compiled using
      ;; the host compiler.  By loading this file again, we will
      ;; compile the macro function again, this time with the target
      ;; compiler.
      (ld "Data-and-control-flow/multiple-value-bind-defmacro.lisp")
      ;; Similarly, the macros for conditional were compiled using the
      ;; host compiler.  By loading this file again, we will compile
      ;; those macro functions again, this time with the target
      ;; compiler.
      (ld "Conditionals-Clostrum/macros.lisp")
      ;; Load a file containing the definition of the macro
      ;; MULTIPLE-VALUE-LIST.  This definition is needed, because it
      ;; is used in the expansion of the macro NTH-VALUE loaded below.
      (ld "Data-and-control-flow/multiple-value-list-defmacro.lisp")
      ;; We define MULTIPLE-VALUE-CALL as a macro.  This macro expands
      ;; to a primop that takes a function, rather than a function
      ;; designator, as its first argument.
      (ld "Data-and-control-flow/multiple-value-call-defmacro.lisp")
      (ld "Data-and-control-flow-Clostrum/setf-defmacro.lisp")
      (host-load "Data-and-control-flow-Clostrum/defun-support.lisp")
      (import-function
       client environment 'sicl-data-and-control-flow:defun-expander)
      ;; Load a file containing the definition of macro DEFUN.
      (ld "Data-and-control-flow-Clostrum/defun-defmacro.lisp")
      ;; Load a file containing definition of function
      ;; GET-SETF-EXPANSION.  We can not use the version of this
      ;; function provided by the host, because it takes an
      ;; environment argument, and the host version does not work with
      ;; the Cleavir/SICL environment objects.
      ;; FIXME: check whether this one is actually used by macro expanders.
      (ld "Data-and-control-flow-Clostrum/get-setf-expansion-defun.lisp")
      (ld "Data-and-control-flow-Clostrum/defconstant-defmacro.lisp")
      (ld "Data-and-control-flow-Clostrum/defvar-defmacro.lisp")
      (ld "Data-and-control-flow-Clostrum/defparameter-defmacro.lisp")
      (ld "Evaluation-and-compilation/macroexpand-hook-defparameter.lisp")
      (ld "Evaluation-and-compilation-Clostrum/macroexpand-1-defun.lisp")
      (host-load "Evaluation-and-compilation/declaim-support.lisp")
      (import-function
       client environment 'sicl-evaluation-and-compilation:declaim-expander)
      (ld "Evaluation-and-compilation/declaim-defmacro.lisp"))))
