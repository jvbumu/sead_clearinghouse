<?php

require_once(__DIR__ . '/../Vendor/PHPMailer/PHPMailerAutoload.php');

namespace Services {
    
    class MailService extends ServiceBase {

        function __construct() {
            global $application;
            $this->config = $application->config['mailer'];
        }
        
        public function Send($subject, $body, $recipient)
        {
            $mail->addReplyTo('list@example.com', 'List manager');
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
            $mail = new PHPMailer();
            $mail->isSMTP();
            $mail->Host = $this->config['smtp-server'];
            $mail->SMTPAuth = $this->config['smtp-auth'];
            $mail->SMTPKeepAlive = true; // SMTP connection will not close after each email sent, reduces SMTP overhead
            $mail->Port = 25;
            if ($this->config['smtp-auth']) {
                $mail->Username = $this->config['smtp-username'];
                $mail->Password = $this->config['smtp-password'];
            }
            return $mail;
        }
        
    }
    
}

?>