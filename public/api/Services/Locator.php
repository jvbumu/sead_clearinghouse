<?php

namespace Services {

    class Locator
    {
 
        protected $service_store = array();

        public function getService($class_name)
        {
            if (!array_key_exists($class_name, $this->service_store)) {
                $this->service_store[$class_name] = new $class_name();
            }
            return $this->service_store[$class_name];
        }
        
        public function locate($class_name)
        {
            return $this->getService($class_name);
        }
        
        public function getXmlDecoder()
        {
            return $this->locate("\Services\DecodeService");
        }
        
        public function getProcessor()
        {
            return $this->locate("\Services\ProcessService");
        }
        
        public function getXmlExploder()
        {
            return $this->locate("\Services\ExplodeXmlSubmissionService");
        }
        
        public function getSiteService()
        {
            return $this->locate("\Services\SiteService");
        }
        
        public function getUserService()
        {
            return $this->locate("\Services\UserService");
        }

        public function getReportService()
        {
            return $this->locate("\Services\ReportService");
        }

        public function getSubmissionService()
        {
            return $this->locate("\Services\SubmissionService");
        }
        
        public function getTransferService()
        {
            return $this->locate("\Services\TransferService");
        }
        
        public function getSampleGroupService()
        {
            return $this->locate("\Services\SampleGroupService");
        }
        
        public function getSampleService()
        {
            return $this->locate("\Services\SampleService");
        }
        
        public function getSessionService()
        {
            return $this->locate("\Services\SessionService");
        }
        
        public function getSecurityService()
        {
            return $this->locate("\Services\SecurityService");
        }
        
        public function getActivityService()
        {
            return $this->locate("\Services\ActivityService");
        }
        
        public function getMailDispatcher()
        {
            return $this->locate("\InfraStructure\MailService");
        }
                
        public function getMailService()
        {
            return $this->locate("\Services\MailService");
        }

        public function getDataSetService()
        {
            return $this->locate("\Services\DataSetService");
        }

        public function getRejectService()
        {
            \Services\AcceptOrRejectService::Auto_Load_Dummy();
            return $this->locate("\Services\RejectService");
        }

        public function getAcceptService()
        {
            \Services\AcceptOrRejectService::Auto_Load_Dummy();
            return $this->locate("\Services\AcceptService");
        }
        
        public function getSignalRejectService()
        {
            return $this->locate("\Services\SignalRejectService");
        }
        
        public function getSignalAcceptService()
        {
            return $this->locate("\Services\SignalAcceptService");
        }
        
        public function getMailTemplateService()
        {
            return $this->locate("\Services\MailTemplateService");
        }
        
        public function getReminderService()
        {
            return $this->locate("\Services\ReminderService");
        }

        public function getReclaimService()
        {
            return $this->locate("\Services\ReclaimService");
        }
        
        public function getSignalReminderService()
        {
            return $this->locate("\Services\SignalReminderService");
        }
        
        public function getSignalReclaimService()
        {
            return $this->locate("\Services\SignalReclaimService");
        } 
        
        public function getEncryptService()
        {
            return $this->locate("\Services\EncryptService");
        } 

        // public function getEncryptPasswordService()
        // {
        //     return $this->locate("\Services\EncryptPasswordService");
        // } 
        
        public function getReceiveReclaimSignalSpecification()
        {
            return $this->locate("\Services\Specification\ReceiveReclaimSignalSpecification");
        } 
 
        public function getTransferBackToPendingSpecification()
        {
            return $this->locate("\Services\Specification\TransferBackToPendingSpecification");
        } 
        
        public function getSendReminderSignalSpecification()
        {
            return $this->locate("\Services\Specification\SendReminderSignalSpecification");
        } 

        public function getCanAcceptSubmissionSpecification()
        {
            return $this->locate("\Services\Specification\CanAcceptSubmissionSpecification");
        } 

        public function getCanRejectSubmissionSpecification()
        {
            return $this->locate("\Services\Specification\CanRejectSubmissionSpecification");
        }
        
        public function getReceiveAcceptOrRejectSignalSpecification()
        {
            return $this->locate("\Services\Specification\ReceiveAcceptOrRejectSignalSpecification");
        }
        
        public function getCanSendMailToUserSpecification()
        {
            return $this->locate("\Services\Specification\CanSendMailToUserSpecification");
        }
        
        public function getCanProcessSubmissionSpecification()
        {
            return $this->locate("\Services\Specification\ProcessSubmissionSpecification");
        }       
        
        public function getCanViewSubmission()
        {
            return $this->locate("\Services\Specification\CanViewSubmission");
        }
        
        public function getCanClaimSubmission()
        {
            return $this->locate("\Services\Specification\CanClaimSubmission");
        }

        public function getCanUnclaimSubmission()
        {
            return $this->locate("\Services\Specification\CanUnclaimSubmission");
        }
        
        public function getCanTransferSubmission()
        {
            return $this->locate("\Services\Specification\CanTransferSubmission");
        }
        
        
    }
}
?>