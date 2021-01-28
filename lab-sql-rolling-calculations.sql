use sakila; 
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
-- Get number of monthly active customers.
drop view if exists customer_activity; 

create or replace view customer_activity as
select customer_id, convert(rental_date, date) as Activity_date,
date_format(convert(rental_date,date), '%M') as Activity_Month,
date_format(convert(rental_date,date), '%m') as Activity_Month_number,
date_format(convert(rental_date,date), '%Y') as Activity_year
from sakila.rental;

drop view sakila.monthly_active_customer;

create view sakila.monthly_active_customer as
select Activity_year, Activity_Month, Activity_Month_number, count(customer_id) as Active_customer from sakila.customer_activity
group by Activity_year, Activity_Month
order by Activity_year asc, Activity_Month_number asc;

select Active_customer, Activity_Month, Activity_year
from sakila.monthly_active_customer
group by Activity_year, Activity_Month;

-- Active users in the previous month.
with cte_activity as (
  select Active_customer, lag(Active_customer,1) over (order by Activity_year) as last_month, 
  Activity_year, Activity_month
  from monthly_active_customer
)
select *
from cte_activity
where last_month is not null;

-- Percentage change in the number of active customers.
with cte_activity as (
  select Active_customer, lag(Active_customer,1) over (order by Activity_year) as last_month, 
  Activity_year, Activity_month
  from monthly_active_customer
)
select *, 
round(((Active_customer - last_month) / last_month ) * 100,2) as Percentage
from cte_activity
where last_month is not null;

-- Retained customers every month.

select distinct customer_id as Active_id, 
Activity_year, Activity_Month, Activity_month_number 
from customer_activity;

drop view sakila.distinct_users;

create view sakila.distinct_customers as 
select distinct customer_id as Active_id, 
Activity_year, Activity_Month, Activity_month_number 
from customer_activity;

select * from sakila.distinct_customers;

drop view if exists sakila.retained_customers;

create view sakila.retained_customers as 
select 
   a.Activity_year,
   a.Activity_month,
   a.Activity_month_number,
   count(distinct a.Active_id) as Retained_customers
   from sakila.distinct_customers as a
join sakila.distinct_customers as b
on a.Active_id = b.Active_id 
and b.Activity_month_number = a.Activity_month_number + 1 
group by a.Activity_year, a.Activity_month_number
order by a.Activity_year, a.Activity_month_number;

select * from sakila.retained_customers;

-- ==============================

