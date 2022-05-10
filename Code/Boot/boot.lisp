(cl:in-package #:sicl-boot)

(defun boot ()
  (let ((boot (make-instance 'boot
                :e0 (setf *e0* (make-instance 'environment :name "E0"))
                :e1 (setf *e1* (make-instance 'environment :name "E1"))
                :e2 (setf *e2* (make-instance 'environment :name "E2"))
                :e3 (setf *e3* (make-instance 'environment :name "E3"))
                :e4 (setf *e4* (make-instance 'environment :name "E4"))
                :e5 (setf *e5* (make-instance 'environment :name "E5"))
                :ecs (setf *ecs* (make-instance 'environment :name "ECS")))))
    (loop for env in (list *e0* *e1* *e2* *e3* *e4* *e5* *ecs*)
          for client = (env:client env)
          do (reinitialize-instance client
               :environment env))
    (sicl-boot-phase-1:boot boot)
    (sicl-boot-phase-2:boot boot)
    (sicl-boot-phase-3:boot boot)
    (sicl-boot-phase-4:boot boot)
    (sicl-boot-phase-5:boot boot)
    (sicl-boot-phase-6:boot boot)
    (sicl-boot-stealth-mixin:boot boot)
    (sicl-boot-alexandria:boot boot)
    (sicl-boot-trucler:boot boot)
    (sicl-boot-environment:boot boot)
    boot))
