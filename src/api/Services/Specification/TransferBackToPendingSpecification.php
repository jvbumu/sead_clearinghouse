<?php

namespace Services\Specification {

    class TransferBackToPendingSpecification extends \Services\ServiceBase {
        
        public function IsSatisfiedBy(&$submission, &$claim_user)
        {
            if ($submission["submission_state_id"] != \Model\Submission::State_InProgress) {
                return false;
            }

            if (\Model\Submission::daysSinceClaimed($submission) < \InfraStructure\ReminderConfigService::daysSinceClaimedUntilTransferBackToPending()) {
                return false;
            }
            
            if (ActivityHelper::daysSinceActivity($submission, $submission["activities"]) < \InfraStructure\ReminderConfigService::daysWithoutActivityUntilTransferBackToPending()) {
                return false;
            }
            
            return true;
        }
    }
    
}

