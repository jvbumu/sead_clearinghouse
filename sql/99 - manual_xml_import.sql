
-- Add the following stored procedure to server side target database (if not exists):
CREATE OR REPLACE FUNCTION clearing_house.xml_import(loid oid, p_unlink boolean DEFAULT true)
 RETURNS xml
 LANGUAGE plpgsql
AS $function$
    declare
        content bytea;
        lfd integer;
        lsize integer;
    begin
        lfd := lo_open(loid,262144); --INV_READ
        lsize := lo_lseek(lfd,0,2);
        perform lo_lseek(lfd,0,0);
        content := loread(lfd,lsize);
        perform lo_close(lfd);

        if p_unlink then
            perform lo_unlink(loid);
        end if;

        return xmlparse(document convert_from(content,'UTF8'));
    end;
$function$

-- Create a target table where the XML will be stored.
CREATE TABLE clearing_house.tbl_clearinghouse_xml_temp(
  id serial not null,
  xmldata xml
);

-- Transfer XML to submission table
CREATE OR REPLACE FUNCTION clearing_house.xml_transfer_bulk_upload(p_submission_id integer DEFAULT NULL::integer, p_xml_id integer DEFAULT NULL::integer, p_upload_user_id integer DEFAULT 4)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
Begin

	p_xml_id = Coalesce(p_xml_id, (Select Max(ID) from clearing_house.tbl_clearinghouse_xml_temp));

	If p_submission_id Is Null Then

        Select Coalesce(Max(submission_id),0) + 1
        Into p_submission_id
        From clearing_house.tbl_clearinghouse_submissions;

        Insert Into clearing_house.tbl_clearinghouse_submissions(submission_id, submission_state_id, data_types, upload_user_id,
            upload_date, upload_content, xml, status_text, claim_user_id, claim_date_time)

            Select p_submission_id, 1, 'Undefined other', p_upload_user_id, now(), null, xmldata, 'New', null, null
            From clearing_house.tbl_clearinghouse_xml_temp
            Where id = p_xml_id;
    Else

		Update clearing_house.tbl_clearinghouse_submissions
        	Set XML = X.xmldata
        From clearing_house.tbl_clearinghouse_xml_temp X
        Where clearing_house.tbl_clearinghouse_submissions.submission_id = p_submission_id
          And X.id = p_xml_id;

    End If;

    Return p_submission_id;
End $function$



/*****************************************************************************************************************************
**	Function	fn_truncate_all_entity_tables
**	Who			Roger Mähler
**	When		2018-03-25
**	What		Truncates all clearinghouse entity tables and resets sequences
**  Note        NOTE! This Function clears ALL entities in CH tables!
**	Uses
**	Revisions
******************************************************************************************************************************/
-- Select clearing_house.fn_truncate_all_entity_tables()
Create Or Replace Function clearing_house.fn_truncate_all_entity_tables()
Returns void As $$
    Declare x record;
    Declare command text;
    Declare item_count int;
Begin

    -- Raise 'This error raise must be removed before this function will run';

	For x In (
        Select t.*
        From clearing_house.tbl_clearinghouse_submission_tables t
	) Loop

        command = 'select count(*) from clearing_house.' || x.table_name_underscored || ';';

        Raise Notice '%: %', command, item_count;

        Begin
            Execute command Into item_count;
            If item_count > 0 Then
                command = 'TRUNCATE clearing_house.' || x.table_name_underscored || ' RESTART IDENTITY;';
                Execute command;
            End If;
       Exception
            When undefined_table Then
                Raise Notice 'Missing: %', x.table_name_underscored;
                -- Do nothing, and loop to try the UPDATE again.
       End;

	Truncate Table clearing_house.tbl_clearinghouse_submission_xml_content_values Restart Identity Cascade;
	Truncate Table clearing_house.tbl_clearinghouse_submission_xml_content_columns Restart Identity Cascade;
	Truncate Table clearing_house.tbl_clearinghouse_submission_xml_content_records Restart Identity Cascade;
	Truncate Table clearing_house.tbl_clearinghouse_submission_xml_content_tables Restart Identity Cascade;
    Truncate Table clearing_house.tbl_clearinghouse_submissions Restart Identity Cascade;
    Truncate Table clearing_house.tbl_clearinghouse_xml_temp Restart Identity Cascade;

	End Loop;
	End
$$ Language plpgsql;

