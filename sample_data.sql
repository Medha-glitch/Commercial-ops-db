USE commercial_ops;

INSERT INTO suppliers (name, contact, quality_score)
VALUES ('Shree Farms', 'shree@example.com', 4.5),
       ('Village Dairy Co-op', 'coops@example.com', 4.2);

INSERT INTO products (name, category, unit_price, stock_quantity, expiry_date, min_threshold, supplier_id)
VALUES ('Milk 500ml', 'Dairy', 30.00, 15, DATE_ADD(CURDATE(), INTERVAL 3 DAY), 5, 1),
       ('Paneer 200g', 'Dairy', 80.00, 8,  DATE_ADD(CURDATE(), INTERVAL 5 DAY), 3, 1),
       ('Butter 100g', 'Dairy', 70.00, 12, DATE_ADD(CURDATE(), INTERVAL 20 DAY), 4, 2),
       ('Curd 250ml',  'Dairy', 25.00, 20, DATE_ADD(CURDATE(), INTERVAL 4 DAY), 5, 2);

INSERT INTO customers (name, phone, address, preferences)
VALUES ('Aditi Verma','9999990001','Sector 5, City', JSON_OBJECT('delivery_window','7-9am')),
       ('Rahul Singh','9999990002','Old Town Road', JSON_OBJECT('no_contact','yes'));

-- Example order
INSERT INTO orders (customer_id, order_type, status, payment_status)
VALUES (1, 'STANDARD', 'CONFIRMED', 'PAID');

INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount)
VALUES (1, 1, 2, 30.00, 0.00),  -- 2 x Milk 500ml
       (1, 4, 4, 25.00, 0.00);  -- 4 x Curd 250ml

INSERT INTO deliveries (order_id, delivery_date, status, notes)
VALUES (1, CURDATE(), 'SCHEDULED', 'Leave at security if unavailable');

-- Subscription
INSERT INTO subscriptions (customer_id, delivery_frequency, frequency_per_month, next_delivery_date, is_active)
VALUES (1, 1, 30, CURDATE(), 1);

INSERT INTO subscription_items (subscription_id, product_id, quantity, unit_price)
VALUES (1, 1, 2, 30.00); -- 2 x Milk 500ml daily
