<?php

namespace Services {
    
    class ActivityService extends ServiceBase {

        Const UseCase_Generic = 0;
		Const UseCase_Login = 1;
		Const UseCase_Logout = 2;
		Const UseCase_Upload_submission = 3;
		Const UseCase_Accept_submission = 4;
		Const UseCase_Reject_submission = 5;
		Const UseCase_Open_submission = 6;
		Const UseCase_Process_submission = 7;
		Const UseCase_Transfer_submission = 8;
		Const UseCase_Add_reject_cause = 9;
		Const UseCase_Delete_reject_cause = 10;
		Const UseCase_Claim_submission = 11;
		Const UseCase_Unclaim_submission = 12;
		Const UseCase_Execute_report = 13;
		Const UseCase_Update_user = 20;
		Const UseCase_Delete_user = 21;
        Const UseCase_Send_Reminder = 22;
        Const UseCase_Reclaim_Submission = 23;
        Const UseCase_Nag = 24;
        Const Activity_State_Pending = 0;
        Const Activity_State_Started = 1;
        Const Activity_State_Stopped = 2;
        Const Activity_State_Error = 9;

        public function commit(&$activity)
        {
            $this->registry->getActivityRepository()->save($activity);
            return $activity;
        }

        // TODO Use injection instead?
        function getCurrentSession()
        {
            return \Application\Session::getCurrentSession();
        }
        
        function getUserId()
        {
            return $this->getCurrentSession() ? $this->getCurrentSession()["user_id"] : 0;
        }

        function getSessionId()
        {
            return $this->getCurrentSession() ? $this->getCurrentSession()["session_id"] : 0;
        }
        
        public function startActivity($use_case_id, $entity_id, $data = null, $entity_type_id = 0)
        {
            $activity = $this->createNew($use_case_id, $this->getUserId(), $this->getSessionId());
            $activity["entity_type_id"] = $entity_type_id;
            $activity["entity_id"] = $entity_id;
            $activity["activity_data"] = $data;
            $this->commit($activity);
            return $activity;
        }
        
        public function stopActivity(&$activity, $status_id = self::Activity_State_Stopped, $message = null)
        {
            $activity["status_id"] = $status_id;
            $activity["execute_stop_time"] = date("Y-m-d H:i:s"); //new \DateTime();
            $activity["message"] = $message ?: $activity["message"];
            $activity["user_id"] = $activity["user_id"] == 0 ? $this->getUserId() : $activity["user_id"];
            $this->commit($activity);
            return $activity;
         }

        public function setError(&$activity, $message)
        {
            $activity["status_id"] = self::Activity_State_Stopped;
            $activity["execute_stop_time"] = date("Y-m-d H:i:s"); //new \DateTime();
            $activity["message"] = $message;
            $this->commit($activity);
            return $activity;
         }
        
        public function createNew($use_case_id = self::UseCase_Generic, $user_id = 0, $session_id = 0, $status_id = self::Activity_State_Started)
        {
            return array(
                "activity_log_id" => 0,
                "use_case_id" => $use_case_id,
                "user_id" => $user_id,
                "entity_type_id" => 0,
                "entity_id" => 0,
                "session_id" => $session_id,
                "execute_start_time" => date("Y-m-d H:i:s"), //new \DateTime(),
                "execute_stop_time" => null,
                "status_id" => $status_id,
                "activity_data" => 0,
                "message" => ""
            );
        }
        
    }
    
}

?>