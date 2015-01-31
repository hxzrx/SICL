(cl:in-package #:sicl-extrinsic-environment)

(defun fill-environment (environment)
  (import-host-packages environment)
  (import-from-host-common-lisp environment)
  (import-from-sicl-global-environment environment)
  (import-from-sicl-conditionals environment)
  (import-from-cleavir-code-utilities environment)
  (import-from-cleavir-environment environment)
  (import-loop-support environment)
  (define-backquote-macros environment)
  (define-defmacro environment)
  (define-in-package environment)
  (define-default-setf-expander environment)
  ;; Load a file containing a definition of the macro LAMBDA.  This
  ;; macro is particularly simple, so it doesn't really matter how it
  ;; is expanded.  This is fortunate, because that the time this file
  ;; is loaded, the definition of DEFMACRO is still one we created
  ;; "manually" and which uses the host compiler to compile the macro
  ;; function in the null lexical environment.  We define the macro
  ;; LAMBDA before we redefine DEFMACRO as a target macro because
  ;; PARSE-MACRO returns a LAMBDA form, so we need this macro in order
  ;; to redefine DEFMACRO.
  (load-file "../../Evaluation-and-compilation/lambda.lisp" environment)
  ;; Load a file containing the definition of the macro
  ;; MULTIPLE-VALUE-BIND.  We need it early because it is used in the
  ;; expansion of SETF, which we also need early for reasons explained
  ;; below.
  (load-file "../../Environment/multiple-value-bind.lisp" environment)
  ;; Load a file containing a definition of the macro SETF. Recall
  ;; that, at this point, the definition of DEFMACRO is still the one
  ;; that we created "manually".  We need the SETF macro early,
  ;; because it is needed in order to define the macro DEFMACRO.  The
  ;; reason for that, is that the expansion of DEFMACRO uses SETF to
  ;; set the macro function.  We could have defined DEFMACRO to call
  ;; (SETF MACRO-FUNCTION) directly, but that would have been less
  ;; "natural", so we do it this way instead.
  (load "../../Data-and-control-flow/setf.lisp" environment)
  ;; At this point, we have all the ingredients (the macros LAMBDA and
  ;; SETF) in order to redefine the macro DEFMACRO as a native macro.
  ;; SINCE we already have a primitive form of DEFMACRO, we use it to
  ;; define DEFMACRO.  The result of loading this file is that all new
  ;; macros defined subsequently will have their macro functions
  ;; compiled with the target compiler.  However, the macro function of
  ;; DEFMACRO is still compiled with the host compiler.
  (load "../../Environment/defmacro-defmacro.lisp" environment)
  ;; As mentioned above, at this point, we have a version of DEFMACRO
  ;; that will compile the macro function of the macro definition using
  ;; the target compiler.  However, the macro function of the macro
  ;; DEFMACRO itself is still the result of using the host compiler.
  ;; By loading the definition of DEFMACRO again, we fix this
  ;; "problem".
  (load "../../Environment/defmacro-defmacro.lisp" environment)
  ;; Now that have the final version of the macro DEFMACRO, we can
  ;; load the target version of the macro IN-PACKAGE.
  (load "../../Environment/in-package.lisp" environment)
  ;; Up to this point, the macro function of the macro LAMBDA was
  ;; compiled using the host compiler.  Now that we have the final
  ;; version of the macro DEFMACRO, we can reload the file containing
  ;; the definition of the macro LAMBDA, which will cause the macro
  ;; function to be compiled with the target compiler.
  (load "../../Evaluation-and-compilation/lambda.lisp" environment)
  ;; Load a file containing the definition of the macro
  ;; MULTIPLE-VALUE-LIST.  This definition is needed, because it is
  ;; used in the expansion of the macro NTH-VALUE loaded below.
  (load "../../Data-and-control-flow/multiple-value-list.lisp" environment)
  ;; Load a file containing the definition of the macro NTH-VALUE.
  ;; This definition is needed by the function CONSTANTP which is
  ;; loaded as part of the file standard-environment-functions.lisp
  ;; loaded below.
  (load "../../Data-and-control-flow/nth-value.lisp" environment)
  ;; Load a file containing the definition of macro DEFUN.
  (load "../../Environment/defun-defmacro.lisp" environment))
