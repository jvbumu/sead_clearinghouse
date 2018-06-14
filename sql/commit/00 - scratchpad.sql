
-- Insert SITES


/* Update existing SITES */
-- REGEL: TILLÅT INTE 

Update p
	Set -- LIST OF UPDATES
From table_sites p_t
Join clearing_house.tbl_sites l_t
  On p_t.site_id = l_t.public_id
Where p.site_id = p_t.site_id
  
Select count(*) From clearing_house.tbl_clearinghouse_submissions
From clearing_house.tbl_sites l_t

/*

1. LOOKUPS HANTERAS I EGET FLÖDE
2. TILLÅT INTE UPPDATERING AV FK?
3. SKAPA ALLTID NYTT DATASET NÄR DATA UPPDATERAS

*/