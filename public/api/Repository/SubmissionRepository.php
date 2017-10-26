<?php
  
namespace Repository {

    class SubmissionRepository extends RepositoryBase {
       
        function __construct(&$conn, $schema_name) {
            parent::__construct($conn, "tbl_clearinghouse_submissions", array("submission_id"), $schema_name, "submission_id");
        }
       
        public function findAllNew()
        {
            return parent::find(array("submission_state_id" => strval(\Model\Submission::State_New)));
        }

        public function findByIdX($id)
        {
            $result = parent::getAdapter()->fetch_all(SubmissionQueryBuilder::getQueryRel(array("submission_id" => $id), false));
            return (count($result) > 0) ? $result[0] : null;
        }

        public function findReport($specification)
        {  
            return parent::getAdapter()->fetch_all(SubmissionQueryBuilder::getQueryRel(array(), FALSE, $specification));
        }
        
        public function processExplodeXML2RDB($id)
        {
            $statement = parent::getAdapter()->prepare('Select clearing_house.fn_explode_submission_xml_to_rdb(?)');
            $statement->bindParam(1, $id, \PDO::PARAM_INT); 
            $result = $statement->execute();
            return $result;
        }

        public function saveError($submission, $message)
        {
            $submission["submission_state_id"] = \Model\Submission::State_Error;
            $submission["status_text"] = $message;
            $this->save($submission, array("submission_state_id", "status_text"));
        }
        
        /*************************************************************************************************************************************
         * Returns hiearchy of objects associated to a submission, the data is displayed in the navigation tree
         *************************************************************************************************************************************/
        public function getSubmissionMetaData($submission_id)
        {
            $data = $this->getAdapter()->query(SubmissionQueryBuilder::getContentReportSql($submission_id))->fetchAll(\PDO::FETCH_ASSOC);
            $datasets = $this->getAdapter()->query(SubmissionQueryBuilder::getSampleGroupDataSetReportSql($submission_id))->fetchAll(\PDO::FETCH_ASSOC);
            
            /* Order the data as hiearchical data  */
            $submission = array();
            $submission["submission_id"] = $submission_id;
            $submission["sites"] = array();
            foreach ($data as $column => $value) {
                $site_id = $value["site_id"];
                if (!key_exists($site_id, $submission["sites"])) {
                    $submission["sites"][$site_id] = array(
                        "submission_id" => $submission_id,
                        "site_id" => $site_id,
                        "site_name" => $value["site_name"],
                        "sample_groups" => array()
                    );
                }
                $site = &$submission["sites"][$site_id];
                $sample_group_id = $value["sample_group_id"];
                if ($sample_group_id == null)
                    continue;
                if (!key_exists($sample_group_id, $site["sample_groups"])) {
                    $site["sample_groups"][$sample_group_id] = array(
                        "submission_id" => $submission_id,
                        "site_id" => $site_id,
                        "sample_group_id" => $sample_group_id,
                        "sample_group_name" => $value["sample_group_name"],
                        "samples" => array(),
                        "datasets" => array_values(array_filter($datasets, function ($x) use ($sample_group_id) { return $x["sample_group_id"] == $sample_group_id; }))
                    );
                }
                $sample_group = &$site["sample_groups"][$sample_group_id];
                $sample_id = $value["physical_sample_id"];
                if ($sample_id == null)
                    continue;
                if (!key_exists($sample_id, $sample_group["samples"])) {
                    $sample_group["samples"][$sample_id] = array(
                        "submission_id" => $submission_id,
                        "site_id" => $site_id,
                        "sample_group_id" => $sample_group_id,
                        "physical_sample_id" => $sample_id,
                        "sample_name" => $value["sample_name"]
                    );
                }

            }

            /* Change associative arrays to indexed arrays (gives JSON arrays instead of JSON objects) */
            $submission["sites"] = array_values($submission["sites"]);
            for ($i = 0; $i < count($submission["sites"]);$i++) {
                $site = &$submission["sites"][$i];
                $site["sample_groups"] = array_values($site["sample_groups"]);
                for ($j = 0; $j < count($site["sample_groups"]); $j++) {
                    $sample_group = &$site["sample_groups"][$j];
                    $sample_group["samples"] = array_values($sample_group["samples"]);
                }
            }
            
            return $submission;
        }
    }

    
    class SubmissionQueryBuilder extends RepositoryBase {

        public static function getQueryRel($filter, $include_data=TRUE, $specification=NULL)
        {   
            $where_clause = "";
            foreach ($filter as $column => $value) {
                $where_clause .= " And $column = " . $value . " ";
            }
            
            if ($specification != NULL) {
                $specification_filter = $specification->toSQL();
                if ($specification_filter <> "") {
                    $where_clause = "(" . $where_clause . ") And $specification_filter";
                }
            }
            
            $sql = "
                Select s.submission_id,
                       s.submission_state_id,
                       s.data_types,
                       to_char(s.upload_date,'YYYY-MM-DD') as upload_date, " .
                       QueryHelper::nullif("s", "upload_content", $include_data) . "," .
                       QueryHelper::nullif("s", "xml", $include_data) . ",
                       s.upload_user_id,
                       s.claim_user_id,
                       c.user_name as claim_user_name,
                       c.full_name as claim_full_name,
                       to_char(s.claim_date_time,'YYYY-MM-DD') claim_date_time,
                       Coalesce(u.user_name, '') as x_user_name,
                       Coalesce(u.full_name, '') as x_full_name,
                       Coalesce(g.description, '') as x_data_provider_grade,
                       Coalesce(x.submission_state_name, '') as x_submission_state_name
                From clearing_house.tbl_clearinghouse_submissions s
                Left Join clearing_house.tbl_clearinghouse_users u
                  On u.user_id = s.upload_user_id
                Left Join clearing_house.tbl_clearinghouse_users c
                  On c.user_id = s.claim_user_id
                Left Join clearing_house.tbl_clearinghouse_submission_states x
                  On x.submission_state_id = s.submission_state_id
                Left Join clearing_house.tbl_clearinghouse_data_provider_grades g
                  On g.grade_id = u.data_provider_grade_id
                Where 1 = 1 " . QueryHelper::generateWhere($filter) . " "
            ;
            
            return $sql;
        }
        
        public static function getContentReportSql($submission_id)
        {
            $sql = '
                    Select s.site_id, s.site_name, g.sample_group_id, g.sample_group_name, v.physical_sample_id, v.sample_name
                    From clearing_house.view_sites s
                    Left Join clearing_house.view_sample_groups g
                      On g.site_id = s.merged_db_id
                    Left Join clearing_house.tbl_physical_samples v
                      On v.sample_group_id = g.merged_db_id
                    Where s.submission_id = ' . strval($submission_id) . '
                    Order By s.site_id, g.sample_group_id, v.physical_sample_id'
                    ;

            return $sql;
        }
        
        public static function getSampleGroupDataSetReportSql($submission_id)
        {           
            $sql = 'Select	g.sample_group_id, d.dataset_id, d.dataset_name, d.data_type_id, Count(*) as v_count
                    From clearing_house.view_sample_groups g
                    Join clearing_house.view_physical_samples v
                      On v.sample_group_id = g.merged_db_id
                     And v.submission_id In (0, g.submission_id)
                    Join clearing_house.view_analysis_entities e
                      On e.physical_sample_id = v.merged_db_id
                     And e.submission_id In (0, g.submission_id)
                    Join clearing_house.view_datasets d
                      On d.merged_db_id = e.dataset_id	
                     And d.submission_id In (0, g.submission_id)
                    Where g.submission_id = ' . strval($submission_id) . '
                    Group By g.sample_group_id, d.dataset_id, d.dataset_name, d.data_type_id
';
            return $sql;
        }
                
        
    }

}

?>