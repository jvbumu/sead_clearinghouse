<?php

namespace Services {
    
    class SubmissionService extends ServiceBase {

        static function __classLoad() {
        }
        
        function getSubmissions()
        {
            return $this->registry->getSubmissionRepository()->findAll();
        }

        function getSubmission($id)
        {
            return $this->registry->getSubmissionRepository()->findById($id);
        }

        function getSubmissionSites($submission_id)
        {
            return $this->registry->getSiteRepository()->findBySubmissionId($submission_id);
        }
        
        function getSubmissionRejects($submission_id)
        {
            return $this->registry->getSubmissionRejectRepository()->findBySubmissionId($submission_id);            
        }
        
        function saveSubmissionReject($id, &$entity)
        {
            return $this->registry->getSubmissionRejectRepository()->save($entity);            
        }

        function deleteSubmissionReject($submission_reject_id)
        {
            return $this->registry->getSubmissionRejectRepository()->deleteById($submission_reject_id);            
        }

        function getRejectTypes()
        {
            return $this->registry->getSubmissionRejectRepository()->getRejectTypes();            
        }
        
        function getSubmissionsReport()
        {
            return $this->registry->getSubmissionRepository()->findReport($this->locator->getCanViewSubmission($this->getCurrentUser()), false);
        }
        
        function getSubmissionMetaData($submission_id)
        {
            return $this->registry->getSubmissionRepository()->getSubmissionMetaData($submission_id);            
        }
        
    }
}

?>