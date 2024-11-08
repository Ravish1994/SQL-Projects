use pizzahuttProject

select top 2 * from customerbase
select top 2 * from product_category
select top 2 * from Products
select top 2 * from Sales

--Q1 What is the total sales revenue ?
select sum(S.quantity*P.price) as [Total Sales Revenue] 
from products P right join sales S
on P.product_id = S.product_id;

--Q2 Which product has the highest sales revenue?
select Top 1 *, DENSE_RANK() 
over( order by [Total Sales Revenue] desc ) as Rank_ from (
select P.name, sum(S.quantity*P.price) as [Total Sales Revenue] 
from products P right join sales S
on P.product_id = S.product_id 
group by P.name ) as PVT;

--Q3 How many pizzas of each type were sold?
select P.name as [Types of Pizza],
sum(S.quantity) as Quantity
from sales S left join Products P
on P.product_id = S.product_id
where P.cat_id = 'PZ' group by P.name
order by sum(S.quantity) desc;

--Q4 What is the average quantity of products sold per day?
select sum(Quantity)/count(distinct sale_date)
as avg_quant_per_day from sales;

--Q5 Which day had the highest sales in terms of revenue?
select Top 1 *, DENSE_RANK() 
over( order by [Total Sales Revenue] desc ) as Rank_ from (
select S.sale_date, sum(S.quantity*P.price) as [Total Sales Revenue] 
from products P right join sales S
on P.product_id = S.product_id 
group by S.sale_date ) as PVT;

--Q6 What is total revenue generated on each day?
select S.sale_date, sum(S.quantity*P.price) as [Total Sales Revenue] 
from products P right join sales S
on P.product_id = S.product_id 
group by S.sale_date 

--Q7 What is the average price of each product?
select P.name, sum(P.price*S.quantity)/sum(S.quantity) as [Avg Price of the Product] 
from Products P right join sales S on P.product_id = S.product_id group by P.name;

--Q8 Which product has the highest average price?
select* from
(select *, dense_rank() over(
order by [Avg Price of the Product] desc) as Rank_
from (select P.name, sum(P.price*S.quantity)/sum(S.quantity) as [Avg Price of the Product] 
from Products P right join sales S on P.product_id = S.product_id group by P.name) as GFH) as GFD
where Rank_ = 1;

--Q9 What is the total sales revenue for a specific date range?
select sum(S.quantity*P.price) as [Total Sales Revenue] 
from products P right join sales S
on P.product_id = S.product_id 
where S.sale_date between '01-01-2022' and '01-01-2023';

--Q10 Which product were sold in the highest quantity?
select * from( select *, dense_rank()
over(order by Quantity desc) as Rank_ from (
select P.name, S.product_id, sum(S.quantity) as Quantity
from products P inner join sales S 
on P.product_id = S.product_id
group by S.product_id, P.name) as HJK) as GFH
where Rank_ = 1;

--Q11 What is the overall sales trend over time monthwise.
select [Month of Date] , sum([Total Sales Revenue Daywise]) as [Total Sales Revenue Monthwise]
from (select S.sale_date, month( S.sale_date) as [Month of Date], 
sum(S.quantity*P.price) as [Total Sales Revenue Daywise] 
from products P right join sales S
on P.product_id = S.product_id group by S.sale_date) as GHJ group by [Month of Date];

--Q12 How does sales quantity vary by product?
select P.name, S.product_id, sum(S.quantity) as Quantity
from products P inner join sales S 
on P.product_id = S.product_id
group by S.product_id, P.name
order by S.product_id;

--Q13 Which products have never been sold?
select name as [Never sold product]
from (select P.name, sum(S.quantity) as Quantity
from products P left join sales S 
on P.product_id = S.product_id group by P.name) as GHK
where Quantity is NULL;

--Q14 What is the distribution of sales across different product categories?
select P.cat_id, sum( S.quantity) as [Total Quantity], 
sum(S.quantity*P.price) as [Overall Sales]
from products P inner join sales S 
on P.product_id = S.product_id group by P.cat_id

--Q15 What is the total revenue generated by each product category?
select P.cat_id, sum( S.quantity) as [Total Quantity], 
sum(S.quantity*P.price) as [Total Revenue Generated]
from products P inner join sales S 
on P.product_id = S.product_id group by P.cat_id

--------------------------------------------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx----------------------------
--customer Analytics : Interesting Queries
--RFM Analysis [Customer Analytics]

--customer segmentation
--basis on frequency and monetry
--Monetory analysis
--anyone who is spending more than 80 dollars is high value customer
--anyone who is visiting more than 12 times is High frequency customer
create view [dbo].[vw_product_sale] as
SELECT sale_id, p.product_id, customer_id, sale_date, name, description,
category_desc,quantity, QUANTITY*PRICE AS Sales, delivery_fee
FROM SALES AS SALES
LEFT JOIN PRODUCTS AS P
ON P.PRODUCT_ID=SALES.PRODUCT_ID
left join product_category  as cat
on p.cat_id=cat.category_id

create view vw_rfm_analysis as
select cust.customer_id,customer_name,phoneno
,datediff(dd,max(sale_date),getdate()) as Recency,count(*) as Frequency
,cast(avg(sales) as int) as Monetry--Average_Sale_per_customer
,sum(sales) as sales,count(sale_id) as txn
from vw_product_sale as sale
left join customerbase as cust
on cust.customer_id=sale.customer_id
group by cust.customer_id,customer_name,phoneno

--Q16 Recency Analysis
--winback

--recency of consumer
-- x no of days ( then they will offer voucher/toppings/free product/ bogo offer/points)
--entice for you , for a limited period ,
--we have to create sense of urgency to take action
select cust.customer_id,customer_name,phoneno,max(sale_date) as Last_date_of_Transaction,
datediff(dd,max(sale_date),getdate()) as no_of_eclipse_day
from vw_product_sale as sale
left join  customerbase as cust
on sale.customer_id=cust.customer_id
group by cust.customer_id,customer_name,phoneno
order by 5 desc

--Q17 Frequency Analysis
select cust.customer_id,customer_name,phoneno,count(*) as frequency
from vw_product_sale as sale
left join customerbase as cust
on cust.customer_id=sale.customer_id group by
cust.customer_id,customer_name,phoneno
order by 4 desc

--Q18 Monetory Analysis
--customer Segmentation
select monetry_m+frequency_f,
count(customer_id) as Count_, sum(sales) as Sum_, sum(txn) from
(select customer_id,
case when frequency>12 then 'HF'
ELSE 'LF'
END AS frequency_f,
case when monetry>80 then 'HV'
else 'LV'
END AS Monetry_m,
sales, txn from vw_rfm_analysis) as rfm
group by frequency_f,Monetry_m

--Q19 Top 10 Customer based on Value and Volume
-- Based on Value
select top 10 C.customer_name, sum(P.price*S.quantity) as Sales_Value 
from customerbase C 
left join sales S on
C.customer_id = S.customer_id
left join Products P on
P.product_id = S.product_id 
group by C.customer_name
order by sum(P.price*S.quantity) desc;

-- Based on Volume
select top 10 C.customer_name, sum(S.quantity) as Sales_Volume
from customerbase C 
left join sales S on
C.customer_id = S.customer_id
left join Products P on
P.product_id = S.product_id 
group by C.customer_name
order by sum(S.quantity) desc;

--Q20 Top Most Product in each Product Category based on Quantity
select * from
(select *, DENSE_RANK()
over(partition by cat_id order by Quantity desc) as Rank_
from(
select distinct* from 
(select P.cat_id, P.name, P.description, S.quantity
from Products P inner join sales S
on S.product_id = P.product_id) as HJK) as GHF) as GFF
where Rank_=1 order by cat_id;

--Q21 Top 5 nearest and farthest customer (basis delivery fee)

-- Top 5 Farthest customer
select * from
(select S.delivery_fee,C.customer_name, DENSE_RANK()
over(order by s.delivery_fee desc) as Rank_
from products P inner join sales S 
on P.product_id = S.product_id 
inner join customerbase C 
on S.customer_id = C.customer_id) as DFG
where Rank_<=5;

-- Top 5 nearest customer
select * from
(select S.delivery_fee,C.customer_name, DENSE_RANK()
over(order by s.delivery_fee) as Rank_
from products P inner join sales S 
on P.product_id = S.product_id 
inner join customerbase C 
on S.customer_id = C.customer_id) as DFG
where Rank_<=5;


--Q22 Percentage of Delivery fee compare to order value
select (P.price*S.quantity) as [Order value], S.delivery_fee, 
round((S.delivery_fee/(P.price*S.quantity))*100,2) as [Percentage of Delivery fee compr to order value]
from products P inner join sales S 
on P.product_id = S.product_id order by (P.price*S.quantity) desc;

--Q23 Top customer in each product category 
create view VW_90 as
select C.customer_name, P.cat_id, (S.quantity*P.price) as [Revenue Generated]
from products P inner join sales S on P.product_id = S.product_id 
inner join customerbase C on S.customer_id = C.customer_id;

select distinct* from
(select *, DENSE_RANK()
over(partition by cat_id order by [Revenue Generated] desc) as Rank_
from VW_90) as VGH
where Rank_ = 1 order by cat_id;

--Q24 Financial year wise sales
--Q25 customer Universe