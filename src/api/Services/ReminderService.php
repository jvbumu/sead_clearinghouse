<?php

namespace Services {

   
    class ReminderService extends ServiceBase
    {
        public function sendReminder($submission, $user)
        {
            $this->locator->getSignalReminderService()->send($submission, $user);
        } 
    }
    
    class SignalReminderService extends \Services\SignalService
    {
        
        function __construct() {
            parent::__construct("reminder-subject", "reminder-body");
        }
        
        function getTemplateValues($submission, $user)
        {
            return array(
                "#SUBMISSION-ID#" => \Model\Submission::getIdentifier($submission),
                "#DAYS-UNTIL-REMINDER#" => \InfraStructure\ReminderConfigService::daysUntilFirstReminder()
            );
        }        
    }
    
}

