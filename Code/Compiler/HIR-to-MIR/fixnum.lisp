(cl:in-package #:sicl-hir-to-mir)

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-less-instruction) code-object)
  (change-class instruction 'cleavir-ir:signed-less-instruction))

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-not-greater-instruction) code-object)
  (change-class instruction 'cleavir-ir:signed-not-greater-instruction))

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-equal-instruction) code-object)
  (change-class instruction 'cleavir-ir:eq-instruction))

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-add-instruction) code-object)
  (change-class instruction 'cleavir-ir:signed-add-instruction))

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-sub-instruction) code-object)
  (change-class instruction 'cleavir-ir:signed-sub-instruction))

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-logand-instruction) code-object)
  (change-class instruction 'cleavir-ir:bitwise-and-instruction))

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-logior-instruction) code-object)
  (change-class instruction 'cleavir-ir:bitwise-or-instruction))

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-logxor-instruction) code-object)
  (change-class instruction 'cleavir-ir:bitwise-exclusive-or-instruction))

(defmethod process-instruction
    (client (instruction cleavir-ir:fixnum-lognot-instruction) code-object)
  (let ((one (make-instance 'cleavir-ir:constant-input :value 1))
        (temp (make-instance 'cleavir-ir:lexical-location :name (gensym))))
    (cleavir-ir:insert-instruction-before
     (make-instance 'cleavir-ir:bitwise-not-instruction
       :inputs (cleavir-ir:inputs instruction)
       :output temp)
     instruction)
    (change-class instruction 'cleavir-ir:unsigned-sub-instruction
                  :inputs (list temp one))))
