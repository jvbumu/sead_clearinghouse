<?php

namespace Services\Specification {

    class CanSendMailToUserSpecification extends \Services\ServiceBase {

        public function isSatisfiedBy($user) {
            try {

                if (!$user["signal_receiver"]) {
                    throw new \Exception("User cannot receive signals");
                }

                if ($user["email"] == null) {
                    throw new \Exception("User's email address is unknown");
                }

                if (!filter_var($user["email"], FILTER_VALIDATE_EMAIL)) {
                    throw new \Exception("User's email address is not valid");
                }

                return true;
            } catch (\Exception $ex) {
                throw new $ex;
            }
        }

    }
    
}

