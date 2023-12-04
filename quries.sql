use gdb023;
select count(*) from sales;

/*
 lets create a view 'sales' field consist date, customer_code, customer_name, product_code, product,
   variant, segment, sold_quantity, fiscal_year, market, region
select 
	s.date, s.customer_code,
    c.customer as customer_name,
    s.product_code, p.product,
    s.sold_quantity, s.fiscal_year,
    p.variant, p.segment,
    c.market,
    c.region
from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
join dim_product p 
on s.product_code=p.product_code;
*/
# Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select 
	distinct(s.market)
from sales s
where customer_name= 'Atliq Exclusive' and region = 'APAC';

# What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
with unique_p_20 as
	(select 
		count(distinct(product_code)) as unique_products_2020
	from sales
	where fiscal_year=2020),
 unique_p_21 as
	(select 
		count(distinct(product_code)) as unique_products_2021
	from sales
	where fiscal_year=2021)
select 
	*,
    round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) as percentage_chg
from unique_p_20 cross join unique_p_21 ;

#Provide a report with all the unique product counts for each segment and
#sort them in descending order of product counts. The final output contains 2 fields, segment product_count
select 
	segment,
    count(distinct product_code) as product_count
from sales
group by segment
order by product_count desc;

# Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
# The final output contains these fields, segment product_count_2020 product_count_2021 difference
with p_20 as (
	select 
		segment,
		count(distinct product_code) as product_count_2020
	from sales
    where fiscal_year=2020
	group by segment),
p_21 as (
	select 
		segment,
		count(distinct product_code) as product_count_2021
	from sales
    where fiscal_year=2021
	group by segment)
select 
	*,
    product_count_2021 - product_count_2020 as difference,
    (product_count_2021 - product_count_2020)*100/product_count_2020 as percentage_chg
from p_20 
join p_21 using(segment)
order by percentage_chg desc;

# Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code,product, manufacturing_cost
select 
	m.product_code,
    p.product,
    m.manufacturing_cost
from fact_manufacturing_cost m 
join dim_product p
on m.product_code = p.product_code
where m.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
	or m.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);

# Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
# The final output contains these fields, customer_code, customer, average_discount_percentage

select 
	s.customer_code, s.customer_name,
    round(avg(pre_d.pre_invoice_discount_pct)*100,2) as average_discount_percentage
from sales s
join fact_pre_invoice_deductions pre_d
on s.customer_code = pre_d.customer_code
where s.fiscal_year=2021 and market = 'India'
group by s.customer_code
order by average_discount_percentage desc limit 5;

# Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
# This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
# The final report contains these columns: Month Year Gross sales Amount
select
	month(s.date) as Month,
    year(s.date) as Year,
    round(sum(g.gross_price),2) as gross_sales
from sales s
join fact_gross_price g
on s.product_code = g.product_code and s.fiscal_year = g.fiscal_year
where customer_name='Atliq Exclusive'
group by Month, Year
order by Year;

# In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity
select 
	get_fiscal_quater(date) as Quarter,
    sum(sold_quantity) as total_sold_quantity
from sales
where fiscal_year = 2020
group by quarter
order by total_sold_quantity desc;

# Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
# The final output contains these fields, channel gross_sales_mln percentage
-- Since channel is not joined to the sales table hence we used join among fact_sales_monthly, dim_customer and fact_gross_price
with cte as (
select 
    c.channel,
    round(sum(g.gross_price/1000000),2)as  gross_sales_mln   
from fact_sales_monthly s
join dim_customer c
on c.customer_code = s.customer_code
join fact_gross_price g
on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year
where s.fiscal_year = 2021
group by c.channel)
select 
	*,
    (gross_sales_mln*100/sum(gross_sales_mln) over()) as percentage
from cte;

# Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
# The final output contains these fields, division product_code, product total_sold_quantity rank_order
with cte as(
    select
		p.division,
		s.product_code,
		s.product,
		sum(sold_quantity) as total_sold_quantity,
        rank() over(partition by division order by sum(sold_quantity) desc) as rank_order
	from sales s
	join dim_product p
	on p.product_code = s.product_code
	where fiscal_year=2021
	group by product_code)
select 
	*
from cte
where rank_order <= 3;



