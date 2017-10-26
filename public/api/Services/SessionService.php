<?php

namespace Services {

   
    /**
     * Transfers NEW submission to PENDING state.
     *
     * Submission in state NEW are processed in the following way:
     * 1) Content is decoded and uncompressed and stored as plain xml (xml type).
     *
     * @category   Submission state transfer
     * @package    Services
     * @author     Roger Mähler <roger.mahler@umu.se>
     * @copyright  2013 SEAD
     * @license    
     * @version    Release: @package_version@
     * @link       
     * @see        
     * @since      
     * @deprecated 
     */
    class SessionService extends ServiceBase {

            public function login_user($username, $password, $ip = null)
            {
                $user = $this->registry->getUserRepository()->findByUsername($username);
                
                if ($user == null) {
                    throw new \InfraStructure\SEAD_Access_Denied_User_Exception($username);
                }
                
                if (!$this->validatePassword($user, $password)) {
                    throw new \InfraStructure\SEAD_Access_Denied_Password_Exception();
                }
                
                $session = $this->registry->getSessionRepository()->create_new($user["user_id"], $ip);
                
                $this->registry->getSessionRepository()->save($session);
                
                $user["is_administrator"] = ($user["role_id"] == 3);
                $user["is_readonly"] = ($user["role_id"] == 1);
                
                $session["user"] = $user;
                
                return $session;
            }
            
            public function validatePassword($user, $password)
            {
                $password_hash = $user["password"];
                return password_verify($password, $password_hash);
                //return $user["password"] == $password; //$this->locator->getEncryptPasswordService()->decode($password);
            }
            
            public function login_session($username, $password, $ip = null)
            {
                try {
                    $session = $this->login_user($username, $password, $ip);
                    $session_data = \Application\Session::start($session["user"], $session);
                    return $session_data;
                } catch (\Exception $ex) {
                    return array("error" => $ex->getMessage(), "exception" => $ex);
                }
            }
            
            public function logout()
            {
                
                $session_data = \Application\Session::getSession();

                if ($session_data != null) {

                    try {
                        
                        $session = $session_data["session"];
                        $session["stop_time"] = \InfraStructure\Utility::Now();

                        $this->registry->getSessionRepository()->save($session, array("stop_time"));
                    
                    } catch (Exception $ex) {
                        
                    }
                    
                }
                \Application\Session::stop();

                return true;
            }
            
    }

}