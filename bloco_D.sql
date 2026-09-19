-- =========================================================
-- Bloco D — Subqueries
-- =========================================================

-- D1: clientes cujo gasto total está acima da média geral de gasto por cliente
-- Pergunta de negócio: quem são os clientes de maior valor (acima da média)?
WITH gasto_por_cliente AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS gasto_total
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
    JOIN olist_order_items_dataset oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id
)
SELECT *
FROM gasto_por_cliente
WHERE gasto_total > (SELECT AVG(gasto_total) FROM gasto_por_cliente)
ORDER BY gasto_total DESC;


-- D2: produtos que nunca receberam avaliação
-- Pergunta de negócio: quais produtos não têm nenhum feedback de cliente?
SELECT pr.product_id
FROM olist_products_dataset pr
WHERE NOT EXISTS (
    SELECT 1
    FROM olist_order_items_dataset oi
    JOIN olist_order_reviews_dataset r ON r.order_id = oi.order_id
    WHERE oi.product_id = pr.product_id
);


-- D3: vendedores que venderam produtos de mais de 5 categorias diferentes
-- Pergunta de negócio: quais vendedores têm portfólio mais diversificado?
SELECT
    seller_id,
    qtd_categorias
FROM (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT pr.product_category_name) AS qtd_categorias
    FROM olist_order_items_dataset oi
    JOIN olist_products_dataset pr ON pr.product_id = oi.product_id
    GROUP BY oi.seller_id
) sub
WHERE qtd_categorias > 5
ORDER BY qtd_categorias DESC;


-- D4: pedidos cujo valor de frete é maior que o valor total dos itens do próprio pedido
-- Pergunta de negócio: em quais pedidos o frete "pesa" mais que o produto em si?
SELECT
    o.order_id,
    (SELECT SUM(oi.price) FROM olist_order_items_dataset oi WHERE oi.order_id = o.order_id) AS valor_itens,
    (SELECT SUM(oi.freight_value) FROM olist_order_items_dataset oi WHERE oi.order_id = o.order_id) AS valor_frete
FROM olist_orders_dataset o
WHERE (SELECT SUM(oi.freight_value) FROM olist_order_items_dataset oi WHERE oi.order_id = o.order_id)
    > (SELECT SUM(oi.price) FROM olist_order_items_dataset oi WHERE oi.order_id = o.order_id);
