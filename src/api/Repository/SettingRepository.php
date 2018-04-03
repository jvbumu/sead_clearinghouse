<?php

namespace Repository {
         
    class SettingRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "tbl_clearinghouse_settings", array("setting_id"), "clearing_house", "setting_id");
        }
        
        function getInfoReferences()
        {
            return $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_info_references", array());
        }
                
    }

}
   
?>