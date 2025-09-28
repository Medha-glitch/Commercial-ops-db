USE commercial_ops;
DELIMITER //

-- Reduce stock when an order item is created & raise low-stock alert
CREATE TRIGGER trg_reduce_stock_on_order
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock_quantity = stock_quantity - NEW.quantity,
        last_updated = NOW()
    WHERE id = NEW.product_id;

    IF (SELECT stock_quantity FROM products WHERE id = NEW.product_id) < 
       (SELECT min_threshold FROM products WHERE id = NEW.product_id) THEN
        INSERT INTO alerts (product_id, alert_type, message, created_at)
        VALUES (NEW.product_id, 'LOW_STOCK',
                CONCAT('Low stock: product ID ', NEW.product_id), NOW());
    END IF;
END//

-- Auto-create order for due subscriptions and roll next date
CREATE TRIGGER trg_handle_subscription_renewal
BEFORE UPDATE ON subscriptions
FOR EACH ROW
BEGIN
    IF NEW.is_active = 1 AND NEW.next_delivery_date <= CURDATE() THEN
        INSERT INTO orders (customer_id, order_type, status, payment_status, created_at)
        VALUES (NEW.customer_id, 'SUBSCRIPTION', 'PENDING', 'UNPAID', NOW());

        -- ensure we use the exact ID of the order we just inserted
        SET @new_order_id := LAST_INSERT_ID();

        -- copy subscription items into the new order
        INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount)
        SELECT @new_order_id, si.product_id, si.quantity, si.unit_price, 0.00
        FROM subscription_items si
        WHERE si.subscription_id = NEW.id;

        -- set next delivery date
        SET NEW.next_delivery_date = DATE_ADD(NEW.next_delivery_date, INTERVAL NEW.delivery_frequency DAY);
    END IF;
END//

DELIMITER ;
