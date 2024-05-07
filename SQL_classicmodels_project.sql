-- ------------------------------------- Analysis of Classicmodels data using MySQL ------------------------------------------------
-- ----------------------------------------------------AVIRUP MITRA ----------------------------------------------------------------

use classicmodels;

-- ------------------------------------------------------------------------
# 1. List all the product names and their scale.

select productName,productScale from products;

-- ------------------------------------------------------------------------
# 2. Find number of customers from each country and sort in descending order.

select country,count(customerNumber) total_customers from customers 
group by country order by 2 desc;

-- ---------------------------------------------------------------------------

# 3. How many orders has each customer placed?

select o.customerNumber,(select customerName from customers c where c.customerNumber=o.customerNumber) customer_name,count(orderNumber) total_orders 
from orders o
where customerNumber in (select customerNumber from customers c)
group by o.customerNumber order by 3 desc;

-- ----------------------------------------------------------------------------

# 4. What is the total amount spent by each customer?

select c.customerNumber,c.customerName, sum(ifnull(p.amount,0)) amount_spent from customers c 
left join payments p on c.customerNumber=p.customerNumber
group by c.customerNumber order by 3 desc;

-- -----------------------------------------------------------------------------

# 5. List the top 5 most expensive products(average price across all orders).

select od.productCode,(select productName from products p where p.productCode=od.productCode) product_name, avg(od.priceEach) average_price 
from orderdetails od group by od.productCode,product_name 
order by average_price desc limit 5;
-- -----------------------------------------------------------------------------

# 6. Display salesperson and the number of sales made?

select salesRepEmployeeNumber, 
(select concat(firstname,' ',lastname) from employees e where c.salesRepEmployeeNumber=e.employeeNumber) Name,count(customerNumber) total_no_of_sales 
from customers c
where c.customerNumber in (select customerNumber from orders o where o.status in ('Shipped','Resolved'))
group by salesRepEmployeeNumber order by total_no_of_sales desc;

-- -------------------------------------------------------------------------------

# 7. What is the average order value?

select round(avg(total_price),2) average_order_price from (select o.orderNumber, sum(od.quantityOrdered*od.priceEach) total_price 
from orders o join orderdetails od
on o.orderNumber=od.orderNumber group by o.orderNumber) a;

-- --------------------------------------------------------------------------------

# 8. Retrieve least ordered product and most ordered product.

select p.productCode,p.productName,count(o.orderNumber) Order_count
from products p
join orderdetails o on p.productCode=o.productCode
group by p.productCode , p.productName
having Order_count in (select min(ordercount) from (select count(orderNumber) ordercount from orderdetails od group by od.productCode) a);
-- ------------------------------------------
select p.productCode,p.productName,count(o.orderNumber) Order_count
from products p
join orderdetails o on p.productCode=o.productCode
group by p.productCode , p.productName
having Order_count in (select max(ordercount) from (select count(orderNumber) ordercount from orderdetails od group by od.productCode) a);

-- ---------------------------------------------------------------------------------

# 9. List number of products from all product line.

select productLine,count(productCode) number_of_products from products
group by productLine order by 2 desc;

-- ---------------------------------------------------------------------------------

# 10. Find the products that were ordered top 2 times for each country.

select productCode,productName,Order_count, country from 
(select p.productCode productCode,p.productName productName,count(o.orderNumber) Order_count,c.country country,
dense_rank() over(partition by c.country order by count(o.orderNumber) desc) as order_rank
from customers c join orders o
on c.customerNumber=o.customerNumber
join orderdetails od on o.orderNumber=od.orderNumber
join products p on od.productCode=p.productCode
group by p.productCode,p.productName,c.country
order by 3 desc, 4) a where a.order_rank<=2 order by country;

-- ------------------------------------------------------------------------------

# 11. Calculate revenue,gross profit margin for each product across orders that are 'Shipped' and 'Resolved'.

select p.productCode, p.productName, 
sum(od.priceEach * od.quantityOrdered) revenue,
sum((od.priceEach - p.buyPrice) * od.quantityOrdered) grossProfit,
round((sum((od.priceEach - p.buyPrice) * od.quantityOrdered)*100/sum(od.priceEach * od.quantityOrdered)),2) grossProfitMargin
from products p join orderdetails od on p.productCode = od.productCode
where od.orderNumber in (select orderNumber from orders o where o.status in ('Shipped','Resolved'))
group by p.productCode, p.productName;

-- ---------------------------------------------------------------------------------

# 12. Show the total sales by product categories per quarter for the years.

select year(orderDate) year, quarter(orderDate) quarter,(select p.productLine from products p where p.productCode=od.productCode) productLine,
sum(od.quantityOrdered*od.priceEach) total_sales
from orders o join orderdetails od
on o.orderNumber=od.orderNumber
where o.status in ('Shipped','Resolved')
group by 1,2,3 order by 1,2;
