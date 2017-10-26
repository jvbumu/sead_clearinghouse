<?php

namespace Application\Services {
    
    class LoginService extends \Services\ServiceBase
    {
        public function login($userName, $userPassword, $ip = null) {
            try {

                if (!isset($userName) || $userName == ""){
                    throw new \InfraStructure\SEAD_Access_Denied_Exception();
                }

                $session = $this->locator->getSessionService()->login_user($userName, $userPassword, $ip);

                if($session === NULL){
                    throw new \InfraStructure\SEAD_Internal_Error_Exception();
                }
                if($session === false){
                    throw new \InfraStructure\SEAD_Access_Denied_Exception();
                }

                return "<id>" . $session["user_id"] . "<id>";

            } catch (\InfraStructure\SEADException $ex) {
                return "<error>" . $ex.getMessage() . "<error>";
            }
        }
    }
    
}
