(cl:in-package #:sicl-hir-to-cl)

(defun make-code-bindings (initial-instruction context)
  (let ((enter-instructions (sort-functions initial-instruction)))
    (loop for enter-instruction in (butlast enter-instructions)
          collect `(,(gethash enter-instruction (function-names context))
                    ,(translate-enter-instruction enter-instruction context)))))

(defun hir-to-cl (initial-instruction)
  (let ((enter-instructions (sort-functions initial-instruction))
        (context (make-instance 'context))
        (lexical-locations (find-lexical-locations initial-instruction))
        (successor (first (cleavir-ir:successors initial-instruction)))
        (*static-environment-variable* (gensym "temp")))
    (loop for enter-instruction in (butlast enter-instructions)
          do (setf (gethash enter-instruction (function-names context))
                   (gensym "code")))
    `(lambda (xxx)
       (let (,@(make-code-bindings initial-instruction context)
             ,(mapcar #'cleavir-ir:name lexical-locations))
         (tagbody ,@(translate successor context))))))
