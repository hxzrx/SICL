(cl:in-package #:asdf-user)

(defsystem :sicl-conditions
  :serial t
  :components
  ((:file "packages")
   (:file "support")
   (:file "debugger-hook-defparameter")
   (:file "condition-class-defclass")
   (:file "report-mixin-defclass")
   (:file "condition-defclass")
   (:file "define-condition-support")
   (:file "define-condition-defmacro")
   (:file "Portable-condition-system/condition-hierarchy")
   (:file "check-type-defmacro")
   (:file "Portable-condition-system/restart-defclass")
   (:file "Portable-condition-system/restarts-utilities")
   (:file "Portable-condition-system/restarts")
   (:file "Portable-condition-system/handlers-utilities")
   (:file "Portable-condition-system/handlers")
   (:file "make-condition-defgeneric")
   (:file "make-condition-defmethods")
   (:file "Portable-condition-system/coerce-to-condition")))
