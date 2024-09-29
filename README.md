# SQL-Project
# Ad Click Prediction #
***
# Data overview #
The ID column uniquely identifies each ad impression, while full name personalizes the ad viewer. Gender, age, ad position, and device type offer demographic and placement insights. Time-of-day logs when the ad was viewed, and browsing history tracks user preferences; the target column, "click," indicates if the ad was clicked.
________

## Objective ##
•	Cleaned and processed data, handling missing values and fixing inconsistencies (e.g., incorrect gender values).

•	Performed data exploration to identify patterns between browsing history and ad clicks.

•	Implemented SQL queries to predict the likelihood of ad clicks based on various factors.

## Data Analysis ##
1.Data Cleaning and Imputation
Data cleaning and Imputation of selected and reviewed data where columns like Gender,device Type and Ad position were null. Impute missing values by filling in the most frequent value.

```sql
SELECT
    COUNT(*) AS total_Gender,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS gender_nulls,
    (SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS null_percentage
FROM Ad_click_prediction;

SELECT
    COUNT(*) AS total_Device,
    SUM(CASE WHEN Device_type IS NULL THEN 1 ELSE 0 END) AS "Device nulls",
    (SUM(CASE WHEN Device_type IS NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS null_percentage
FROM Ad_click_prediction;
```
## Data Imputing ##
```sql
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
```
## Exploratory Data Analysis ##
•	In the Exploratory Data Analysis (EDA), key columns were analysed to understand patterns and distributions. For the Age column, the minimum, maximum, and average values were calculated to assess the range and distribution of user ages. 

```sql
-----Data Distribution 

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
```

## Outlier Detection ##
The purpose of outlier detection is to identify data points that deviate significantly from the norm, which can indicate errors, unusual events, or important insights. Detecting outliers helps improve data quality and ensures accurate analysis.

```sql
-----outliers Detection
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
```

## Relation Analysis ##
The main goal is to look into how click-through rates on ads vary by gender in order to better understand audience engagement levels.

```sql
select gender,avg(click) as click_rate
From Ad_click_prediction
group by gender
```

## Trigger Function ##
Trigger Function was created to record changes to the click column in the ad click data and automate updates to the report table.

```sql
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
```






