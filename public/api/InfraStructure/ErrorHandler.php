<?php

namespace InfraStructure {

    class ErrorHandler {

        public static function setup()
        {
            ini_set('error_reporting', -1);
            ini_set('html_errors', false);
//            ini_set('display_errors', 1);
            ini_set('display_errors',\E_ALL & ~\E_NOTICE & ~\E_STRICT & ~\E_DEPRECATED);
            ini_set('log_errors', 1);

            $config = \InfraStructure\ConfigService::getConfig();
            ini_set('error_log', '/tmp/Clearing_House_PHP_ERRORS.log');
            //ini_set('error_log', 'C:\temp\Clearing_House_PHP_ERRORS.log');

            set_exception_handler(
                function ($exception)
                {
                    throw $exception;
                }
            );
        }



    }
}

?>
