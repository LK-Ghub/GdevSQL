-- =========================================================
-- Bloco H — Procedure de leitura (parametrizada)
-- =========================================================
-- Observação: no PostgreSQL, PROCEDURE (invocada via CALL) não retorna um
-- result set diretamente — apenas via parâmetros OUT/INOUT. Como o
-- objetivo aqui é retornar um conjunto de dados de leitura (sem alterar
-- nada), implementamos como FUNCTION com RETURNS TABLE, que é o padrão
-- idiomático do Postgres para esse caso.

-- H1: relatório de vendedor (faturamento, ticket médio, nota média) no período
DROP FUNCTION IF EXISTS sp_relatorio_vendedor(VARCHAR, TIMESTAMP, TIMESTAMP);

CREATE OR REPLACE FUNCTION sp_relatorio_vendedor(
    id_vendedor VARCHAR,
    data_inicio TIMESTAMP,
    data_fim TIMESTAMP
)
RETURNS TABLE (
    seller_id VARCHAR,
    faturamento NUMERIC,
    ticket_medio NUMERIC,
    nota_media_avaliacao NUMERIC
)
LANGUAGE sql
AS $$
    SELECT
        s.seller_id,
        ROUND(SUM(oi.price), 2) AS faturamento,
        ROUND(AVG(oi.price), 2) AS ticket_medio,
        ROUND(AVG(r.review_score), 2) AS nota_media_avaliacao
    FROM olist_sellers_dataset s
    JOIN olist_order_items_dataset oi ON oi.seller_id = s.seller_id
    JOIN olist_orders_dataset o ON o.order_id = oi.order_id
    LEFT JOIN olist_order_reviews_dataset r ON r.order_id = o.order_id
    WHERE s.seller_id = id_vendedor
      AND o.order_purchase_timestamp BETWEEN data_inicio AND data_fim
    GROUP BY s.seller_id;
$$;

-- Exemplo de uso:
-- SELECT * FROM sp_relatorio_vendedor('id_do_vendedor_aqui', '2017-01-01', '2017-12-31');


-- H2: relatório de categoria (faturamento total, ticket médio) no período
DROP FUNCTION IF EXISTS sp_relatorio_categoria(VARCHAR, TIMESTAMP, TIMESTAMP);

CREATE OR REPLACE FUNCTION sp_relatorio_categoria(
    categoria VARCHAR,
    data_inicio TIMESTAMP,
    data_fim TIMESTAMP
)
RETURNS TABLE (
    categoria_produto VARCHAR,
    faturamento_total NUMERIC,
    ticket_medio NUMERIC
)
LANGUAGE sql
AS $$
    SELECT
        COALESCE(t.product_category_name_english, pr.product_category_name) AS categoria_produto,
        ROUND(SUM(oi.price), 2) AS faturamento_total,
        ROUND(AVG(oi.price), 2) AS ticket_medio
    FROM olist_products_dataset pr
    JOIN olist_order_items_dataset oi ON oi.product_id = pr.product_id
    JOIN olist_orders_dataset o ON o.order_id = oi.order_id
    LEFT JOIN product_category_name_translation t
        ON t.product_category_name = pr.product_category_name
    WHERE (pr.product_category_name = categoria OR t.product_category_name_english = categoria)
      AND o.order_purchase_timestamp BETWEEN data_inicio AND data_fim
    GROUP BY categoria_produto;
$$;

-- Exemplo de uso:
-- SELECT * FROM sp_relatorio_categoria('cama_mesa_banho', '2017-01-01', '2017-12-31');
