-- =========================================================
-- Bloco A — SELECT básico
-- =========================================================

-- A1: 20 pedidos com status delivered mais recentes, ordenados pela data de entrega
-- Pergunta de negócio: quais foram os pedidos entregues mais recentemente?
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
ORDER BY order_delivered_customer_date DESC
LIMIT 20;


-- A2: produtos de uma categoria específica, usando a tabela de tradução
-- Pergunta de negócio: quais produtos pertencem à categoria "computers_accessories"
-- (nome em inglês)? A tradução é usada para localizar o product_category_name
-- (em português) correspondente e então filtrar a tabela de produtos.
SELECT
    pr.product_id,
    pr.product_category_name,
    t.product_category_name_english,
    pr.product_weight_g
FROM olist_products_dataset pr
JOIN product_category_name_translation t
    ON t.product_category_name = pr.product_category_name
WHERE t.product_category_name_english = 'computers_accessories';
-- Troque o valor de product_category_name_english pela categoria desejada.


-- A3: métodos de pagamento distintos utilizados na base
-- Pergunta de negócio: quais formas de pagamento a Olist aceita/registrou?
SELECT DISTINCT payment_type
FROM olist_order_payments_dataset;


-- A4: produtos com peso acima de 10kg, do mais pesado para o mais leve
-- Pergunta de negócio: quais produtos são "pesados" e podem impactar o custo de frete?
SELECT
    product_id,
    product_category_name,
    product_weight_g
FROM olist_products_dataset
WHERE product_weight_g > 10000  -- 10kg = 10.000g
ORDER BY product_weight_g DESC;
