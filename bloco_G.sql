-- =========================================================
-- Bloco G — Views
-- =========================================================

-- G1: view consolidando pedido, cliente, itens, pagamento e vendedor
-- Serve de base para consultas analíticas futuras sem repetir os JOINs sempre.
--
-- Cuidado de granularidade: order_items tem grão por ITEM e
-- order_payments tem grão por PEDIDO (um pedido pode ter N pagamentos,
-- ex: cartão + voucher). Se juntássemos as duas tabelas direto, um
-- pedido com 3 itens e 2 pagamentos viraria 3 x 2 = 6 linhas na view
-- (o "produto cartesiano" das combinações), duplicando valores em
-- qualquer SUM() feito sobre a view sem agrupar antes. Para evitar
-- isso, agregamos os pagamentos por pedido ANTES do join, garantindo
-- 1 linha de pagamento por pedido (relação 1:1 com orders).
DROP VIEW IF EXISTS vw_pedidos_completos;

CREATE VIEW vw_pedidos_completos AS
WITH pagamentos_por_pedido AS (
    SELECT
        order_id,
        SUM(payment_value) AS valor_total_pago,
        MAX(payment_installments) AS max_parcelas,
        STRING_AGG(DISTINCT payment_type, ', ') AS formas_pagamento
    FROM olist_order_payments_dataset
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    oi.order_item_id,
    oi.product_id,
    oi.price,
    oi.freight_value,
    s.seller_id,
    s.seller_city,
    s.seller_state,
    p.formas_pagamento,
    p.max_parcelas,
    p.valor_total_pago
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset oi ON oi.order_id = o.order_id
JOIN olist_sellers_dataset s ON s.seller_id = oi.seller_id
LEFT JOIN pagamentos_por_pedido p ON p.order_id = o.order_id;
-- Observação: a view ainda tem grão por ITEM (por causa do join com
-- order_items) — isso é intencional, para permitir análises por
-- produto/vendedor usando price e freight_value normalmente. Já
-- valor_total_pago, max_parcelas e formas_pagamento são valores DO
-- PEDIDO (repetidos em cada linha de item do mesmo pedido) — não some
-- valor_total_pago direto sobre a view sem usar DISTINCT ON (order_id)
-- ou agrupar por order_id antes, senão ele volta a ser contado uma vez
-- por item.


-- G2: view consolidando nota média e volume de avaliações por categoria
DROP VIEW IF EXISTS vw_avaliacoes_categoria;

CREATE VIEW vw_avaliacoes_categoria AS
SELECT
    COALESCE(t.product_category_name_english, pr.product_category_name) AS categoria,
    COUNT(r.review_id) AS qtd_avaliacoes,
    ROUND(AVG(r.review_score), 2) AS nota_media
FROM olist_order_reviews_dataset r
JOIN olist_order_items_dataset oi ON oi.order_id = r.order_id
JOIN olist_products_dataset pr ON pr.product_id = oi.product_id
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = pr.product_category_name
GROUP BY categoria;
