<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

namespace Application {
        
    class Session {
        
        public static function start(&$user, &$session)
        {
            //session_start();
            
            $user["password"] = "";
            
            $_SESSION["user_id"] = array(
                "session" => $session,
                "user" => $user,
                "session_id" => session_id(),
                "security" => \Services\SecurityService::getSecurityModel($user)
            );
            
            return $_SESSION["user_id"];
        }
        
        public static function stop()
        {
            try {
                unset($_SESSION['user_id']);
                session_unset();
                session_destroy(); 
            } catch (Exception $ex) {
            }
        }
        
        public static function getSessionId()
        {
            return session_id();
        }
        
        public static function getSession()
        {
            return isset($_SESSION["user_id"]) ? $_SESSION["user_id"] : null;
        }
 
        public static function isActive()
        {
            return Session::getSession() && isset($_SESSION["user_id"]);
        }

        public static function getCurrentSession()
        {
            if (Session::isActive()) {
                return Session::getSession()["session"];
            }
            return null;
        }

        public static function getCurrentUser()
        {
            if (Session::isActive()) {
                return Session::getSession()["user"];
            }
            return null;
        }

        
    }
    
}