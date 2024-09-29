select * from Ad_click_prediction

select * from Ad_click_prediction	
where gender is Null

SELECT
    COUNT(*) AS total_Gender,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS gender_nulls,
    (SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS null_percentage
FROM Ad_click_prediction;


UPDATE Ad_click_prediction
SET gender = (
SELECT gender FROM Ad_click_prediction WHERE gender IS NOT NULL 
	GROUP BY gender ORDER BY COUNT(*) DESC LIMIT 1
)
WHERE gender IS NULL;

select gender from Ad_click_prediction

select * from Ad_click_prediction
where Device_type is NUll

SELECT
    COUNT(*) AS total_Device,
    SUM(CASE WHEN Device_type IS NULL THEN 1 ELSE 0 END) AS "Device nulls",
    (SUM(CASE WHEN Device_type IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS null_percentage
FROM Ad_click_prediction;


UPDATE Ad_click_prediction
SET Device_type = (
SELECT Device_type FROM Ad_click_prediction WHERE Device_type IS NOT NULL 
	GROUP BY Device_type ORDER BY COUNT(*) DESC LIMIT 1
)
WHERE Device_type IS NULL;

select Device_type from Ad_click_prediction


select * from Ad_click_prediction
where ad_position is Null


SELECT
    COUNT(*) AS total_Ad,
    SUM(CASE WHEN ad_position IS NULL THEN 1 ELSE 0 END) AS "AD nulls",
    (SUM(CASE WHEN ad_position IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS null_percentage
FROM Ad_click_prediction;

UPDATE Ad_click_prediction
SET ad_position = (
SELECT ad_position FROM Ad_click_prediction WHERE ad_position IS NOT NULL 
	GROUP BY ad_position ORDER BY COUNT(*) DESC LIMIT 1
)
WHERE ad_position IS NULL;

select ad_position from Ad_click_prediction

select * from Ad_click_prediction 
where browsing_history is Null;

SELECT
    COUNT(*) AS total_history,
    SUM(CASE WHEN browsing_history IS NULL THEN 1 ELSE 0 END) AS "History nulls",
    (SUM(CASE WHEN browsing_history IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS null_percentage
FROM Ad_click_prediction;

---- Fill the Null with Placeholder

update Ad_click_prediction
set browsing_history='No history'
where browsing_history is Null

select browsing_history from Ad_click_prediction

select * from Ad_click_prediction
where time_of_day is Null

---- impute with time_of_day

update Ad_click_prediction
set time_of_day =(select time_of_day from Ad_click_prediction
where time_of_day is Not Null group by time_of_day
	order by count(*) desc Limit 1)
where time_of_day is Null

select time_of_day from Ad_click_prediction


Create table ad_click_backup
as select * from Ad_click_prediction

------ Review Data 

select * from Ad_click_prediction
where age is Null or gender is Null 
or ad_position is Null or browsing_history is Null
or time_of_day is Null

----- 2nd step is Data Exploration 

----- EDA of Age 

select min(age),max(age),avg(age)
from Ad_click_prediction
where age is Not Null

select  gender,count(*)from Ad_click_prediction
group by gender

---Device_type and ad_position 

select device_type ,count(*)
from Ad_click_prediction
group by device_type

select ad_position, count(*)
from Ad_click_prediction
group by ad_position


--- click__

select click, count(*)
from Ad_click_prediction
group by click

------Data Distribution 

Distribution of the individual variables 
Helps to find out outliers and understand how data behaves 

------Age Distribution 

select count (age) As "Distribution"
from Ad_click_prediction 
group by age order by age 

----Gender and Device_type distribution

select count(gender) as "count"
from Ad_click_prediction
group by gender 

select count(device_type) as "count"
from Ad_click_prediction
group by device_type

-----outliers Detection

Formula -Z-score
	Z=(value-mean)/standard deviation


create table  age_stats(
	mean_age Numeric,
	stddev_age Numeric
)

select * from age_stats

	
create or replace function age_stats_function()
returns Void as $$
declare 
mean_age Numeric;
stddev_age Numeric;

begin 
select avg(age),stddev(age) into mean_age,stddev_age
from Ad_click_prediction;
Insert into age_stats(mean_age,stddev_age)
values(mean_age,stddev_age);
End;
$$ Language plpgsql;


select age_stats_function()

select * from age_stats

--------Z_scores---
create table z_scores as 	
select id,age,
(age-(select mean_age from age_stats))/(select stddev_age from age_stats)
as z_score from Ad_click_prediction

select * from z_scores where abs(z_score)<-3


----Relation Analysis

select gender,avg(click) as click_rate
from Ad_click_prediction
group by gender

------Create the report table for tracking click rates and total clicks by gender

create table Report_table(
	gender varchar(20)Primary key,
	sum_of_clicks int,
	click_rate float 
)
-------Create the trigger function to update the report table after insert or update

create or replace function update_click_report()
returns trigger as $$
Declare
      sumofclicks int;
      avgclickRate float;
      count_report int;
Begin
      select sum(click),avg(click)
      into sumofclicks,avgclickRate
      from Ad_click_prediction
      where gender=New.gender;

      select count(*) into count_report
      from report_table
      where gender=New.gender;

     if count_report=0 then
      insert into report_table(gender,sum_of_clicks,click_rate)
      values (New.gender,sumofclicks,avgclickRate);
Else
      update report_table
      set sum_of_clicks=sumofclicks,
          click_rate=avgclickRate
      where gender=New.gender;
End If;
     RAISE NOTICE 'Updated report_table with sum_of_clicks: %, click_rate: %', sumOfClicks, avgClickRate;

return New;
End;
$$ language plpgsql;

create trigger update_click_report_trigger
After insert or update on Ad_click_prediction
for each row
execute function update_click_report();


select * from Ad_click_prediction

-------This trigger could be designed to log any updates made to the click column
create  Table  click_log(
	id int,
	old_click_value boolean,
	new_click_value boolean,
	updated_at timestamp default current_timestamp
)

Create or replace function log_click_changes()
Returns trigger as $$
Declare
       oldclick boolean;
       newclick boolean;
       log_count int;
Begin
        If OLD.click is distinct from New.click Then 
         oldclick=OLD.click;
         newclick=New.click;


      select count(*) into log_count from click_log
      where id=New.id and gender=New.gender;

       if log_count=0 Then 
       insert into click_log(id,old_click_value,new_click_value,updated_at)
      values (New.id,oldclick,newclick,current_timestamp);
Else
  update click_log
  set old_click_value=oldclick,
       new_click_value=newclick,
       updated_at=current_timestamp
  where id=New.id and gender=New.gender;
End If;

Raise notice'Logged click changes for ID: %, Old Click: %, New Click: %', NEW.id, oldClick, newClick;
End If;
Return New;
End;
$$ Language plpgsql;

Create trigger log_click_changes_trigger
After insert or update of click
on Ad_click_prediction
for each Row
Execute function log_click_changes()


