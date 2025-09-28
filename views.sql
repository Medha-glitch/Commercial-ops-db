USE commercial_ops;

-- Sales Performance (by day & top products)
CREATE OR REPLACE VIEW vw_sales_performance AS
SELECT
  DATE(o.created_at) AS order_date,
  SUM(oi.total_amount) AS total_revenue,
  COUNT(DISTINCT o.id) AS order_count
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
WHERE o.status IN ('CONFIRMED','SHIPPED','DELIVERED')
GROUP BY DATE(o.created_at);

-- Inventory Status snapshot
CREATE OR REPLACE VIEW vw_inventory_status AS
SELECT
  p.id, p.name, p.category, p.stock_quantity, p.min_threshold,
  p.expiry_date,
  CASE WHEN p.stock_quantity < p.min_threshold THEN 'LOW' ELSE 'OK' END AS stock_health
FROM products p;

-- Delivery Analytics
CREATE OR REPLACE VIEW vw_delivery_analytics AS
SELECT
  d.delivery_date,
  SUM(d.status = 'DELIVERED') AS delivered_count,
  SUM(d.status = 'FAILED') AS failed_count,
  COUNT(*) AS total_deliveries
FROM deliveries d
GROUP BY d.delivery_date;
