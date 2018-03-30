<?php

namespace Repository {

    class DataSetRepositoryConfig {
        static $dataset_model_elements = array(
            //"dataset" => "clearing_house.fn_clearinghouse_review_dataset_client_data",
            "contacts" => "clearing_house.fn_clearinghouse_review_dataset_contacts_client_data",
            "submissions" => "clearing_house.fn_clearinghouse_review_dataset_submissions_client_data",
            "measured_values" => "clearing_house.fn_clearinghouse_review_dataset_measured_values_client_data",
            "abundance_values" => "clearing_house.fn_clearinghouse_review_dataset_abundance_values_client_data",
            "ceramic_values" => "clearing_house.fn_clearinghouse_review_dataset_ceramic_values_client_data"
        );
    }

    class DataSetRepository extends RepositoryBase {

        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "view_datasets", array("submission_id", "dataset_id"), "clearing_house");
            $this->dataset_model_elements = DataSetRepositoryConfig::$dataset_model_elements;
        }

        function getDataSetModel($submission_id, $dataset_id)
        {
            $dataset = $this->getAdapter()->execute_procedure("clearing_house.fn_clearinghouse_review_dataset_client_data",
                array($submission_id, $dataset_id), \InfraStructure\DatabaseConnection::Execute_GetFirst);
            $result =  array(
                "local_db_id" => $this->getKeyValueIfExistsOrDefault($dataset, "local_db_id", 0),
                "entity_type_id" => $this->getKeyValueIfExistsOrDefault($dataset, "entity_type_id", 0),
                "dataset" => $dataset
            );
            foreach ($this->dataset_model_elements as $key => $function_name) {
                $result[$key] = $this->getAdapter()->execute_procedure($function_name, array($submission_id, $dataset_id));
            }
            return $result;
        }

        function NotImplemented()
        {
            return array();
        }

    }

}

?>