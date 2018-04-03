<?php

namespace InfraStructure {
    
    require_once(__DIR__ . '/../Vendor/PHPMailer/PHPMailerAutoload.php');

    class MailService {

        function __construct() {
            global $application;
            $this->config = $application->config['mailer'];
        }
        
        public function send($subject, $body, $recipient)
        {
            $mail = $this->createMailer();
            $mail->addReplyTo($this->config['reply-address'], $this->config['sender-name']);
            $mail->setFrom($this->config['reply-address'], $this->config['sender-name']);
            $mail->addAddress($recipient, $recipient);
            $mail->Subject = $subject;
            $mail->Body = $body;
            //send the message, check for errors
            if (!$mail->send()) {
                throw new \Exception($mail->ErrorInfo);
            }
        }
        
        function createMailer()
        {
            $mail = new \PHPMailer();
            if ($this->config['smtp-server']) {
                $mail->isSMTP();
                $mail->Host = $this->config['smtp-server'];
                $mail->SMTPAuth = $this->config['smtp-auth'];
                $mail->SMTPKeepAlive = false; 
                if ($this->config['smtp-auth']) {
                    $mail->Username = $this->config['smtp-username'];
                    $mail->Password = $this->config['smtp-password'];
                }
            }
            $mail->Port = 25;
            return $mail;
        }
        
    }
    
}

?>