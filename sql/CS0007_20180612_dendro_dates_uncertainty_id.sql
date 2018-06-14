/****************************************************************************************************************
  Change author
    Roger Mähler, 2018-06-12
  Change description
    Dendro data has dendro date records with no, or unspecified error uncertainty, which is not possible in current design
    The resolutionos to allow NULL FK for dendro dates i.e. make tbl_dendro_date.error_uncertainty_id nullable
  Risk assessment
    Low risk since the data is new
  Planning
    Low risk
  Change execution and rollback
    Apply this script.
    Steps to verify change: N/A
    Steps to rollback change: N/A
  Change prerequisites (e.g. tests)
  Change reviewer
    Roger Mähler, 2018-06-12
  Change Approver Signoff
    Roger Mähler, 2018-06-12
  Notes:
    FK constraint is of "SIMPLE MATCH" which allows NULL FK values i.e. no change needed
  Impact on dependent modules
    Changes must be propagated to Clearing House
*****************************************************************************************************************/


-- Change code:
ALTER TABLE public.tbl_dendro_dates ALTER COLUMN error_uncertainty_id DROP NOT NULL;

-- ROLLBACK;


--  NOTES:
--  FK constraint is of "SIMPLE MATCH" which allows NULL FK values i.e. no change needed
