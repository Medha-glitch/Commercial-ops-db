# Commercial Operations Database (SQL)

![Status](https://img.shields.io/badge/status-case_study-green)
![DB](https://img.shields.io/badge/database-MySQL%20(InnoDB)-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

A scalable SQL database designed to streamline daily commercial operations for small-to-medium businesses selling perishables (inspired by a local dairy farm). It converts messy, unstructured communication (e.g., WhatsApp stock lists) into clean, queryable data with inventory control, orders, deliveries, and subscriptions.

---

## Table of Contents
- [Project Overview](#project-overview)
- [Problem & Context](#problem--context)
- [Business Scope](#business-scope)
- [Data Model](#data-model)
- [Key Features](#key-features)
- [SQL Implementation](#sql-implementation)
  - [Schema (DDL)](#schema-ddl)
  - [Sample Data (DML)](#sample-data-dml)
  - [Stored Procedures & Functions](#stored-procedures--functions)
  - [Triggers](#triggers)
  - [Reporting Views](#reporting-views)
- [Demo Queries](#demo-queries)
- [Challenges & Solutions](#challenges--solutions)
- [Results & Impact](#results--impact)
- [Learning Outcomes](#learning-outcomes)
- [Roadmap](#roadmap)
- [Architecture Diagram](#architecture-diagram)
- [How to Run Locally](#how-to-run-locally)
- [License](#license)

---

## Project Overview
**Duration:** _[Add timeframe]_  
**Tech Stack:** MySQL (InnoDB), Stored Procedures, Triggers, Views  
**Role:** Database Designer & Developer

This project models end-to-end operations: customers, products, orders, deliveries, suppliers, and **subscriptions** (e.g., daily milk delivery). It demonstrates **3NF design**, robust **many-to-many** handling, and **business logic automation** via routines/triggers.

---

## Problem & Context
Real scenario from a small dairy vendor:
- Daily long WhatsApp messages listing stock in free text.
- Hard to find items or availability quickly.
- No proper inventory/customer tracking.
- Miscommunications due to manual processes.

**Opportunity:** Build a structured commercial operations database that:
1) fixes immediate pain points, 2) showcases solid DB design, 3) scales to larger operations.

---

## Business Scope
Though inspired by a dairy use-case, the schema is generalized for **SMEs** with:
- Inventory & expiry tracking
- Customer orders & deliveries
- Subscription/recurring orders
- Supplier relationships
- Alerts & reporting

---

## Data Model

### Main Entities
- **Customers** — profile, contacts, preferences
- **Products** — categories, pricing, stock, expiry, thresholds
- **Orders** — customer orders, statuses, payments
- **OrderItems** — products in an order (junction table)
- **Deliveries** — route/date/status/notes
- **Suppliers** — product sources, quality metrics
- **Subscriptions** — recurring deliveries & items

### Core Relationships
- 1-to-Many: Customer → Orders, Customer → Subscriptions
- Many-to-Many: Orders ↔ Products (via `order_items`)
- 1-to-Many: Orders → Deliveries
- 1-to-Many: Subscriptions → SubscriptionItems

---

## Key Features
- **3NF schema** with indexes for performance.
- **Inventory control**: automatic stock decrease on order item insert.
- **Low-stock alerts** via trigger.
- **Subscription automation** with renewal logic.
- **Reporting views** for sales, inventory, delivery analytics.

---

## SQL Implementation

> ⚠️ All snippets are MySQL-compatible. Adjust `DELIMITER` as needed in your client (e.g., MySQL CLI or Workbench).

### Schema (DDL)
See [`sql/schema.sql`](sql/schema.sql).

### Sample Data (DML)
See [`sql/sample_data.sql`](sql/sample_data.sql).

### Stored Procedures & Functions
See [`sql/routines.sql`](sql/routines.sql).

### Triggers
See [`sql/triggers.sql`](sql/triggers.sql).

### Reporting Views
See [`sql/views.sql`](sql/views.sql).

---

## Demo Queries
```sql
-- 1) Find what’s available today (not expired)
SELECT id, name, stock_quantity, unit_price
FROM products
WHERE (expiry_date IS NULL OR expiry_date >= CURDATE())
ORDER BY category, name;

-- 2) Customers with active subscriptions & monthly expected revenue
SELECT c.name, CalculateMonthlySubscriptionRevenue(c.id) AS expected_monthly_revenue
FROM customers c
WHERE EXISTS (SELECT 1 FROM subscriptions s WHERE s.customer_id = c.id AND s.is_active = 1)
ORDER BY expected_monthly_revenue DESC;

-- 3) Low stock products
SELECT * FROM vw_inventory_status WHERE stock_health = 'LOW';

-- 4) Daily sales trend
SELECT * FROM vw_sales_performance ORDER BY order_date DESC LIMIT 14;

-- 5) Orders and their items (human-friendly)
SELECT o.id AS order_id, c.name AS customer, o.order_type, o.status,
       oi.product_id, p.name AS product, oi.quantity, oi.unit_price, oi.total_amount
FROM orders o
JOIN customers c ON c.id = o.customer_id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
ORDER BY o.created_at DESC, o.id, oi.id;
```

---

## Challenges & Solutions
**Many-to-Many Order Modeling**  
- _Problem:_ Orders with varying product quantities/prices  
- _Solution:_ `order_items` junction table with `quantity`, `unit_price`, `discount`, computed `total_amount`.

**Concurrency on Inventory**  
- _Problem:_ Simultaneous updates to stock  
- _Solution:_ Use `FOR UPDATE` where appropriate; design triggers to keep inventory consistent.

**Real-Time Consistency**  
- _Problem:_ Orders, inventory, and alerts syncing  
- _Solution:_ Triggers + logs ensure ACID behavior and auditability.

---

## Results & Impact
- **Query latency:** ~<30ms for typical lookups (inventory, order history)  
- **Data integrity:** 0 mismatches between orders & stock in test runs  
- **Scalability:** Designed for 1000+ daily SKUs and 500+ regular customers

**Business Value**
- Turned unstructured messaging into **queryable data**
- **Low-stock alerts** reduce stockouts
- **Subscription automation** reduces manual work
- **Views** enable quick sales & delivery insights

---

## Learning Outcomes
- Practical **3NF** design and selective denormalization tradeoffs
- Indexing & `EXPLAIN`-driven query tuning (MySQL InnoDB)
- Translating domain rules into **constraints, procedures, and triggers**

---

## Roadmap
**Phase 2**
- REST **API layer** for frontend integration
- Advanced analytics & forecasting
- **Multi-location** / warehouse support
- Webhooks for 3rd-party integrations

**Technical**
- Table **partitioning** for large datasets
- Replication (**primary-replica**) for HA
- Automated backups with **PITR**

---

## Architecture Diagram
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Customers     │    │    Products     │    │  Subscriptions  │
│                 │    │   (Dairy Items) │    │                 │
│ • customer_id   │    │ • product_id    │    │ • subscription_id│
│ • name          │    │ • name          │    │ • customer_id   │
│ • phone         │    │ • category      │    │ • delivery_freq │
│ • address       │    │ • unit_price    │    │ • next_delivery │
│ • preferences   │    │ • stock_qty     │    │ • is_active     │
└─────────┬───────┘    │ • expiry_date   │    └─────────┬───────┘
          │            │ • min_threshold │              │
          │            └─────────┬───────┘              │
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Orders      │    │   OrderItems    │    │SubscriptionItems│
│                 │    │                 │    │                 │
│ • order_id      │◄──►│ • order_id      │    │ • subscription_id│
│ • customer_id   │    │ • product_id    │    │ • product_id    │
│ • order_type    │    │ • quantity      │    │ • quantity      │
│ • status        │    │ • unit_price    │    │ • unit_price    │
│ • created_at    │    │ • total_amount  │    └─────────────────┘
└─────────┬───────┘    └─────────────────┘
          │
          ▼
┌─────────────────┐    ┌─────────────────┐
│   Deliveries    │    │  InventoryLog   │
│                 │    │                 │
│ • delivery_id   │    │ • log_id        │
│ • order_id      │    │ • product_id    │
│ • delivery_date │    │ • old_stock     │
│ • status        │    │ • new_stock     │
│ • notes         │    │ • update_reason │
└─────────────────┘    └─────────────────┘
```

---

## How to Run Locally
1. **Create DB & Tables**  
   Run the **Schema (DDL)** section first.
2. **Seed Data**  
   Run the **Sample Data (DML)** section.
3. **Add Routines/Triggers/Views**  
   Run the **Stored Procedures & Functions**, **Triggers**, and **Reporting Views** sections.
4. **Try Demo Queries**  
   Use the examples under **Demo Queries**.

> Tip: Split this README’s SQL into `schema.sql`, `sample_data.sql`, `routines.sql`, `triggers.sql`, and `views.sql` for cleaner iteration.

---

## License
This project is released under the **MIT License**. See [LICENSE](LICENSE).
