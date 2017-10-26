<?php

namespace Services {

    abstract class SignalService extends ServiceBase
    {
        protected $subject_template = "";
        protected $body_template = "";

        function __construct($subject, $body) {
            parent::__construct();
            $this->subject_template = $subject;
            $this->body_template = $body;
        }
        
        public function send(&$submission, $user)
        {
            $subject = $this->getSubject($submission, $user);
            $body = $this->getBody($submission, $user);
            $this->locator->getMailService()->send($user, $subject, $body);
        }

        public function sendToCandidates($submission, $specification)
        {
            $users = $this->registry->getUserRepository()->findAll();
            foreach ($users as $candidate) {
                if (!$specification->IsSatisfiedBy($candidate)) {
                    continue;
                }
                $this->send($submission, $candidate);
            }
        } 

        function getSubject(&$submission, $user)
        {
            $template_values = $this->getTemplateValues($submission, $user);
            return $this->locator->getMailTemplateService()->getTemplateInstance($this->subject_template, $template_values);
        }        

        function getBody(&$submission, $user)
        {
            $template_values = $this->getTemplateValues($submission, $user);
            return $this->locator->getMailTemplateService()->getTemplateInstance($this->body_template, $template_values);
        }

        function getTemplateValues($submission, $user)
        {
            return array();
        } 
        
    }

}

