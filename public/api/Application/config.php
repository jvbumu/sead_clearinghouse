<?php
return array(
    'slim' => array(
//        'log.writer' => new \Slim\Extras\Log\DateTimeFileWriter(array(
//            'path' => './logs',
//            'name_format' => 'Y-m-d',
//            'message_format' => '%label% - %date% - %message%'   
//        )),
        'debug' => false
    ),
    'logger' => array(
        'folder' => '/tmp/'
    ),
    //'error_log' => '/tmp/Clearing_House_PHP_ERRORS.log',
    'error_log' => 'C:\temp\Clearing_House_PHP_ERRORS.log',
    'max_execution_time' => 120,
    'mailer' => array(
        'smtp-server' => 'mail.acc.umu.se', //'smtp.example.com',
        'reply-address' => 'noreply@sead.org',
        'sender-name' => 'SEAD Clearing House',
        'reply-address' => 'noreply@sead.org',
        'smtp-auth' => false,
        'smtp-username' => '',
        'smtp-password' => ''
    ),
    'application_key' => 'SEADkey=pCPZyd8JprcXAKaE'
);

?>
