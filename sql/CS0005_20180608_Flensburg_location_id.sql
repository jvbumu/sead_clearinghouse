
Begin Transaction;

Update public.tbl_locations
 	Set location_name = 'Västra Ed' -- Was 'Flensburg'
Where location_id = 3894;

Commit;
