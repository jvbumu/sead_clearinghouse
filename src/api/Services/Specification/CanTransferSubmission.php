<?php

namespace Services\Specification {

    class CanTransferSubmission
    {
        public function IsSatisfiedBy($submission, $user, $to_user)
        {
            if ($submission["submission_state_id"] != \Model\Submission::State_Pending && $submission["submission_state_id"] != \Model\Submission::State_InProgress)
                throw new \Exception("Only pending or submissions in progress can be transfered");
            
            if ($user["role_id"] != \Model\User::Role_Administrator)
                throw new \Exception("Only administrators can transfer a submission to other user");
            
            return true;
        }
    }
    
}

