
var SecurityFunctions = {

    fn_user_has_claimed_submission: function(submission)
    {
        return (SEAD.User && (submission.get("claim_user_id") == SEAD.User.user_id));
    },

    fn_submission_is_new: function(submission)
    {
        return submission.get("submission_state_id") === 1;
    },

    fn_submission_is_in_progress: function(submission)
    {
        return submission.get("submission_state_id") === 3;
    },

    fn_submission_is_pending: function(submission)
    {
        return submission.get("submission_state_id") === 2;
    },

    fn_can_open_submission: function(submission)
    {
        if (!this.has_view_submission_privilage)
            return false;

        if (this.fn_user_has_claimed_submission(submission))
            return true;

        return !this.fn_submission_is_new(submission);
    },

    fn_can_edit_submission: function(submission)
    {
        if (!submission)
            return false;

        if (!this.has_edit_submission_privilage)
            return false;

        if (!this.fn_submission_is_in_progress(submission))
            return false;

        return this.fn_user_has_claimed_submission(submission);
    },

    fn_can_claim_submission: function(submission)
    {
        return submission && this.has_claim_submission_privilage && this.fn_submission_is_pending(submission);
    },

    fn_can_unclaim_submission: function(submission)
    {
        return submission && this.has_unclaim_submission_privilage && (this.fn_user_has_claimed_submission(submission) || this.user_is_administrator) && this.fn_submission_is_in_progress(submission);
    },

    fn_can_transfer_submission: function(submission)
    {
        return submission && this.has_transfer_submission_privilage && this.user_is_administrator && this.fn_submission_is_in_progress(submission);
    },

    fn_can_accept_submission: function(submission, reject_causes)
    {
        return this.fn_can_edit_submission(submission) && this.has_accept_submission_privilage && reject_causes.length == 0;
    },

    fn_can_reject_submission: function(submission, reject_causes)
    {
        return this.fn_can_edit_submission(submission) && this.has_reject_submission_privilage && reject_causes.length > 0;
    },

    fn_can_add_reject_cause: function(submission)
    {
        return this.fn_can_edit_submission(submission) && this.has_add_reject_cause_privilage;
    }


};

export default SecurityFunctions;
