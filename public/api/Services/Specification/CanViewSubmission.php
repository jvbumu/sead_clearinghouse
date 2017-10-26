<?php

namespace Services\Specification {

    class CanViewSubmission
    {
        protected $user = null;
        function __construct($user = null) {
            $this->user = $user;
        }
        
        public function IsSatisfiedBy($submission)
        {
            if ($user["role_id"] != \Model\User::Role_Administrator)
                return true;
            if (in_array($user["user_id"], array($submission["upload_user_id"], $submission["claim_user_id"])))
                return true;
            return $submission["submission_state_id"] == \Model\Submission::State_Pending;
        }
        
        // TODO: Implement (a )or use existing) domain level Criteria object (e.g. use ORM framework)
        public function toSQL()
        {
            if ($this->user["role_id"] != \Model\User::Role_Administrator)
                return "";
            $user_id = $this->user["user_id"];
            $pending = \Model\Submission::State_Pending;
            return "(submission_state_id = $pending Or $user_id In (upload_user_id, claim_user_id))";
        }
     }
    
}

