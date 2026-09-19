-- =========================================================
-- Bloco F — CTE / tabela temporária
-- =========================================================

-- F1: faturamento mensal por estado e variação percentual mês a mês
-- Pergunta de negócio: como a receita de cada estado evolui mês a mês?
WITH faturamento_mensal AS (
    SELECT
        c.customer_state,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS mes,
        SUM(oi.price) AS faturamento
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
    JOIN olist_order_items_dataset oi ON oi.order_id = o.order_id
    GROUP BY c.customer_state, DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    customer_state,
    mes,
    faturamento,
    LAG(faturamento) OVER (PARTITION BY customer_state ORDER BY mes) AS faturamento_mes_anterior,
    ROUND(
        100.0 * (faturamento - LAG(faturamento) OVER (PARTITION BY customer_state ORDER BY mes))
        / NULLIF(LAG(faturamento) OVER (PARTITION BY customer_state ORDER BY mes), 0),
        2
    ) AS variacao_percentual
FROM faturamento_mensal
ORDER BY customer_state, mes;


-- F2: volume de avaliações e nota média por categoria, para achar as piores reputações
-- Pergunta de negócio: quais categorias têm pior reputação, considerando volume relevante?
WITH avaliacoes_categoria AS (
    SELECT
        COALESCE(t.product_category_name_english, pr.product_category_name) AS categoria,
        COUNT(r.review_id) AS qtd_avaliacoes,
        ROUND(AVG(r.review_score), 2) AS nota_media
    FROM olist_order_reviews_dataset r
    JOIN olist_order_items_dataset oi ON oi.order_id = r.order_id
    JOIN olist_products_dataset pr ON pr.product_id = oi.product_id
    LEFT JOIN product_category_name_translation t
        ON t.product_category_name = pr.product_category_name
    GROUP BY categoria
)
SELECT *
FROM avaliacoes_categoria
WHERE qtd_avaliacoes >= 30  -- volume mínimo para considerar relevante; ajuste se necessário
ORDER BY nota_media ASC, qtd_avaliacoes DESC;


-- F3: frete médio por estado do cliente, comparado à média geral
-- Pergunta de negócio: quais estados pagam frete acima da média nacional?
WITH frete_por_estado AS (
    SELECT
        c.customer_state,
        AVG(oi.freight_value) AS frete_medio_estado
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
    JOIN olist_order_items_dataset oi ON oi.order_id = o.order_id
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    ROUND(frete_medio_estado, 2) AS frete_medio_estado,
    ROUND((SELECT AVG(frete_medio_estado) FROM frete_por_estado), 2) AS frete_medio_geral,
    ROUND(frete_medio_estado - (SELECT AVG(frete_medio_estado) FROM frete_por_estado), 2) AS diferenca_vs_geral
FROM frete_por_estado
ORDER BY diferenca_vs_geral DESC;
