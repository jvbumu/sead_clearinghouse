<?php

namespace InfraStructure {

    class SEADException extends \Exception
    {
        public function __construct($message, $code = 0, Exception $previous = null) {
            parent::__construct($message, $code, $previous);
        }
        
        public static function assertLoaded()
        {
        }
        
    }

    class SEAD_Access_Denied_Exception extends \Exception
    {
        public function __construct($message = null, $code = 0, \Exception $previous = null) {
            parent::__construct($message ?: "Access is denied (wrong password)", $code, $previous);
        }
    }

    class SEAD_Access_Denied_User_Exception extends \Exception
    {
        public function __construct($user_name, $code = 0, \Exception $previous = null) {
            parent::__construct("Access denied (unknown user)", $code, $previous);
        }
    }
    
    class SEAD_Access_Denied_Password_Exception extends \Exception
    {
        public function __construct($code = 0, \Exception $previous = null) {
            parent::__construct("Access denied (Wrong password)", $code, $previous);
        }
    }
    
    class SEAD_Internal_Error_Exception extends \Exception
    {
        public function __construct($message = null, $code = 0, \Exception $previous = null) {
            parent::__construct(($message !== null ? $message : "Interna error"), $code, $previous);
        }
    }
    
    class SEAD_Invalid_State_For_Operation_Exception extends \Exception
    {
        public function __construct($message = "Submission state not valid for operation", $code = 0, \Exception $previous = null) {
            parent::__construct(($message !== null ? $message : "Interna error"), $code, $previous);
        }
    }
    
    class SEAD_No_Such_Submission extends \Exception {
        
        public function __construct($message = "No such submission", $code = 0, $previous = null) {
            parent::__construct($message, $code, $previous);
        }
    }
    
    class SEAD_Submission_Not_Validated extends \Exception {
        
        public function __construct($message = "Submission is not validated completely", $code = 0, $previous = null) {
            parent::__construct($message, $code, $previous);
        }
    }
}