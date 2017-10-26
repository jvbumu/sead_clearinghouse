<?php

namespace Services\Specification {
    
    class SendReminderSignalSpecification extends \Services\ServiceBase {
        
        public function IsSatisfiedBy(&$submission, &$claim_user)
        {

            if ($submission["submission_state_id"] != \Model\Submission::State_InProgress) {
                return false;
            }

            if (ActivityHelper::reminderAlreadySent($submission, $submission["activities"])) {
                return false;
            }

            if (\Model\Submission::daysSinceClaimed($submission) < \InfraStructure\ReminderConfigService::daysUntilFirstReminder()) {
                return false;
            }
            
            if (ActivityHelper::daysSinceActivity($submission, $submission["activities"]) < \InfraStructure\ReminderConfigService::daysUntilFirstReminder()) {
                return false;
            }
            
            return true;
        }       
    }
    
}

