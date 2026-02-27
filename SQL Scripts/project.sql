create database food_app_project;

use food_app_project;


create table customers (
    customer_id int primary key,
    name varchar(255),
    city varchar(255),
    signup_date date not null,
    gender varchar(10)
);

create table restaurants (
    restaurant_id int primary key,
    restaurant_name varchar(255),
    city varchar(255),
    cuisine varchar(255),
    rating decimal(3,2)
);

create table delivery_agents(
    agent_id int primary key,
    agent_name varchar(255) not null,
    city varchar(255),
    joining_date date,
    rating decimal(3,2)
);

create table orders(
    order_id int primary key,
    customer_id int not null,
    restaurant_id int not null,
    order_date date not null,
    order_amount decimal(10,2),
    discount decimal(5,2),
    payment_method varchar(50),
    delivery_time int,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

create table order_item(
    order_item_id int primary key,
    order_id int not null,
    item_name varchar(255),
    quantity int,
    price decimal(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

select * from customers;
select * from restaurants;
select * from delivery_agents;
select * from orders;
select * from order_item;

