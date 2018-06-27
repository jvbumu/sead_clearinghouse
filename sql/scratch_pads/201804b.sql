

-- https://docs.google.com/spreadsheets/d/1gLGEjcGp4iy9FENoF02Vubu5m8qrpMS1bJeM6PsNz5o/edit?usp=sharing

with inserted_sites as (
      insert into public.tbl_sites (...)
          select *
          from cleareing_house.tbl_sites
          where submission_id = 1
            and coalesce(public_db_id,0) > 0
          returning *
     )
insert into product_metadata (product_id, sales_volume, date)
    select i.product_id, v.sales_volume, v.date
    from (values ('Dope product 1', 80, '2017-03-21'),
                 ('Dope product 2', 50, '2017-03-21'),
                 ('Dope product 3', 70, '2017-03-21')
         ) v(title, sales_volume, date) join
         i
         on i.title = v.title;

