<?php

namespace Services\Specification {

class CanAcceptSubmissionSpecification extends \Services\ServiceBase
    {
        function __construct($user = null) {
            parent::__construct();
        }
        
        public function IsSatisfiedBy($submission)
        {
            if ($submission["submission_state_id"] != \Model\Submission::State_InProgress) {
                throw new \InfraStructure\SEAD_Invalid_State_For_Operation_Exception();
            }
            if ($submission["claim_user_id"] != $this->getCurrentUser()["user_id"]) {
                throw new \InfraStructure\SEAD_Operation_Denied_For_User_Exception();
            }
            if (count($submission["rejects"]) > 0) {
                throw new \InfraStructure\SEAD_Exception("Accept operation denied since submission has reject causes");
            }
            return true;
        }
    }
    
}

