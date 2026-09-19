-- =========================================================
-- Bloco I — Window functions
-- =========================================================

-- I1: ranking dos vendedores por faturamento dentro de cada estado
-- Pergunta de negócio: quem é o vendedor #1 em cada estado?
WITH faturamento_vendedor_estado AS (
    SELECT
        s.seller_id,
        s.seller_state,
        SUM(oi.price) AS faturamento
    FROM olist_sellers_dataset s
    JOIN olist_order_items_dataset oi ON oi.seller_id = s.seller_id
    GROUP BY s.seller_id, s.seller_state
)
SELECT
    seller_id,
    seller_state,
    faturamento,
    RANK() OVER (PARTITION BY seller_state ORDER BY faturamento DESC) AS ranking_no_estado
FROM faturamento_vendedor_estado
ORDER BY seller_state, ranking_no_estado;


-- I2: faturamento mensal acumulado por vendedor
-- Pergunta de negócio: como a receita acumulada do vendedor evolui ao longo do tempo?
WITH faturamento_mensal_vendedor AS (
    SELECT
        oi.seller_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS mes,
        SUM(oi.price) AS faturamento_mes
    FROM olist_order_items_dataset oi
    JOIN olist_orders_dataset o ON o.order_id = oi.order_id
    GROUP BY oi.seller_id, DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    seller_id,
    mes,
    faturamento_mes,
    SUM(faturamento_mes) OVER (PARTITION BY seller_id ORDER BY mes) AS faturamento_acumulado
FROM faturamento_mensal_vendedor
ORDER BY seller_id, mes;


-- I3: percentual de participação de cada vendedor no faturamento total do seu estado
-- Pergunta de negócio: qual o peso relativo de cada vendedor dentro do seu estado?
WITH faturamento_vendedor_estado AS (
    SELECT
        s.seller_id,
        s.seller_state,
        SUM(oi.price) AS faturamento
    FROM olist_sellers_dataset s
    JOIN olist_order_items_dataset oi ON oi.seller_id = s.seller_id
    GROUP BY s.seller_id, s.seller_state
)
SELECT
    seller_id,
    seller_state,
    faturamento,
    ROUND(
        100.0 * faturamento / SUM(faturamento) OVER (PARTITION BY seller_state),
        2
    ) AS percentual_participacao_estado
FROM faturamento_vendedor_estado
ORDER BY seller_state, percentual_participacao_estado DESC;


-- I4: variação de faturamento de um mês para o outro por vendedor
-- Pergunta de negócio: o faturamento do vendedor está crescendo ou caindo mês a mês?
WITH faturamento_mensal_vendedor AS (
    SELECT
        oi.seller_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS mes,
        SUM(oi.price) AS faturamento_mes
    FROM olist_order_items_dataset oi
    JOIN olist_orders_dataset o ON o.order_id = oi.order_id
    GROUP BY oi.seller_id, DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    seller_id,
    mes,
    faturamento_mes,
    LAG(faturamento_mes) OVER (PARTITION BY seller_id ORDER BY mes) AS faturamento_mes_anterior,
    faturamento_mes - LAG(faturamento_mes) OVER (PARTITION BY seller_id ORDER BY mes) AS variacao_absoluta
FROM faturamento_mensal_vendedor
ORDER BY seller_id, mes;
