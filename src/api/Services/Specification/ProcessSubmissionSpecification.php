<?php

namespace Services\Specification {

    class ProcessSubmissionSpecification extends \Services\ServiceBase
    {
        public function IsSatisfiesBy($submission)
        {
            if ($submission["submission_state_id"] != \Model\Submission::State_New)
                throw new \Exception("ProcessSubmissionSpecification: Wrong state");

            return true;
        }
    }
    
}

