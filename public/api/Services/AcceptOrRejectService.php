<?php

namespace Services {
    
     class AcceptOrRejectService extends ServiceBase {

        public static function Auto_Load_Dummy()
        {
            // Dummy function to force autoload since only derived classes are referenced from outside of file
        }
        
        function getSubmission($submission_id)
        {
            $submission = $this->registry->getSubmissionRepository()->findById($submission_id);
            $submission["rejects"] = $this->registry->getSubmissionRejectRepository()->findBySubmissionId($submission["submission_id"]);
            return $submission;
        }
        
        function execute($submission_id, $user)
        {
            $submission = $this->getSubmission($submission_id);
            if (!$this->getSpecification($user)->IsSatisfiedBy($submission, $user)) {
                return;
            }

            $this->changeState($submission, $user);
            $this->sendSignal($submission, $user);
            
            return $submission;
        }
 
        function sendSignal(&$submission, $user)
        {
            $this->getSignalService()->sendToCandidates($submission, $this->locator->getReceiveAcceptOrRejectSignalSpecification($submission));
        }
        
        function changeState(&$submission, $user)
        {
        }        
        
        function getSpecification($user)
        {
            return null;
        }
    
    }

    class RejectService extends AcceptOrRejectService {

        function changeState(&$submission, $user)
        {
            $this->setRejected($submission);
        }        

        function setRejected(&$submission)
        {
            $submission["submission_state_id"] = \Model\Submission::State_Rejected;
            $this->registry->getSubmissionRepository()->save($submission, array("submission_state_id"));
        }  
        
        function getSpecification($user)
        {
            return $this->locator->getCanRejectSubmissionSpecification($user);
        }

        function getSignalService()
        {
            return $this->locator->getSignalRejectService();
        }
    }
    
    class AcceptService extends AcceptOrRejectService {

        function changeState(&$submission, $user)
        {
            $this->setAccepted($submission);
            $this->transfer($submission);
        }        

        function setAccepted(&$submission)
        {
            $submission["submission_state_id"] = \Model\Submission::State_Accepted;
            //$submission["xml"] = null;
            $this->registry->getSubmissionRepository()->save($submission, array("submission_state_id", "xml"));
            return $submission;
        }

        function transfer($submission, $user)
        {
            $item = $this->registry->getAcceptedQueueRepository()->createNew();
            $item["process_state_id"] = 0;
            $item["submission_id"] = $submission["submission_id"];
            $item["upload_file"] = $submission["upload_content"];
            $item["accept_user_id"] = $user["user_id"];
            $this->registry->getAcceptedQueueRepository()->save($item);
            return $item;
        }
        
        function getSpecification($user)
        {
            return $this->locator->getCanAcceptSubmissionSpecification($user);
        }        
        
        function getSignalService()
        {
            return $this->locator->getSignalAcceptService();
        }
    }

    class SignalAcceptService extends \Services\SignalService
    {
        function __construct() {
            parent::__construct("accept-subject", "accept-body");
        }
    }
    
    class SignalRejectService extends \Services\SignalService
    {
        function __construct() {
            parent::__construct("reject-subject", "reject-body");
        }
        
        function getBody(&$submission, $user)
        {
            $causes = "";
            foreach ($submission["rejects"] as $reject) {
                $cause_values = array(
                    "#SITE-NAME#" => $this->getSiteName($reject["site_id"]),
                    "#ENTITY-TYPE#" => $this->getEntityType($reject["entity_type_id"]),
                    "#ERROR-SCOPE#" => $this->getEntityScope($reject["reject_scope_id"]),
                    "#ENTITY-ID-LIST#" => $this->getEntityIDs($reject),
                    "#ERROR-DESCRIPTION#" => $reject["reject_description"] ?: ""
                );
                $causes .= $this->locator->getMailTemplateService()->getTemplateInstance("reject-cause", $cause_values);
            }
            return $this->locator->getMailTemplateService()->getTemplateInstance("reject-body", array ("#REJECT-CAUSES#" => $causes));
        }

        function getSiteName($site_id)
        {
            try {
                if ($site_id == 0) {
                    return "";
                }
                return $this->registry->getSiteRepository()->findById($site_id)["site_name"];
            } catch (\Exception $ex) {
                return "Site " . strval($site_id);
            }
        }
        
        function getEntityType($entity_type_id)
        {
            try {
                return $this->registry->getSubmissionRejectRepository()->getRejectTypeName($entity_type_id);
            } catch (\Exception $ex) {
                return "?";
            }
        }
        
        function getEntityScope($reject_scope_id)
        {
            try {
                return $this->registry->getSubmissionRejectRepository()->getRejectScopes()[$reject_scope_id];
            } catch (\Exception $ex) {
                return "?";
            }
        }

        function getEntityIDs($reject)
        {
            try {
                return implode(", ", array_map(function ($x) { return $x["local_db_id"]; }, $reject["reject_entities"]));
            } catch (\Exception $ex) {
                return "?";
            }
        }
    }
}

?>