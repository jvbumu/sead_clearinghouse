<?php

namespace Services {
    
    class TransferService extends ServiceBase {
 
        function claim($submission_id)
        {
            $user = $this->getCurrentUser();
            return $this->setUser($submission_id, $user,
                array(
                    "claim_user_id" => $user["user_id"],
                    "claim_date_time" => \InfraStructure\Utility::Now(),
                    "submission_state_id" => \Model\Submission::State_InProgress
                ),
                $this->locator->getCanClaimSubmission()
            );
        }
        
        function unclaim($submission_id)
        {           
            $user = $this->getCurrentUser();
            return $this->setUser($submission_id, $user,
                array(
                    "claim_user_id" => null,
                    "claim_date_time" => null,
                    "submission_state_id" => \Model\Submission::State_Pending
                ),
                $this->locator->getCanUnclaimSubmission()
            );
        }

        function transfer($submission_id, $receive_user_id)
        {
            $receiver = $this->registry->getUserRepository()->findById($receive_user_id);
            return $this->setUser($submission_id, $this->getCurrentUser(),
                array(
                    "claim_user_id" => $receiver["user_id"],
                    "claim_date_time" => \InfraStructure\Utility::Now(),
                    "submission_state_id" => \Model\Submission::State_InProgress
                ),
                $this->locator->getCanTransferSubmission()
            );
        }
        
                
        function setUser($submission_id, $user, $values, $specification)
        {           
            $submission = $this->registry->getSubmissionRepository()->findById($submission_id);
            if (!$specification->IsSatisfiedBy($submission, $user)) {
                return;
            }
            foreach ($values as $key => $value) {
                $submission[$key] = $value;                
            }
            $this->registry->getSubmissionRepository()->save($submission, array_keys($values));
            return $this->registry->getSubmissionRepository()->findByIdX($submission_id);
        }
 
        
    }

}

?>