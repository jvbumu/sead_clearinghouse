/*
with recursive rel_tree as (
   select rel_id, rel_name, rel_parent, 1 as level, array[rel_id] as path_info
   from INFORMATION_SCHEMA.relations 
   where rel_parent is null
   union all
   select c.rel_id, rpad(' ', p.level * 2) || c.rel_name, c.rel_parent, p.level + 1, p.path_info||c.rel_id
   from relations c
     join rel_tree p on c.rel_parent = p.rel_id
)
select rel_id, rel_name
from rel_tree
order by path_info;
*/
-- Table: tbl_sites

-- DROP TABLE tbl_sites;
https://docs.google.com/spreadsheets/d/1gLGEjcGp4iy9FENoF02Vubu5m8qrpMS1bJeM6PsNz5o/edit?usp=sharing

CREATE TABLE clearing_house.test_tbl_sites as select * from clearing_house.tbl_sites


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

select * from tbl_sites


