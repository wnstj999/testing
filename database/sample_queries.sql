-- Sample CRUD and Analytical Queries for the Portal System

-- 1. Create: Insert a new city for the existing country.
INSERT INTO cities (country_code, city_name, is_port_city, latitude, longitude, population)
VALUES ('DEU', 'Hamburg', 'Y', 53.5511, 9.9937, 1841000);

-- 2. Read: Retrieve all port cities with their country names.
SELECT c.city_name,
       co.country_name,
       p.port_name,
       p.container_capacity_teu
FROM cities c
JOIN countries co ON co.country_code = c.country_code
LEFT JOIN ports p ON p.city_id = c.city_id
WHERE c.is_port_city = 'Y'
ORDER BY co.country_name, c.city_name;

-- 3. Update: Adjust reserved quantity after confirming an order.
UPDATE inventory
SET quantity_reserved = quantity_reserved + 20
WHERE warehouse_id = 1 AND product_id = 2;

-- 4. Delete: Remove obsolete exchange rate data.
DELETE FROM exchange_rates
WHERE rate_date < CURRENT_DATE - INTERVAL '5' YEAR;

-- 5. Join 200 rows example: Summarize inventory by country and warehouse.
SELECT co.country_name,
       w.warehouse_name,
       p.product_name,
       i.quantity_on_hand,
       i.quantity_reserved
FROM inventory i
JOIN warehouses w ON w.warehouse_id = i.warehouse_id
JOIN products p ON p.product_id = i.product_id
JOIN malls m ON m.mall_id = p.mall_id
JOIN cities ci ON ci.city_id = w.city_id
JOIN countries co ON co.country_code = ci.country_code
ORDER BY co.country_name, w.warehouse_name, p.product_name
FETCH FIRST 200 ROWS ONLY;

-- 6. Analytics: Usage statistics per school, grade, class.
SELECT inst.institution_name,
       usage.grade_level,
       usage.class_name,
       SUM(usage.quantity_used) AS total_quantity_used
FROM product_usage_logs usage
JOIN institution_orders io ON io.institution_order_id = usage.institution_order_id
JOIN institutions inst ON inst.institution_id = io.institution_id
GROUP BY inst.institution_name, usage.grade_level, usage.class_name
ORDER BY inst.institution_name, usage.grade_level, usage.class_name;

-- 7. Audit trail sample query.
SELECT al.entity_name,
       al.entity_id,
       al.action_type,
       al.performed_at,
       mu.email AS performed_by
FROM audit_logs al
LEFT JOIN mall_users mu ON mu.user_id = al.performed_by
ORDER BY al.performed_at DESC
FETCH FIRST 50 ROWS ONLY;

