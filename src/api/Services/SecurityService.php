<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

namespace Services {

    class SecurityService extends ServiceBase {

        public static function getDefaultSecurityModel()
        {
            return array(
                "user_is_administrator" => false,
                "user_is_readonly" => false,
                "user_is_normal" => false,
                "user_is_data_provider" => false,
                
                "has_view_submission_privilage" => false,
                "has_edit_submission_privilage" => false,
                "has_accept_submission_privilage" => false,
                "has_reject_submission_privilage" => false,
                "has_claim_submission_privilage" => false,
                "has_unclaim_submission_privilage" => false,
                "has_transfer_submission_privilage" => false,
                "has_add_reject_cause_privilage" => false,
                "has_edit_reject_cause_privilage" => false,
                "has_delete_reject_cause_privilage" => false,
                "has_edit_user_privilage" => false
            );
        }

        public static function getSecurityModel($user)
        {
            $model = SecurityService::getDefaultSecurityModel();
            
            if ($user == null) {
                return $model;
            }
            
            $model["user_is_administrator"] = $user["role_id"] == \Model\User::Role_Administrator;
            $model["user_is_readonly"] = $user["role_id"] == \Model\User::Role_Reader;
            $model["user_is_normal"] = $user["role_id"] == \Model\User::Role_Normal;
            $model["user_is_undefined_role"] = $user["role_id"] == \Model\User::Role_Undefined;
            $model["user_is_data_provider"] = $user["is_data_provider"];
            
            $model["has_view_submission_privilage"] = !$model["user_is_undefined_role"];
            $model["has_edit_submission_privilage"] = $model["user_is_normal"] || $model["user_is_administrator"];
            $model["has_accept_submission_privilage"] = $model["user_is_normal"] || $model["user_is_administrator"];
            $model["has_reject_submission_privilage"] = $model["user_is_normal"] || $model["user_is_administrator"];
            $model["has_claim_submission_privilage"] = $model["user_is_normal"] || $model["user_is_administrator"];
            $model["has_unclaim_submission_privilage"] = $model["user_is_normal"] || $model["user_is_administrator"];
            $model["has_transfer_submission_privilage"] = $model["user_is_administrator"];
            $model["has_add_reject_cause_privilage"] = $model["has_edit_submission_privilage"];
            $model["has_edit_reject_cause_privilage"] = $model["has_edit_submission_privilage"];
            $model["has_delete_reject_cause_privilage"] = $model["has_edit_submission_privilage"];
            $model["has_edit_user_privilage"] = $model["user_is_administrator"];
            
            return $model;
        }

    }


}