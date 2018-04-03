<?php

namespace Services {
    
    class MailService extends ServiceBase {

        public function send($user, $subject, $body) {
            try {

                if (!$this->locator->getCanSendMailToUserSpecification()->isSatisfiedBy($user)) {
                    return false;
                }

                $dispatcher = new \InfraStructure\MailService();
                $dispatcher->send($subject, $body, $user["email"]);
                $status = "SENT";
            } catch (\Exception $ex) {
                $status = "ERROR: " + $ex->getMessage();
            }

            return $this->register($user, $subject, $body, $status);
        }

        public function register($user, $subject, $body, $status) {
            try {
                $signal = $this->registry->getSignalRepository()->createNew();
                $signal["subject"] = $subject;
                $signal["body"] = $body;
                $signal["recipient_user_id"] = $user["user_id"];
                $signal["recipient_address"] = $user["email"];
                $signal["status"] = $status;
                $this->registry->getSignalRepository()->save($signal);
                return $signal;
            } catch (\Exception $ex) {
                return null;
            }
        }

    }

  
}

?>