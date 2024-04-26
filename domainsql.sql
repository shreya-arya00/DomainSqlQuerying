-- Users table to store user account information
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    address VARCHAR(255),
    phone_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table to store information about available products/services
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cart table to store information about user's cart items
CREATE TABLE cart (
    cart_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table to store information about user's orders
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    shipping_address VARCHAR(255),
    shipping_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order details table to store information about products in each order
CREATE TABLE order_details (
    detail_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reviews table to store user reviews and ratings for products/services
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Support tickets table to store user inquiries and issues
CREATE TABLE support_tickets (
    ticket_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    message TEXT,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Count total number of users
SELECT COUNT(*) AS total_users FROM users;

-- Retrieve top-rated products
SELECT p.*, AVG(r.rating) AS average_rating
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id
ORDER BY average_rating DESC
LIMIT 10;

-- Search products with dynamic filters, pagination, and sorting
CREATE OR REPLACE FUNCTION search_products(
    IN keyword VARCHAR(255),
    IN category VARCHAR(50),
    IN sort_column VARCHAR(50),
    IN sort_order VARCHAR(4),
    IN page INT,
    IN page_size INT
)
RETURNS TABLE (
    product_id INT,
    name VARCHAR(255),
    description TEXT,
    category VARCHAR(50),
    price DECIMAL(10, 2),
    stock_quantity INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM products
    WHERE (category = '' OR category = $2)
        AND (name ILIKE '%' || $1 || '%' OR description ILIKE '%' || $1 || '%')
    ORDER BY
        CASE WHEN sort_column = 'price' AND sort_order = 'asc' THEN price END ASC,
        CASE WHEN sort_column = 'price' AND sort_order = 'desc' THEN price END DESC,
        CASE WHEN sort_column = 'name' AND sort_order = 'asc' THEN name END ASC,
        CASE WHEN sort_column = 'name' AND sort_order = 'desc' THEN name END DESC
    LIMIT $6 OFFSET (($5 - 1) * $7);
END;
$$ LANGUAGE plpgsql;

-- Read operation for the users table
SELECT * FROM users WHERE user_id = ?;

-- Update operation for the users table
UPDATE users SET email = ?, password = ?, full_name = ?, address = ?, phone_number = ? WHERE user_id = ?;

-- Delete operation for the users table
DELETE FROM users WHERE user_id = ?;

-- Search query with like filter for users
SELECT * FROM users WHERE full_name ILIKE '%John%';

-- Sorting operation in the products table
SELECT * FROM products ORDER BY price DESC;

-- Pagination for the orders table
SELECT * FROM orders ORDER BY order_date DESC LIMIT 10 OFFSET 0;

-- Usage of joins to retrieve order details along with product names
SELECT od.*, p.name AS product_name
FROM order_details od
JOIN products p ON od.product_id = p.product_id;

-- Usage of counts to count the total number of orders for each user
SELECT user_id, COUNT(*) AS total_orders
FROM orders
GROUP BY user_id;

-- Usage of count with order by to retrieve the top users with the most orders
SELECT user_id, COUNT(*) AS total_orders
FROM orders
GROUP BY user_id
ORDER BY total_orders DESC;
