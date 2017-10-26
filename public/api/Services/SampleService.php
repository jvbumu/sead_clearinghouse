<?php

namespace Services {
    
    class SampleService extends ServiceBase {

        public function getSampleModel($submission_id, $sample_id)
        {
            return $this->registry->getSampleRepository()->getSampleModel($submission_id, $sample_id);
        }

    }
    
}

?>