<?php

namespace Repository {
         
    class SignalRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "tbl_clearinghouse_signals", array("signal_id"), "clearing_house", "signal_id");
        }
        
        public function createNew()
        {
            return array(
                'signal_id' => 0,
                'use_case_id' => 0,
                'recipient_user_id' => 0,
                'recipient_adress' => '',
                'signal_time' => date("Y-m-d H:i:s"), //new DateTime(),
                'subject' => "",
                'body' => "",
                'status' => null
            );
        }
    }

}
   
?>