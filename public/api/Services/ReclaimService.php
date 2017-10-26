<?php

namespace Services {

    class ReclaimService extends ServiceBase
    {
        public function execute($submission, $user)
        {
            $this->setPending($submission);
            $this->sendSignal($submission);
        }
        
        function setPending(&$submission)
        {
            $submission["submission_state_id"] = \Model\Submission::State_Pending;
            $this->registry->getSubmissionRepository()->save($submission, array("submission_state_id"));
        } 
        
        function sendSignal(&$submission)
        {
            $this->locator->getSignalReclaimService()->sendToCandidates($submission, $this->locator->getReceiveReclaimSignalSpecification());
        } 
        
    }

    class SignalReclaimService extends \Services\SignalService
    {
        
        function __construct() {
            parent::__construct("reclaim-subject", "reclaim-body");
        }
        
        function getTemplateValues($submission, $user)
        {
            return array(
                "#SUBMISSION-ID#" => \Model\Submission::getIdentifier($submission),
                "#DAYS-UNTIL-RECLAIM#" => \InfraStructure\ReminderConfigService::daysSinceClaimedUntilTransferBackToPending(),
                "#DAYS-WITHOUT-ACTIVITY#" => \InfraStructure\ReminderConfigService::daysWithoutActivityUntilTransferBackToPending()
            );
        }        
    }
    
}

