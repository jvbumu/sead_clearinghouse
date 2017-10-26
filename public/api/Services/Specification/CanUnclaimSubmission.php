<?php

namespace Services\Specification {

    class CanUnclaimSubmission
    {
        public function IsSatisfiedBy($submission, $user)
        {
            if ($submission["submission_state_id"] != \Model\Submission::State_InProgress)
                throw new \Exception("Only in-progress submissions can be un-claimed");

            if ($user["role_id"] == \Model\User::Role_Administrator)
                return true;

            if ($submission["claim_user_id"] != $user["user_id"])
                throw new \Exception("Only claimee can un-claime submission");
            
            return true;
        }
    }
    
}

