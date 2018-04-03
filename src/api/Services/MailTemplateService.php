<?php

namespace Services {
    
    class MailTemplateService extends ServiceBase
    {
        function __construct() {
            parent::__construct();
        }
        
        public static function getTemplate($template_key)
        {
            return \InfraStructure\ConfigService::getKeyValue('signal-templates', $template_key, "(template not found)");
        }
        
        static function getTemplateInstance($template_key, $data)
        {
            $text = self::getTemplate($template_key);
            foreach ($data as $key => $value) {
                $text = str_replace($key, $value ?: "", $text);
            }
            return $text;
        }
        
    }
    
}

?>