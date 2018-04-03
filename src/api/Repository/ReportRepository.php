<?php

namespace Repository {
        
    class ReportRepository extends RepositoryBase {

        function __construct(&$con, $schema_name) {
            parent::__construct($con, "tbl_clearinghouse_reports", array("report_id"), $schema_name);
        }

        function execute($id, $sid)
        {
            try {
                $report = $this->findById($id);
                return $this->executeSql($report["report_procedure"], array($sid));
            } catch (Exception $ex) {
                throw ex;
            }
        }
        
        function getSubmissionTables($sid)
        {
            try {
                $sql = "Select t.table_id, t.table_name
                        From clearing_house.tbl_clearinghouse_submission_xml_content_tables x
                        Join clearing_house.tbl_clearinghouse_submission_tables t
                          On t.table_id = x.table_id
                        Where x.submission_id = $sid
                        Order By t.table_name";
                return $this->getAdapter()->fetch_all($sql);
            } catch (Exception $ex) {
                throw ex;
            }
        }
 
        function getSubmissionTableContent($sid, $tableid)
        {
            try {
                $tablename = $this->getUnderscoredNameFor($tableid);
                $sql = "Select *
                        From clearing_house.$tablename t
                        Where submission_id = $sid
                        Order By local_db_id";
                return $this->executeSql($sql, array());
            } catch (Exception $ex) {
                throw $ex;
            }
        }
 
        function getUnderscoredNameFor($tableid)
        {
            try {
                $sql = "Select table_name_underscored
                        From clearing_house.tbl_clearinghouse_submission_tables t
                        Where table_id = $tableid";
                $result = $this->getAdapter()->fetch_first($sql);
                if ($result == null)
                   throw new \Exception("Unknown table ID $tableid");
                return $result["table_name_underscored"];
            } catch (Exception $ex) {
                throw ex;
            }
        }
        
        function executeSql($sql, $arguments)
        {
            try {
                $statement = $this->con->prepare($sql);
                $statement->execute($arguments);
                $result = $statement->fetchAll(\PDO::FETCH_ASSOC);
                $meta = $this->getMetaData($statement);
                return array(
                    "data" => $result,
                    "columns" => $meta
                );
            } catch (Exception $ex) {
                throw ex;
            }
        }
        
        function getMetaData($statement)
        {
            foreach (range(0, $statement->columnCount() - 1) as $column_index) {
                $meta[] = $statement->getColumnMeta($column_index);
            }
            return $meta;
        }
    }

}

?>