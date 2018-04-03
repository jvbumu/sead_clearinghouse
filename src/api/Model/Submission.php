<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

namespace Model {

    /**
     * Description of Submission
     *
     * @author roma0050
     */
    class Submission extends \Model\EntityBase {

        Const State_Undefined = 0;
        Const State_New = 1;
        Const State_Pending = 2;
        Const State_InProgress = 3;
        Const State_Accepted = 4;
        Const State_Rejected = 5;
        Const State_Error = 9;

        function __construct(&$propertyBag) {
            parent::__construct($propertyBag);
        }
        
        public static function daysSinceClaimed(&$submission)
        {
            try {
                return floor(time() - $submission["claim_date_time"]) / (3600.0 * 24.0);
            } catch (\Exception $ex) {
                return 0;
            }
        }

        public static function getIdentifier(&$submission)
        {
            return strval($submission["submission"]);
        }
        
        public static function reminderAlreadySent(&$submission, &$activities)
        {
            return count(array_filter($activities,
                function ($x) use ($submission)
                {
                    return $x["use_case_id"] == \Services\ActivityService::UseCase_Send_Reminder &&
                           $x["execute_start_time"] > $submission["claim_date_time"] &&
                           $x["user_id"] == $submission["claim_user_id"];
                }
            )) > 0;
            
        }

        public static function getLastActivityDate(&$submission, &$activities)
        {
            try {
                $date = null;
                if (count($activities) == 0) {
                    return $date;
                }
                
                foreach ($activities as $activity) {
                    if ($activity["user_id"] == $submission["claim_user_id"]) {
                        if ($date == null || $activity["execute_start_time"] > $date) {
                            $date = $activity["execute_start_time"];
                        }
                    }
                }
                return $date;
            } catch (\Exception $ex) {
                return null;
            }
        }

        public static function daysSinceActivity(&$submission, &$activities)
        {
            try {
                $date = self::getLastActivityDate($submission, $activities);
                if ($date == null) {
                    return null;
                }
                return floor(time() - $date) / (3600.0 * 24.0);
            } catch (\Exception $ex) {
                return null;
            }
        }
        
    }

}