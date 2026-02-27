--phase 1: exploratory analysis

--1. total revenue
SELECT SUM(order_amount - discount) AS total_revenue
FROM orders;

--2. total orders per city
SELECT r.city, COUNT(*) AS total_orders
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY total_orders DESC;

--3. top 10 customers by spending
SELECT c.name, SUM(o.order_amount - o.discount) AS total_spent
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 10;

-- phase 2: customer segmentation

--4. customer category (gold/silver/bronze) based on total spending
SELECT c.name,
       SUM(o.order_amount - o.discount) AS total_spent,
       CASE 
           WHEN SUM(o.order_amount - o.discount) >= 30000 THEN 'Gold'
           WHEN SUM(o.order_amount - o.discount) >= 10000 THEN 'Silver'
           ELSE 'Bronze'
       END AS customer_category
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.name
ORDER BY total_spent DESC;

-- phase 3: restaurant performance

--5. top 10 restaurants by revenue

SELECT r.restaurant_name,r.city,
       SUM(o.order_amount - o.discount) AS total_revenue
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id 
GROUP BY r.restaurant_name,r.city
ORDER BY total_revenue DESC 
LIMIT 10;

--6. average rating vs revenue

SELECT r.restaurant_name,r.city,r.rating,
       SUM(o.order_amount - o.discount) AS total_revenue
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name,r.city,r.rating
ORDER BY total_revenue DESC;

--phase 4: delivery analysis

--7. average delivery time per city
SELECT r.city, AVG(o.delivery_time) AS avg_delivery_time
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY avg_delivery_time ASC;

--8. late deliveries(delivery_time > 45 mins)

SELECT r.restaurant_name, COUNT(*) AS late_deliveries
FROM orders o   
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.delivery_time > 45 
GROUP BY r.restaurant_name,r.city
ORDER BY late_deliveries DESC;

--8.1. count late deliveries per city

SELECT r.city, COUNT(*) AS late_deliveries
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.delivery_time > 45
GROUP BY r.city
ORDER BY late_deliveries DESC;

--phase 5: payment and discount analysis

--9. payment method distribution

SELECT payment_method, COUNT(*) AS count
FROM orders
GROUP BY payment_method
ORDER BY count DESC;

--10. discount impact on revenue

SELECT 
    CASE 
        WHEN discount > 0 THEN 'With Discount'
        ELSE 'Without Discount'
    END AS discount_status,
    SUM(order_amount - discount) AS total_revenue
FROM orders
GROUP BY discount_status
ORDER BY total_revenue DESC;

--phase 6: advanced sql

--11. monthly revenue using cte

WITH monthly_revenue AS (
    SELECT 
        month(order_date) AS month,
        SUM(order_amount - discount) AS revenue
    FROM orders
    GROUP BY month
)
SELECT month, revenue
FROM monthly_revenue
ORDER BY month;

--12. rank restaurants by revenue(window function)
SELECT restaurant_name, city, total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM (
    SELECT r.restaurant_name,r.city,
           SUM(o.order_amount - o.discount) AS total_revenue
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id 
    GROUP BY r.restaurant_name,r.city
) AS restaurant_revenue;

--13. above average revenue restaurants(subquery)

SELECT restaurant_name, city, total_revenue
FROM ( 
    SELECT r.restaurant_name,r.city,
           SUM(o.order_amount - o.discount) AS total_revenue
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id 
    GROUP BY r.restaurant_name,r.city
) AS restaurant_revenue
WHERE total_revenue > (
    SELECT AVG(total_revenue) FROM (
        SELECT SUM(o.order_amount - o.discount) AS total_revenue
        FROM orders o
        JOIN restaurants r ON o.restaurant_id = r.restaurant_id 
        GROUP BY r.restaurant_id
    ) AS avg_calc
)
ORDER BY total_revenue DESC;


--phase 7: database objects

--14. create revenue view

CREATE VIEW restaurant_revenue_view AS
SELECT r.restaurant_name, r.city,
       SUM(o.order_amount - o.discount) AS total_revenue   
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name, r.city;

--15. create stored procedure to get top N restaurants

CREATE PROCEDURE GetTopRestaurants(IN top_n INT)
BEGIN
    SELECT restaurant_name, city, total_revenue
    FROM restaurant_revenue_view
    ORDER BY total_revenue DESC
    LIMIT top_n;
END;

CALL GetTopRestaurants(5);

--phase 8: performance optimization

--16. index on order_date

CREATE INDEX idx_order_date ON orders(order_date);

--17. index on customer_name

CREATE INDEX idx_customer_name ON customers(name);

--phase 9: trigger automation

create table high_value_orders_log(
    log_id int primary key auto_increment,
    order_id int,
    customer_id int,
    restaurant_id int,
    order_amount decimal(10,2),
    log_date datetime default current_timestamp
);

CREATE TRIGGER trg_high_value_order
AFTER INSERT ON orders  
FOR EACH ROW
BEGIN
    IF NEW.order_amount > 1000 THEN
        INSERT INTO high_value_orders_log (order_id, customer_id, restaurant_id, order_amount)
        VALUES (NEW.order_id, NEW.customer_id, NEW.restaurant_id, NEW.order_amount);
    END IF;
END;

insert into orders values(1200,231,138,'2024-06-01',1500.00,100.00,'Credit Card',30);

select * from high_value_orders_log;

--18. create trigger to prevent negative discount

CREATE TRIGGER trg_prevent_negative_discount
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.discount < 0 THEN
        SET NEW.DISCOUNT = 0;
    END IF;
END;

INSERT INTO orders VALUES(1201,232,139,'2024-06-02',500.00,-50.00,'Cash',25);
SELECT * FROM orders WHERE order_id = 1201;


--19. create delivery delay warning trigger
create table delivery_delay_log(
    log_id int primary key auto_increment,
    order_id int,
    customer_id int,
    restaurant_id int,
    delivery_time int,
    created_at datetime default current_timestamp
);

CREATE TRIGGER trg_delivery_delay_warning
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.delivery_time > 45 THEN
        INSERT INTO delivery_delay_log (order_id, customer_id, restaurant_id, delivery_time)
        VALUES (NEW.order_id, NEW.customer_id, NEW.restaurant_id, NEW.delivery_time);
    END IF;
END;

INSERT INTO orders VALUES(1202,233,140,'2024-06-03',800.00,50.00,'Online Wallet',50);
SELECT * FROM delivery_delay_log;
