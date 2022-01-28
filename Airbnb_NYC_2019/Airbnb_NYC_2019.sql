# Airbnb New York City 2019

# IMPORT DATA

create database Airbnb;

use airbnb;

## use table data import wizard
# only 291 rows imported 

select *
from nyc_2019;

## delete all imported rows and use LOAD DATA INFILE 

truncate table nyc_2019;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/AB_NYC_2019.csv'
INTO TABLE nyc_2019
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;




## DETECT OUTLIERS
# numerical features (this part using tableau to create boxplot)

select *
from nyc_2019
where price>1400;
# not wrong, just rare 

select *
from nyc_2019
where minimum_nights>400
order by minimum_nights;
# 11 rows, 5 values
# airbnb allows longterm rentals, though it's rare to rent more than 6 months?

select *
from nyc_2019
where number_of_reviews>594;
# 3 rows
# drop

select *
from nyc_2019
where reviews_per_month>14
order by reviews_per_month desc;
# 14 rows
# drop

select count(*)
from nyc_2019
where calculated_host_listings_count>91;
# 6 hosts, 975 rows

select longitude, latitude, count(*)
from nyc_2019
where calculated_host_listings_count>91
group by longitude, latitude
having count(*)>1;
# there isn't any 2 places with same longitude and latitude, they're not duplicate listings?

select count(*)
from nyc_2019
where availability_365 = 0;
# 17533 places busy all year
# available_365 isn't reliable

# categorical features

select neighbourhood_group, neighbourhood, count(*)
from nyc_2019
group by 1, 2
order by 3 desc;
# williamsburg and bedford-stuyvesant(Brooklyn) have the most listings

select room_type, count(*)
from nyc_2019
group by 1;
# entire home/apt is the most, there's just a few shared rooms


## FIND NULL/BLANK

select *
from nyc_2019
where name='' or name is null;
# 16 blank cells 

select *
from nyc_2019
where host_name='' or host_name is null;
# 21 blank cells
# name column does not affect much

select count(*)
from nyc_2019
where last_review='' or last_review is null;
# 10052 cells

select count(*)
from nyc_2019
where reviews_per_month='' or reviews_per_month is null;
# 10052 cells

select count(*)
from nyc_2019
where reviews_per_month='' or reviews_per_month is null and (last_review='' or last_review is null);
# same blank rows, wwhen number_of_reviews = 0



## CORRECTING DATA

# delete rows
delete from nyc_2019 where reviews_per_month>14;
delete from nyc_2019 where number_of_reviews>594;
# 16 rows deleted

# change reviews_per_month data type
update nyc_2019 set reviews_per_month=0 where reviews_per_month='';
alter table nyc_2019 modify column reviews_per_month decimal(6,4);

select reviews_per_month
from nyc_2019;






### DIFFERENCES BETWEEN AREAS

select neighbourhood_group, count(distinct(host_id)), count(id)
from nyc_2019
group by 1
order by 3 ;
# why brooklyn and manhattan have more listing (and might be busiest borough)? - location and tourism reason

# price histogram 

select neighbourhood_group, count(id) as count_listings,  
sum(case when room_type='Private room' then 1 end) as num_of_private_rooms,
sum(case when room_type='Shared room' then 1 end) as num_of_shared_rooms,
sum(case when room_type='Entire home/apt' then 1 end) as num_of_entire_home, avg(price)
from nyc_2019
group by 1
order by 3 desc;
# Manhattan has more entire home/apt for rent, that's why average price is higher than others?
# find reasons why Manhattan is the most expensive

select neighbourhood_group, room_type, count(id), avg(price)
from nyc_2019
group by 1, 2
order by 1, 2;

select neighbourhood_group, avg(minimum_nights)
from nyc_2019
group by neighbourhood_group;
# average minimum nights in Brooklyn are 6 and Manhattan are more than 8, while others are 4.5 - 5.2
# might suggest encourage longer vacation in those boroughs?, combine with room_type and price


select neighbourhood_group, sum(reviews_per_month*12) as num_of_guests
from nyc_2019
group by neighbourhood_group;
# brooklyn and manhattan has quite the same num_of_guests, queens is half of them, then bronx and staten island is the least
# compare this with number of listings, one host in queen must welcome more guests than manhattan and brooklyn in avg
# might need to encourage more hosts rent their home in queens, bronx and staten island



## dig deeper to reviewed listings

 create view active_listings as
 select *
 from nyc_2019
 where number_of_reviews>0;
 
 select neighbourhood_group, count(id)
 from active_listings
 group by 1;
# about 80% of the listing ever have reviews, in all boroughs 

select neighbourhood_group, room_type, count(id), avg(price)
from active_listings
group by 1, 2
order by 1,2;
# the reviewed listings in staten island are more affordable

# I suppose that reviews_per_month equal number_of_reviews divide number of months since the first review they've ever had 
# that's why those have 0 reviews have it empty in the reviews_per_month column instead of 0
# so i can calculate howlong a from the first review a listing ever had
# let's assume that's not long after they register

alter table nyc_2019 add month_active int;  
update nyc_2019 set month_active=(number_of_reviews/reviews_per_month);

select max(month_active), min(month_active)
from nyc_2019
limit 1000;

select max(month_active), min(month_active)
from active_listings;
#from 1 to 129 months

select neighbourhood_group, count(id), avg(number_of_reviews), sum(reviews_per_month*12), avg(reviews_per_month)
from active_listings
where month_active<13 
group by 1;


select neighbourhood_group, avg(reviews_per_month*minimum_nights) as num_of_days_rent
from active_listings
#where month_active<13 
group by 1;
# bronx hosts work 4 days a month, queens and brooklyn ones 4.3 days, manhattan and staten island 4.7 days
# because minimum nights is longer in brooklyn and manhattan, while others have more guests per host
# shouldn't increase hosts?


select neighbourhood_group, count(id), 
count(case when month_Active<13 then 1 end) as listings_2019, 
count(case when month_Active>13 and month_active<25 then 1 end) as listings_2018,
count(case when month_Active>25 and month_active<37 then 1 end) as listings_2017,
count(case when month_Active>37 and month_active<49 then 1 end) as listings_2016
from active_listings
group by 1;
# number of listing has increased higher in Queens, Bronx and Staten Island than others, in relative numbers
# they all almost double in 2019


select neighbourhood_group, year(cast(last_review as date)), count(id) 
from active_listings
group by 1, 2
order by 1,2;
