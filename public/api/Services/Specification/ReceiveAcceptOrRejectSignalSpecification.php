<?php

namespace Services\Specification {

     class ReceiveAcceptOrRejectSignalSpecification extends \Services\ServiceBase
     {
        protected $submission = null;
        function __construct($submission = null) {
            parent::__construct();
            $this->submission = $submission;
        }
        
        public function IsSatisfiedBy($user)
        {
            if ($user["role_id"] == \Model\User::Role_Administrator) {
                return true;
            }
            if ($user["user_id"] == $this->submission["user_id"]) {
                return true;
            }
            if ($user["user_id"] == $this->submission["claim_user_id"]) {
                return true;
            }
            if ($user["email"] == null || $user["email"] == "") {
                return false;
            }
            return $user["signal_receiver"];
        }
     }
    
}

