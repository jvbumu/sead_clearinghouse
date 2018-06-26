<?php

namespace Services {

    class ReportService extends ServiceBase {

        function getReports()
        {
            return $this->registry->getReportRepository()->findAll();
        }

        function is_crosstab_result($columns)
        {
            $last_column = array_values(array_slice($columns, -1))[0];
            return (isset($last_column['column_field']) && $last_column['column_field'] == 'json_data_values');
        }

        // TODO: Must make this a safer ID??
        function to_undercored($label)
        {
            $result = trim($label);
            $result = \str_replace(':', '', $result);
            $result = \str_replace(' ', '_', $result);
            return trim($result);
        }

        function executeReport($id, $sid)
        {
            $data = $this->registry->getReportRepository()->execute($id, $sid);
            $values = $data["data"];
            $columns = ReportColumnsBuilder::createReviewTableColumns($data["columns"]);
            if ($this->is_crosstab_result($columns)) {
                $crosstab_column_discarded = array_pop($columns);
                if (count($values) > 0) {
                    $crosstab_row_values = json_decode(end($values[0]));
                    foreach ($crosstab_row_values as $x) {
                        $column_name = $this->to_undercored($x[0]);
                        $columns[] = array(
                            "column_name" => $x[0],
                            "column_field" => $column_name,
                            "data_type" => $x[1],
                            "public_column_field" => 'public_' . $column_name
                        );
                    }
                }
                foreach ($values as $key => $value) {
                    $crosstab_row_values = json_decode(array_pop($value));
                    foreach ($crosstab_row_values as $x) {
                        $column_name = $this->to_undercored($x[0]);
                        $values[$key][$column_name] = $x[2];
                        $values[$key]['public_' . $column_name] = $x[3];
                    }
                }
            }
            $result = array (
                "data" => $values,
                "columns" => $columns,
                "options" => array (
                    "paginate" => true
                )
            );

            return $result;
        }

        function getSubmissionTables($sid)
        {
            return $this->registry->getReportRepository()->getSubmissionTables($sid);
        }

        function getSubmissionTableContent($sid, $tableid)
        {
            $data = $this->registry->getReportRepository()->getSubmissionTableContent($sid, $tableid);

            $result = array (
                "data" => $data["data"],
                "columns" => ReportColumnsBuilder::createReviewTableColumns($data["columns"], false),
                "options" => array (
                    "paginate" => true
                )
            );
            return $result;

        }

    }

    class ReportColumnsBuilder
    {
        public static function createDataTablesColumns($columns)
        {
             return  array_map(
                        function ($x) {
                            return array(
                                "column_name" => $x["name"],
                                "data_type" => $x["native_type"]
                            );
                        },
                    $columns
            );
        }

        public static function createReviewTableColumns($columns, $ignore_id_columns = true)
        {
            $review_columns = array();
            $column_names = \array_map(function ($x) { return $x["name"]; }, $columns);
            foreach ($columns as $column) {
                if (\InfraStructure\Utility::startsWith($column["name"], "public_")) {
                    continue;
                }
                if ($ignore_id_columns && \InfraStructure\Utility::endsWith($column["name"], "_id")) {
                    continue;
                }
                $column_data = array();
                $column_data["column_name"] = \InfraStructure\Utility::toCamelCase($column["name"], true, true);
                $column_data["column_field"] = $column["name"];
                $column_data["data_type"] = $column["native_type"];
                $public_name = "public_" . $column["name"];
                if (in_array ($public_name, $column_names)) {
                    $column_data["public_column_field"] = $public_name;
                }
                $review_columns[] = $column_data;
            }

            return $review_columns;
        }


    }
}
