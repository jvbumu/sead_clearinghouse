
CREATE OR REPLACE FUNCTION clearing_house.fn_clearinghouse_report_sample_group_descriptions(
	integer)
RETURNS TABLE(local_db_id integer, sample_group_id integer, sample_group_name character varying, type_name character varying, description text, date_updated text, public_db_id integer, public_sample_group_id integer, public_sample_group_name character varying, public_type_name character varying public_description text, entity_type_id integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$

Declare
    entity_type_id int;

Begin

	entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_group_descriptions');
	
	Return Query
		Select	LDB.local_db_id								As local_db_id,
				LDB.sample_group_id							As sample_group_id,
                LDB.sample_group_name						As sample_group_name,
                LDB.type_name								As type_name,
                LDB.group_description						As description,
				to_char(LDB.date_updated,'YYYY-MM-DD')		As date_updated,

				LDB.public_db_id							As public_db_id,

				RDB.sample_group_id							As public_sample_group_id,
				RDB.sample_group_name						As public_sample_group_name,
				RDB.type_name								As public_type_name,
				RDB.group_description						As public_description,

				entity_type_id								As entity_type_id

		From (	
		
				Select	sgd.submission_id			As submission_id,
              			sgd.local_db_id				As local_db_id,
              			sgd.public_db_id			As public_db_id,
              			sgd.source_id				As source_id,
              			sgd.sample_group_id			As sample_group_id,
              			sg.sample_group_name		As sample_group_name,
						sgdt.type_name				As type_name,
						sgd.group_description		As group_description,
              			sgd.date_updated			As date_updated
				

			From 	clearing_house.view_sample_group_descriptions sgd
					Join clearing_house.view_sample_group_description_types sgdt
					  On sgdt.merged_db_id = sgd.sample_group_description_type_id
					 And sgdt.submission_id In (0, sgdt.submission_id)
        			Join clearing_house.view_sample_groups sg
       	  	  	  	  On sg.merged_db_id = sgd.sample_group_id
         	 	 	 And sg.submission_id In (0, sg.submission_id)) As LDB

		Left Join (
			
			Select 	sg.sample_group_id					As sample_group_id, 
					sgd.sample_group_description_id		As sample_group_description_id,
					sg.sample_group_name 				As sample_group_name,
					sgdt.type_name						As type_name,
					sgd.group_description				As group_description

			From 	public.tbl_sample_groups sg
					Join public.tbl_sample_group_descriptions sgd
					  On sgd.sample_group_id = sg.sample_group_id
					Join public.tbl_sample_group_description_types sgdt
					  On sgdt.sample_group_description_type_id = sgd.sample_group_description_type_id) as RDB
					  
		On RDB.sample_group_description_id = LDB.public_db_id
		
		Where LDB.source_id = 1
		  And LDB.submission_id = $1

		Order by sample_group_id;

End 
$BODY$;

ALTER FUNCTION clearing_house.fn_clearinghouse_report_sample_group_descriptions(integer)
    OWNER TO clearinghouse_worker;



*fn_clearinghouse_report_sample_descriptions*

CREATE OR REPLACE FUNCTION clearing_house.fn_clearinghouse_report_sample_descriptions(
	integer)
RETURNS TABLE(local_db_id integer, physical_sample_id integer, sample_name character varying, type_name character varying, description text, date_updated text, public_db_id integer,  public_physical_sample_id integer, public_sample_name character varying, public_type_name character varying, public_description text, entity_type_id integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$

Declare
    entity_type_id int;

Begin

	entity_type_id := clearing_house.fn_get_entity_type_for('tbl_sample_descriptions');

	Return Query
		Select	
				LDB.local_db_id						                As local_db_id,
				LDB.physical_sample_id						        As physical_sample_id,
        		LDB.sample_name										As sample_name,
        		LDB.type_name										As type_name,
        		LDB.description										As description,
				to_char(LDB.date_updated,'YYYY-MM-DD')				As date_updated,

				LDB.public_db_id									As public_db_id,

				RDB.physical_sample_id						        As public_physical_sample_id,
				RDB.sample_name										As public_sample_name,
				RDB.type_name										As public_type_name,
				RDB.description										As public_description,

				entity_type_id						                As entity_type_id
		From (
			Select	sd.submission_id							As submission_id,
					sd.local_db_id								As local_db_id,
					sd.public_db_id								As public_db_id,
					sd.source_id								As source_id,
					sd.physical_sample_id						As physical_sample_id,
					ps.sample_name								As sample_name,
					sdt.type_name								As type_name,
					sd.description								As description,
            		sd.date_updated								As date_updated

			From 	clearing_house.view_sample_descriptions sd
					Join clearing_house.view_sample_description_types sdt
					  On sdt.merged_db_id = sd.sample_description_type_id
					 And sdt.submission_id In (0, sdt.submission_id)
         			Join clearing_house.view_physical_samples ps
       	  	  		  On ps.merged_db_id = sd.physical_sample_id
         	 		 And ps.submission_id In (0, ps.submission_id)) As LDB
		Left Join (
			Select 	sd.sample_description_id					As sample_description_id,
					sd.physical_sample_id						As physical_sample_id,			 
					ps.sample_name 								As sample_name,
					sdt.type_name 								As type_name,
					sd.description								As description

			From 	public.tbl_physical_samples ps
					Join public.tbl_sample_descriptions sd
					  On sd.physical_sample_id = ps.physical_sample_id
					Join public.tbl_sample_description_types sdt
					  On sdt.sample_description_type_id = sd.sample_description_type_id) As RDB

		   	  On 	RDB.sample_description_id = LDB.public_db_id

		Where	LDB.source_id = 1
		  And 	LDB.submission_id = $1

		Order by LDB.physical_sample_id;
End 
$BODY$;

ALTER FUNCTION clearing_house.fn_clearinghouse_report_sample_descriptions(integer)
    OWNER TO clearinghouse_worker;
		  

*fn_clearinghouse_report_sample_dimensions(integer)

sample dimensions******

Select	LDB.local_db_id						            As local_db_id,
		LDB.physical_sample_id						    As physical_sample_id,
        LDB.sample_name									As sample_name,
        LDB.dimension_name								As dimension_name,
        LDB.dimension_value								As dimension_value,
		to_char(LDB.date_updated,'YYYY-MM-DD')			As date_updated,

		LDB.public_db_id								As public_db_id,
		
		RDB.sample_dimension_id							As public_sample_dimension_id,
		RDB.physical_sample_id						    As public_physical_sample_id,
		RDB.sample_name									As public_sample_name,
        RDB.dimension_name								As public_dimension_name,
		RDB.dimension_value								As public_dimension_value,

		entity_type_id						            As entity_type_id
From (

	Select  sdm.submission_id					As submission_id,
			sdm.source_id						As source_id,		
			sdm.local_db_id						As local_db_id,
			sdm.public_db_id					As public_db_id,
			sdm.physical_sample_id				As physical_sample_id,
			ps.sample_name						As sample_name,
			dm.dimension_name					As dimension_name,
			sdm.dimension_value					As dimension_value,
			sdm.date_updated					As date_updated
			
	From 	clearing_house.view_sample_dimensions sdm
			Join clearing_house.view_dimensions dm
			  On dm.merged_db_id = sdm.dimension_id
			 And dm.submission_id In (0, dm.submission_id)
         	Join clearing_house.view_physical_samples ps
       	  	  On ps.merged_db_id = sdm.physical_sample_id
         	 And ps.submission_id In (0, ps.submission_id)) As LDB
Left Join (
		
	Select 	sdm.sample_dimension_id				As sample_dimension_id,
    		sdm.physical_sample_id				As physical_sample_id,
			ps.sample_name						As sample_name,
			dm.dimension_name					As dimension_name,
			sdm.dimension_value					As dimension_value
			
	From 	public.tbl_sample_descriptions sd
			Join public.tbl_physical_samples ps
			  On sd.physical_sample_id = ps.physical_sample_id
			Join public.tbl_sample_dimensions sdm
			  On sdm.physical_sample_id = ps.physical_sample_id
			Join public.tbl_dimensions dm
			  On dm.dimension_id = sdm.dimension_id) As RDB
		  
	On RDB.sample_dimension_id = LDB.public_db_id

	Where 	LDB.source_id = 1
	  And  	LDB.submission_id = 1

	Order by LDB.physical_sample_id;

	
	
sample group dimensions***

Select	LDB.local_db_id						            As local_db_id,
		LDB.local_db_id						            As dimension_id,
		LDB.sample_group_id					           	As sample_group_id,
        LDB.sample_group_name							As sample_group_name,
        LDB.dimension_name								As dimension_name,
        LDB.dimension_value								As dimension_value,
		to_char(LDB.date_updated,'YYYY-MM-DD')			As date_updated,

		RDB.sample_group_id						        As public_sample_group_id,
		RDB.sample_group_name							As public_sample_group_name,
        RDB.dimension_name								As dimension_name,
		RDB.dimension_value								As dimension_value,
		entity_type_id						            As entity_type_id

From (

	Select	sgdm.submission_id				As submission_id,
			sgdm.source_id					As source_id,
			sgdm.local_db_id				As local_db_id,
			sgdm.public_db_id				As public_db_id,
			sgdm.sample_group_id			As sample_group_id,
			sg.sample_group_name			As sample_group_name,
			dm.dimension_name				As dimension_name,
			sgdm.dimension_value			As dimension_value,
    		sgdm.date_updated				As date_updated
		


	From	clearing_house.view_sample_group_dimensions sgdm
			Join clearing_house.view_dimensions dm
			  On dm.merged_db_id = sgdm.dimension_id
			 And dm.submission_id In (0, dm.submission_id)
         	Join clearing_house.view_sample_groups sg
       	  	  On sg.merged_db_id = sgdm.sample_group_id
         	 And sg.submission_id In (0, sg.submission_id)) As LDB
        

Left Join (

	Select 	sgdm.sample_group_id				As sample_group_id,
			sg.sample_group_name				As sample_group_name,
			dm.dimension_name					As dimension_name,
			sgdm.dimension_value				As dimension_value
			

	From 	public.tbl_sample_group_dimensions as sgdm
			Join public.tbl_dimensions dm
			  On sgdm.dimension_id = dm.dimension_id
			Join public.tbl_sample_groups sg
			  On sg.sample_group_id = sgdm.sample_group_id) as RDB
	
	n RDB.sample_group_id = LDB.public_db_id
	
	Where LDB.source_id = 1
	  And LDB.submission_id = $1
	
	Order by LDB.sample_group_id;


feature_types****

Select 
		LDB.local_db_id                       	As local_db_id,
		LDB.type_name                           As type_name,
		LDB.description		                    As description,      
		LDB.public_db_id                        As public_db_id,
		to_char(LDB.date_updated,'YYYY-MM-DD')	As date_updated,

		RDB.type_name                           As type_name,
		RDB.description		                    As description,

		entity_type_id                          As entity_type_id

From (                            

	Select  	ft.submission_id                As submission_id,
                ft.source_id                    As source_id,
                ft.local_db_id					As local_db_id,
                ft.public_db_id					As public_db_id,
				ft.feature_type_name            As type_name,
				ft.feature_type_description		As description,
				ft.date_updated					As date_updated
	From clearing_house.view_feature_types ft) As LDB 
Left Join (
		
	Select  ft.feature_type_id                      As feature_type_id,
			ft.feature_type_name                    As type_name,
			ft.feature_type_description		        As description
	From 	tbl_feature_types ft) As RDB

	  On RDB.feature_type_id = LDB.public_db_id

Where LDB.source_id = 1
  And LDB.submission_id = $1

Order By LDB.type_name;
