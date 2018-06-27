-- PREPARE CLEAN SLATE OF PUBLIC DB - APPLY IF PUBLIC DB IS TO BE RECREATED
-- WARNING!!!! WARNING!!!! WARNING!!!! CASCADED DROP!!!

DO $$
Begin

    Perform clearing_house.fn_drop_clearinghouse_public_db_model();
    Perform clearing_house.fn_create_clearinghouse_public_db_model();

End $$ Language plpgsql;
