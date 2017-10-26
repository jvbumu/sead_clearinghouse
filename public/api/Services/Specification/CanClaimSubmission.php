<?php

namespace Services\Specification {

    class CanClaimSubmission
    {
        public function IsSatisfiedBy($submission, $user)
        {
            if ($submission["submission_state_id"] != \Model\Submission::State_Pending)
                throw new \Exception("Only pending submissions can be claimed");
            if ($user["role_id"] != \Model\User::Role_Normal && $user["role_id"] != \Model\User::Role_Administrator)
                throw new \Exception("Only user roles Normal and Administrator can claim a submission");
            return true;
        }
    }
    
}

