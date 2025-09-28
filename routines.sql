USE commercial_ops;
DELIMITER //

-- Daily Inventory Update Procedure
CREATE PROCEDURE UpdateDailyInventory(
    IN p_product_id INT,
    IN p_fresh_stock_qty INT,
    IN p_new_expiry DATE
)
BEGIN
    DECLARE v_old_stock INT DEFAULT 0;

    SELECT stock_quantity INTO v_old_stock
    FROM products WHERE id = p_product_id FOR UPDATE;

    UPDATE products
    SET stock_quantity = v_old_stock + p_fresh_stock_qty,
        expiry_date = p_new_expiry,
        last_updated = NOW()
    WHERE id = p_product_id;

    INSERT INTO inventory_log (product_id, old_stock, new_stock, update_reason)
    VALUES (p_product_id, v_old_stock, v_old_stock + p_fresh_stock_qty, 'Daily Fresh Stock');
END//

-- Monthly Subscription Revenue for a Customer
CREATE FUNCTION CalculateMonthlySubscriptionRevenue(p_customer_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_monthly_total DECIMAL(10,2) DEFAULT 0.00;

    SELECT COALESCE(SUM(si.quantity * si.unit_price * s.frequency_per_month), 0.00)
      INTO v_monthly_total
    FROM subscriptions s
    JOIN subscription_items si ON s.id = si.subscription_id
    WHERE s.customer_id = p_customer_id AND s.is_active = 1;

    RETURN v_monthly_total;
END//

DELIMITER ;
