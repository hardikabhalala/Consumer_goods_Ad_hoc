# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

select market from gdb023.dim_customer 
where customer = "Atliq Exclusive" and region = "APAC";

# 2. What is the percentage of unique product increase in 2021 vs. 2020? 
#The final output contains these fields, 
#unique_products_2020 
#unique_products_2021 
#percentage_chg

select X.A as unique_product_2020, Y.B as unique_product_2021, 
round((B - A)*100/A,2) as percentage_chg
from 
(
(select  count(distinct (product_code)) as A 
from gdb023.fact_sales_monthly
where fiscal_year = 2020) as X,
(select count(distinct (product_code)) as B
from gdb023.fact_sales_monthly
where fiscal_year = 2021) as Y
) ;

# 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
# The final output contains 2 fields, 
# segment 
# product_count
select segment, count(distinct(product_code)) as unique_product 
from gdb023.dim_product
group by segment order by unique_product desc;


# 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
# The final output contains these fields, 
#segment 
# product_count_2020 
# product_count_2021 
# difference

with cte1 as
(select p.segment as A, count(distinct(p.product_code)) as unique_product_2020 
from gdb023.fact_sales_monthly fs
join gdb023.dim_product p 
on p.product_code = fs.product_code
where fiscal_year = 2020 
group by segment),
cte2 as 
(select p.segment as B, count(distinct(p.product_code)) as unique_product_2021
from gdb023.fact_sales_monthly fs
join gdb023.dim_product p 
on p.product_code = fs.product_code
where fiscal_year = 2021 
group by segment)

select cte1.A as segment,unique_product_2020,unique_product_2021,(unique_product_2021 - unique_product_2020) as difference 
from cte1,cte2
where cte1.A = cte2.B;

# 5.Get the products that have the highest and lowest manufacturing costs.
# The final output should contain these fields, 
# product_code 
# product 
# manufacturing_cost

select m.product_code, p.product,m. manufacturing_cost
from gdb023.fact_manufacturing_cost m
join gdb023.dim_product p
on p.product_code = m.product_code
where manufacturing_cost
in
(select max(manufacturing_cost) from gdb023.fact_manufacturing_cost
union
select min(manufacturing_cost) from gdb023.fact_manufacturing_cost)
order by manufacturing_cost desc;

# 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
  # for the fiscal year 2021 and in the Indian market. The final output contains these fields,
  # customer_code 
  # customer 
  # average_discount_percentage
  
select c.customer_code, c.customer, round(avg(pre_invoice_discount_pct),4) AS average_discount_percentage
from gdb023.fact_pre_invoice_deductions d
join gdb023.dim_customer c on d.customer_code = c.customer_code
where c.market = "India" and fiscal_year = "2021"
group by c.customer_code,
         c.customer
order by average_discount_percentage desc
limit 5;

# 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
#This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
#The final report contains these columns:
#Month 
#Year 
#Gross sales Amount

select  monthname(s.date) AS Month, year(s.date) as year,
concat(round(sum(gross_price * sold_quantity)/1000000,2)," M") as gross_sales_amount
from gdb023.fact_sales_monthly as s 
join gdb023.fact_gross_price g 
on s.product_code = g.product_code
join gdb023.dim_customer c 
on s.customer_code = c.customer_code
where c.customer = "Atliq Exclusive"
group by Month, year
order by year;

# 8.In which quarter of 2020, got the maximum total_sold_quantity? 
# The final output contains these fields sorted by the total_sold_quantity,
# Quarter
# Total_sold_quantity

with temp_tables as (
    select month(date_add(date,interval 4 month)) as month,
           fiscal_year,
           sold_quantity 
    from gdb023.fact_sales_monthly
)
select 
      case
          when month/3<=1 then "Q1"
          when month/3<=2 and month/3>1 then "Q2"
          when month/3<=3 and month/3>2 then "Q3"
          when month/3<=4 and month/3>3 then "Q4"
          end quarter,
 round(sum(sold_quantity)/1000000,2) as total_sold_quantity_mln
 from temp_tables
 where fiscal_year = 2020
 group by quarter
 order by total_sold_quantity_mln desc;
 
 # 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
 # The final output contains these fields
 # channel 
 # gross_sales_mln 
 # percentage
 
 with temp_table as (
 select sum(gp.gross_price*s.sold_quantity) as gross_sales, s.fiscal_year,c.channel
 from gdb023.fact_sales_monthly s
 join gdb023.fact_gross_price gp on s.product_code = gp.product_code
 join gdb023.dim_customer c on c.customer_code = s.customer_code
 where s.fiscal_year = 2021
 group by channel
 order by gross_sales desc )
 
 select 
 channel, 
 round((gross_sales)/1000000,2) as gross_sales_mln,
 round(gross_sales/(sum(gross_sales) over())*100,2) as percentage
 from temp_table;
 
# 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
# The final output contains these fields, 
# division 
# product_code


select division,product_code,total_sold_quantity,rank_order
from sales_2021
where rank_order <=3
order by division,rank_order;




 
