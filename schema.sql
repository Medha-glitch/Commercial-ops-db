-- SCHEMA: commercial_ops
CREATE DATABASE IF NOT EXISTS commercial_ops;
USE commercial_ops;

-- Customers
CREATE TABLE customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  phone VARCHAR(20) UNIQUE,
  address TEXT,
  preferences JSON NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Suppliers
CREATE TABLE suppliers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  contact VARCHAR(120),
  quality_score DECIMAL(4,2) DEFAULT 0.00,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Products
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  category VARCHAR(60),
  unit_price DECIMAL(10,2) NOT NULL,
  stock_quantity INT NOT NULL DEFAULT 0,
  expiry_date DATE NULL,
  min_threshold INT NOT NULL DEFAULT 5,
  supplier_id INT NULL,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_supplier
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Orders
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_type ENUM('STANDARD','SUBSCRIPTION') DEFAULT 'STANDARD',
  status ENUM('PENDING','CONFIRMED','SHIPPED','DELIVERED','CANCELLED') DEFAULT 'PENDING',
  payment_status ENUM('UNPAID','PAID','REFUNDED') DEFAULT 'UNPAID',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_orders_customer (customer_id),
  INDEX idx_orders_status (status)
) ENGINE=InnoDB;

-- Order Items (junction)
CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  discount DECIMAL(10,2) DEFAULT 0.00,
  total_amount AS (GREATEST(quantity * unit_price - discount, 0)) STORED,
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES products(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_oi_order (order_id),
  INDEX idx_oi_product (product_id)
) ENGINE=InnoDB;

-- Deliveries
CREATE TABLE deliveries (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  delivery_date DATE NOT NULL,
  status ENUM('SCHEDULED','OUT_FOR_DELIVERY','DELIVERED','FAILED') DEFAULT 'SCHEDULED',
  notes TEXT,
  CONSTRAINT fk_deliveries_order
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_deliveries_order (order_id),
  INDEX idx_deliveries_date (delivery_date)
) ENGINE=InnoDB;

-- Subscriptions
CREATE TABLE subscriptions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  delivery_frequency INT NOT NULL, -- days between deliveries
  frequency_per_month INT NOT NULL DEFAULT 30,
  next_delivery_date DATE NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_subs_customer FOREIGN KEY (customer_id)
    REFERENCES customers(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_subs_customer (customer_id),
  INDEX idx_subs_next_delivery (next_delivery_date)
) ENGINE=InnoDB;

-- Subscription Items
CREATE TABLE subscription_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  subscription_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_si_sub FOREIGN KEY (subscription_id) REFERENCES subscriptions(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_si_product FOREIGN KEY (product_id) REFERENCES products(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uq_subscription_product (subscription_id, product_id)
) ENGINE=InnoDB;

-- Inventory Log
CREATE TABLE inventory_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  old_stock INT NOT NULL,
  new_stock INT NOT NULL,
  update_reason VARCHAR(120),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_il_product FOREIGN KEY (product_id) REFERENCES products(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_il_product (product_id)
) ENGINE=InnoDB;

-- Alerts
CREATE TABLE alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  alert_type ENUM('LOW_STOCK','EXPIRY_SOON','SYSTEM') NOT NULL,
  message VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_resolved TINYINT(1) DEFAULT 0,
  CONSTRAINT fk_alerts_product FOREIGN KEY (product_id) REFERENCES products(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Helpful indexes
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_stock ON products(stock_quantity);
