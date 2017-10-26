<?php

namespace InfraStructure {
    
    class ReminderConfigService {

        public static function getSetting($key, $default)
        {
            return \InfraStructure\ConfigService::getKeyValue('reminder', $key, $default);
        }
        
        public static function daysUntilFirstReminder()
        {
             return self::getKeyValue("days_until_first_reminder", 14);
        }

        public static function daysSinceClaimedUntilTransferBackToPending()
        {
             return self::getKeyValue("days_since_claimed_until_transfer_back_to_pending", 28);
        }

        public static function daysWithoutActivityUntilTransferBackToPending()
        {
             return self::getKeyValue("days_without_activity_until_transfer_back_to_pending", 14);
        }
    } 
}

?>