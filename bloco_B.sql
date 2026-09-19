-- =========================================================
-- Bloco B — JOINs
-- =========================================================

-- B1: categoria do produto (traduzida), valor do item, cidade do vendedor
-- Pergunta de negócio: relatório item a item com categoria em inglês e localização do vendedor.
SELECT
    oi.order_id,
    oi.order_item_id,
    COALESCE(t.product_category_name_english, pr.product_category_name) AS categoria,
    oi.price AS valor_item,
    s.seller_city
FROM olist_order_items_dataset oi
JOIN olist_products_dataset pr ON pr.product_id = oi.product_id
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = pr.product_category_name
JOIN olist_sellers_dataset s ON s.seller_id = oi.seller_id;


-- B2: pedidos com atraso na entrega (estimado x real), com dados do cliente
-- Pergunta de negócio: quais pedidos foram entregues depois do prazo estimado?
SELECT
    o.order_id,
    c.customer_state,
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date,
    (o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date) AS dias_de_atraso
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date;


-- B3: pedidos e suas formas de pagamento, incluindo pagamentos parcelados
-- Pergunta de negócio: como cada pedido foi pago, incluindo casos com mais de uma forma?
SELECT
    o.order_id,
    o.order_status,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
ORDER BY o.order_id, p.payment_sequential;


-- B4: produtos com categoria traduzida, incluindo categorias sem tradução cadastrada
-- Pergunta de negócio: quais produtos ficariam "sem categoria" se dependêssemos só da tradução?
SELECT
    pr.product_id,
    pr.product_category_name,
    t.product_category_name_english
FROM olist_products_dataset pr
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = pr.product_category_name;


-- B5: pedidos em que cliente e vendedor são do mesmo estado
-- Pergunta de negócio: em quantos pedidos a venda acontece "dentro do mesmo estado"?
SELECT DISTINCT
    o.order_id,
    c.customer_state,
    s.seller_state
FROM olist_customers_dataset c
JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON oi.order_id = o.order_id
JOIN olist_sellers_dataset s ON s.seller_id = oi.seller_id
WHERE c.customer_state = s.seller_state;
