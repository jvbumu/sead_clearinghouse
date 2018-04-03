<?php

namespace Services\Specification {
  
    class ReceiveReclaimSignalSpecification extends \Services\ServiceBase
    {
        public function IsSatisfiedBy($user, $submission)
        {
            if ($user["email"] == null || $user["email"] == "") {
                return false;
            }

            if ($user["role_id"] == \Model\User::Role_Administrator) {
                return true;
            }
            
            if ($user["user_id"] == $submission["claim_user_id"]) {
                return true;
            }
            
            return $user["signal_receiver"];
        }
     }   
}

