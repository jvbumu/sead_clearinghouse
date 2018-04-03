<?php

namespace Services {
    
    class UserService extends ServiceBase {

        function getUsers()
        {
            return $this->registry->getUserRepository()->findAll();
        }
        
        public function getUser($id) {
            return $this->registry->getUserRepository()->findById($id);
        }

        public function deleteById($id) {
            return $this->registry->getUserRepository()->deleteById($id);
        }

        public function saveUser($user) {
            
//            $debug_string = "";
//            foreach ($user as $key => $value) {
//                if (is_null($key))
//                    $key = "null";
//                if (is_null($value))
//                    $value = "null";
//               $debug_string = $debug_string . "Key: $key; Value: $value\n";
//            }
//            throw new \Exception($debug_string);
            
            return $this->registry->getUserRepository()->save($user);
        }
 
        public function getUserRoleTypes() {
            return $this->registry->getUserRepository()->getUserRoleTypes();
        }

        public function getDataProviderGradeTypes() {
            return $this->registry->getUserRepository()->getDataProviderGradeTypes();
        }
    }

}

?>