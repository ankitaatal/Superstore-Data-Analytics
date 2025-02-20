-- Create the Database
CREATE DATABASE IF NOT EXISTS superstore;
USE superstore;

-- Create Customers Table
CREATE TABLE customers (
    customer_id CHAR(8) PRIMARY KEY, 
    customer_name VARCHAR(100) NOT NULL,
    segment VARCHAR(25)     
);

-- Create Orders Table
CREATE TABLE orders (
    order_id CHAR(14) PRIMARY KEY,
    customer_id CHAR(8) NOT NULL,
    order_date DATE NOT NULL,
    ship_date DATE,
    ship_mode VARCHAR(25), 
    region VARCHAR(10),
    country VARCHAR(50), 
    state VARCHAR(50),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- Create Products Table
CREATE TABLE products (
    product_id CHAR(15) PRIMARY KEY, 
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(25), 
    sub_category VARCHAR(25) 
);

-- Create Sales Table
CREATE TABLE sales (
    order_id CHAR(14),
    product_id CHAR(15),
    quantity INT NOT NULL CHECK (quantity > 0), -- Ensures valid quantities
    sales DECIMAL(12,2) DEFAULT 0.00, -- Adjusted for large sales amounts
    discount DECIMAL(5,2) DEFAULT 0.00 CHECK (discount >= 0 AND discount <= 1), -- Ensures valid discount range
    profit DECIMAL(12,2) DEFAULT 0.00,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- Indexes for Faster Performance
CREATE INDEX idx_customer_id ON orders(customer_id);
CREATE INDEX idx_product_id ON sales(product_id);
CREATE INDEX idx_order_id ON sales(order_id);

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

-- '/path/to/table.csv' make changes to this as needed
LOAD DATA INFILE '/path/to/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'    -- As I combined product names with a ',' while data cleaning
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/sales.csv'
REPLACE INTO TABLE sales
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;
