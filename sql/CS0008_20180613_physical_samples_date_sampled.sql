/****************************************************************************************************************
  Change author
        Roger Mähler, 2018-06-13
  Change description
        Field date_sampled in tbl_physical_samples has type "character varying", should be "timestamp with time zone"
  Risk assessment
    N/A
  Planning
  Change execution and rollback
    Apply this script.
    Steps to verify change: N/A
    Steps to rollback change: N/A
  Change prerequisites (e.g. tests)
  Change reviewer
  Change Approver Signoff
  Notes:
  Impact on dependent modules
    Changes must be propagated to Clearing House
*****************************************************************************************************************/


-- Change code:
ALTER TABLE public.tbl_physical_samples ALTER COLUMN date_sampled TYPE timestamp with time zone;

-- ROLLBACK;


--  NOTES:
--  FK constraint is of "SIMPLE MATCH" which allows NULL FK values i.e. no change needed
