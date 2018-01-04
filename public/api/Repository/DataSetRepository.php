<?php

namespace Repository {
        
    class DataSetRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "view_datasets", array("submission_id", "dataset_id"), "clearing_house");
        }
       
 
        function getDataSetModel($submission_id, $dataset_id)
        {

            $dataset = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_dataset_client_data", array($submission_id, $dataset_id), \InfraStructure\DatabaseConnection::Execute_GetFirst);
            $contacts = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_dataset_contacts_client_data", array($submission_id, $dataset_id));
            $submissions = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_dataset_submissions_client_data", array($submission_id, $dataset_id));

            $measured_values = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_dataset_measured_values_client_data", array($submission_id, $dataset_id));
            $abundance_values = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_dataset_abundance_values_client_data", array($submission_id, $dataset_id));
            //$ceramic_values = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_dataset_ceramic_values_client_data", array($submission_id, $dataset_id));
            
            // FIXME: Specific analysis entity types should be configurable i.e. not hard-coded (measured_values etc)
            $result =  array(
                "local_db_id" => $this->getKeyValueIfExistsOrDefault($dataset, "local_db_id", 0),
                "entity_type_id" => $this->getKeyValueIfExistsOrDefault($dataset, "entity_type_id", 0),
                "dataset" => $dataset,
                "contacts" => $contacts,
                "submissions" => $submissions,
                "measured_values" => $measured_values,
                "abundance_values" => $abundance_values //,
                // "ceramic_values" => $ceramic_values
            );
            
            return $result;
        }
        
        function NotImplemented()
        {
            return array();
        }
        
    }


}

?>