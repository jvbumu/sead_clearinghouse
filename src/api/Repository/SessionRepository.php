<?php

namespace Repository {
         
    class SessionRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "tbl_clearinghouse_sessions", array("session_id"), "clearing_house", "session_id");
        }
        
        public static function create_new($user_id, $ip)
        {
            return array(
                "session_id" => 0,
                "user_id" => $user_id,
                "ip" => $ip,
                "start_time" => (new \DateTime('NOW'))->format('c'),
                "stop_time" => null              
            );
        }
    }

}
   
?>