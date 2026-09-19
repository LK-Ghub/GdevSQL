-- =========================================================
-- Bloco E — CASE WHEN
-- =========================================================

-- E1: classificar pedidos por prazo de entrega
-- Pergunta de negócio: o pedido chegou adiantado, no prazo ou atrasado?
SELECT
    order_id,
    order_estimated_delivery_date,
    order_delivered_customer_date,
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'sem entrega registrada'
        WHEN order_delivered_customer_date < order_estimated_delivery_date THEN 'adiantado'
        WHEN order_delivered_customer_date = order_estimated_delivery_date THEN 'no prazo'
        ELSE 'atrasado'
    END AS status_entrega
FROM olist_orders_dataset
WHERE order_status = 'delivered';


-- E2: classificar clientes por faixa de gasto total (bronze / prata / ouro)
-- Pergunta de negócio: em qual faixa de valor cada cliente se encaixa?
WITH gasto_por_cliente AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS gasto_total
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
    JOIN olist_order_items_dataset oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    gasto_total,
    CASE
        WHEN gasto_total >= 1000 THEN 'ouro'
        WHEN gasto_total >= 300  THEN 'prata'
        ELSE 'bronze'
    END AS faixa_cliente
FROM gasto_por_cliente
ORDER BY gasto_total DESC;
-- Faixas de exemplo (300 / 1000): ajuste conforme a distribuição real do
-- gasto_total observada nos seus dados (ex: usando percentis/quartis) e
-- documente o critério escolhido no README de insights.


-- E3: classificar produtos por faixa de peso
-- Pergunta de negócio: o produto é leve, médio ou pesado?
SELECT
    product_id,
    product_weight_g,
    CASE
        WHEN product_weight_g IS NULL THEN 'sem informação'
        WHEN product_weight_g < 1000  THEN 'leve'
        WHEN product_weight_g < 10000 THEN 'médio'
        ELSE 'pesado'
    END AS faixa_peso
FROM olist_products_dataset;


-- E4: classificar pagamentos como à vista/parcelado, sinalizando parcelamentos longos
-- Pergunta de negócio: quantos pagamentos são parcelados em muitas vezes (>6)?
SELECT
    order_id,
    payment_type,
    payment_installments,
    CASE
        WHEN payment_installments <= 1 THEN 'à vista'
        WHEN payment_installments > 6  THEN 'parcelado longo'
        ELSE 'parcelado'
    END AS classificacao_pagamento
FROM olist_order_payments_dataset;
