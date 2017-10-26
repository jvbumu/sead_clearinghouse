<?php

namespace InfraStructure {
     
    use Monolog\Logger;
    use Monolog\Handler\AbstractProcessingHandler;

    class PDOHandler extends AbstractProcessingHandler
    {
        private $initialized = false;
        private $pdo;
        private $statement;

        public function __construct($pdo, $level = Logger::DEBUG, $bubble = true)
        {
            $this->pdo = $pdo;
            parent::__construct($level, $bubble);
        }

        protected function write(array $record)
        {
            echo json_encode($record);
            
            if (!$this->initialized) {
                $this->initialize();
            }

            $this->statement->execute(array(
                'channel' => $record['channel'],
                'level' => $record['level'],
                'message' => $record['formatted'],
                'extra' => json_encode($record['extra']),
                'time' => $record['datetime']->format('U'),
            ));
        }

        private function initialize()
        {
            $this->pdo->exec('
                    Create Table If Not Exists clearing_house.tbl_clearinghosue_error_log (
                        channel character varying(255),
                        level int,
                        message text,
                        extra text null,
                        time int)
                '
            );
            $this->statement = $this->pdo->prepare(
                'Insert Into clearing_house.tbl_clearinghosue_error_log (channel, level, message, extra, time)
                    Values (:channel, :level, :message, :extra, :time)'
            );

            $this->initialized = true;
        }
    }

    class Log {

        protected $logger;

        public function __construct($pdo, $config)
        {
            $this->logger = new \Monolog\Logger('SEAD');
            $this->logger->pushHandler(new \InfraStructure\PDOHandler($pdo));
            $log_file_name = $config['folder'] . '\SEAD_CH-log-' . php_sapi_name() . '.txt';
            //$this->logger->pushHandler(new \Monolog\Handler\StreamHandler($log_file_name, \Monolog\Logger::WARNING));
        }
        
        public function addInfo($msg)
        {
            $this->logger->addInfo($msg);
        }

        public function addError($msg)
        {
            $this->logger->addError($msg);
        }

        public function addWarning($msg)
        {
            $this->logger->addWarning($msg);
        }

        function addException($ex)
        {
            //mail('me@domain.com', 'May day!', json_encode(compact('errno', 'errstr', 'errfile', 'errline')));
            $this->logger->addError($ex.getMessage());
        }
        
    }
    
    
}
