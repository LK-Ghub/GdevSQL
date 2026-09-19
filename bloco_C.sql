-- =========================================================
-- Bloco C — Funções agregadas + GROUP BY + HAVING
-- =========================================================

-- C1: faturamento total por estado do cliente
-- Pergunta de negócio: quais estados geram mais receita para a Olist?
SELECT
    c.customer_state,
    SUM(oi.price) AS faturamento_total
FROM olist_customers_dataset c
JOIN olist_orders_dataset o ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON oi.order_id = o.order_id
GROUP BY c.customer_state
ORDER BY faturamento_total DESC;


-- C2: top 10 vendedores por faturamento
-- Pergunta de negócio: quem são os vendedores mais importantes em receita?
SELECT
    s.seller_id,
    s.seller_state,
    SUM(oi.price) AS faturamento_total
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_state
ORDER BY faturamento_total DESC
LIMIT 10;


-- C3: ticket médio (valor médio de item) por categoria de produto
-- Pergunta de negócio: quais categorias têm itens de maior valor médio?
SELECT
    COALESCE(t.product_category_name_english, pr.product_category_name) AS categoria,
    ROUND(AVG(oi.price), 2) AS ticket_medio
FROM olist_order_items_dataset oi
JOIN olist_products_dataset pr ON pr.product_id = oi.product_id
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = pr.product_category_name
GROUP BY categoria
ORDER BY ticket_medio DESC;


-- C4: vendedores com nota média de avaliação abaixo de 3
-- Pergunta de negócio: quais vendedores têm reputação ruim e merecem atenção?
SELECT
    s.seller_id,
    ROUND(AVG(r.review_score), 2) AS nota_media,
    COUNT(r.review_id) AS qtd_avaliacoes
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON oi.seller_id = s.seller_id
JOIN olist_order_reviews_dataset r ON r.order_id = oi.order_id
GROUP BY s.seller_id
HAVING AVG(r.review_score) < 3
ORDER BY nota_media ASC;


-- C5: quantidade de pedidos por forma de pagamento
-- Pergunta de negócio: qual forma de pagamento é mais usada pelos clientes?
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS qtd_pedidos
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY qtd_pedidos DESC;


-- C6: peso médio dos produtos por categoria
-- Pergunta de negócio: quais categorias têm produtos mais pesados em média (impacto em frete)?
SELECT
    COALESCE(t.product_category_name_english, pr.product_category_name) AS categoria,
    ROUND(AVG(pr.product_weight_g), 2) AS peso_medio_g
FROM olist_products_dataset pr
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = pr.product_category_name
WHERE pr.product_weight_g IS NOT NULL
GROUP BY categoria
ORDER BY peso_medio_g DESC;


-- C7: número médio de parcelas por categoria de produto
-- Pergunta de negócio: categorias mais caras/duráveis levam a mais parcelamento?
SELECT
    COALESCE(t.product_category_name_english, pr.product_category_name) AS categoria,
    ROUND(AVG(p.payment_installments), 2) AS media_parcelas
FROM olist_products_dataset pr
JOIN olist_order_items_dataset oi ON oi.product_id = pr.product_id
JOIN olist_order_payments_dataset p ON p.order_id = oi.order_id
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = pr.product_category_name
GROUP BY categoria
ORDER BY media_parcelas DESC;
-- Observação: como um pedido pode ter vários itens e vários registros de
-- pagamento, este cálculo pode considerar o mesmo pagamento mais de uma vez
-- quando o pedido tem múltiplos itens da mesma categoria. É uma aproximação
-- razoável para comparar categorias entre si, mas vale citar essa limitação
-- no README de insights.
