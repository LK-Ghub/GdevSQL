# GdevSQL
Através deste repositório compartilho o resultado do desafio GrowDev de SQL, desenvolvido com o conhecimento adquirido nas aulas do "Curso Introdutório de SQL", em parceria com a Edenred.
# Desafio SQL — Olist Brazilian E-Commerce (GrowMarket)

Exploração e análise do **Olist Brazilian E-Commerce Public Dataset** (~100 mil pedidos, 2016–2018) usando apenas **DQL** em PostgreSQL. O objetivo foi entender um modelo de dados sem chaves estrangeiras declaradas, escrever joins corretos e transformar a base em respostas de negócio.

- **Banco:** PostgreSQL (local) · **Cliente SQL:** DBeaver Community
- **Escopo:** somente consultas (`SELECT`, CTEs, views e funções de leitura). Nenhum dado foi alterado.

## Estrutura do repositório

| Arquivo | Conteúdo |
|---|---|
| `bloco_A.sql` | SELECT básico: filtros, `DISTINCT`, ordenações |
| `bloco_B.sql` | JOINs: categoria traduzida, atrasos, pagamentos, `LEFT JOIN`, mesmo estado |
| `bloco_C.sql` | Agregações com `GROUP BY` e `HAVING` |
| `bloco_D.sql` | Subqueries (`IN`, `NOT EXISTS`, correlacionadas) |
| `bloco_E.sql` | `CASE WHEN`: prazo, faixa de gasto, faixa de peso, tipo de pagamento |
| `bloco_F.sql` | CTEs: crescimento mensal por estado, reputação por categoria, frete por estado |
| `bloco_G.sql` | Views `vw_pedidos_completos` e `vw_avaliacoes_categoria` |
| `bloco_H.sql` | Funções de leitura `sp_relatorio_vendedor` e `sp_relatorio_categoria` |
| `bloco_I.sql` | Window functions: `RANK`, acumulado, participação, `LAG` |

Cada consulta traz um comentário de 1–2 linhas com a pergunta de negócio que responde.

## Modelo de dados (relações identificadas)

Como não há FKs declaradas, as relações foram inferidas pelos IDs em comum:

```
customers (customer_id) ──< orders (order_id) ──< order_items >── products (product_id) ──> category_translation
                                   │                   │
                                   ├──< order_payments └── sellers (seller_id)
                                   └──< order_reviews
```

Pontos de granularidade que definem se um join está certo:

- **`orders`**: 1 linha por pedido (99.440 pedidos).
- **`order_items`**: 1 linha por item (112.650 itens em 98.666 pedidos, média de 1,14 itens por pedido).
- **`order_payments`**: 1 linha por pagamento (103.886 registros). Um pedido pode ter vários, então somar pagamento junto com itens sem cuidado duplica valores.
- **`customers`**: `customer_id` é gerado por pedido; a pessoa é identificada por `customer_unique_id`. Análises de gasto por cliente usam este último.
- **`order_reviews`**: a avaliação pertence ao **pedido**, não ao produto. "Produto sem avaliação" significa "produto que só apareceu em pedidos sem avaliação".

## Validação da carga e consistência entre blocos

- Os pagamentos batem entre blocos: 103.886 registros nos joins de pagamento (B) e na classificação (E).
- Todas as consultas de faturamento (itens no bloco B, estados em C, mensal em F, vendedores em I) fecham no mesmo total: **R$ 13.591.643,70**. Ou seja, **faturamento = soma de `price` dos itens, sem frete**.
- O acumulado final de cada vendedor (I2) é igual ao seu faturamento total (I1) nos 3.095 vendedores.

## Principais insights

### 1. A demanda está concentrada no Sudeste, e a oferta ainda mais em São Paulo

| Estado | Faturamento por estado do cliente | % da demanda | % da oferta (estado do vendedor) |
|---|---|---|---|
| SP | R$ 5,20 mi | 38,3% | 64,4% |
| RJ | R$ 1,82 mi | 13,4% | 6,2% |
| MG | R$ 1,59 mi | 11,7% | 7,4% |
| RS | R$ 750 mil | 5,5% | 2,8% |
| PR | R$ 683 mil | 5,0% | 9,3% |
| Nordeste (9 estados) | R$ 1,55 mi | 11,4% | 3,4% |

- SP, RJ e MG somam 63,4% do faturamento; o Sudeste inteiro, 65,4%. O Norte responde por 2,5% (RR, o menor, tem R$ 7,8 mil).
- SP tem 1.849 dos 3.095 vendedores (59,7%). O Nordeste consome 11,4% mas fornece só 3,4%.
- Só **23 estados têm vendedores**. AL, AP, RR e TO têm clientes, mas nenhum vendedor.
- Por cidade do vendedor, **São Paulo concentra 19,9% do faturamento** e Ibitinga é a 2ª (4,6%), à frente de Curitiba (3,5%).
- **35.600 pedidos (36,1%)** têm cliente e vendedor no mesmo estado, e **88,5% deles são SP → SP**. Fora de SP, a venda local é rara (por exemplo, apenas 70 pedidos na BA).

### 2. Frete e prazo penalizam quem está longe de SP

- Frete médio por estado do cliente: **SP R$ 15,15** contra **RR R$ 42,98** (2,8×), PB R$ 42,72, RO R$ 41,07, AC R$ 40,07. Os estados mais baratos depois de SP são PR (R$ 20,53), MG (R$ 20,63) e RJ (R$ 20,96).
- **7.826 pedidos foram entregues com atraso (8,1% dos 96.477 entregues)**. O atraso médio é de 8,9 dias e a mediana, 5; 40,4% atrasam até 3 dias, mas 2.862 (36,6%) passam de 7 dias, 1.384 passam de 14 e 345 passam de 30 (máximo: 188).
- O RJ tem 21,3% dos pedidos atrasados contra 13,4% do faturamento (índice 1,58). BA (1,55), ES (1,54) e CE (1,50) também ficam acima do esperado; AL e MA chegam a 2,05, embora com poucos pedidos (95 e 141). O PR fica abaixo (0,63). *A participação no faturamento foi usada como aproximação de volume, já que a consulta de atrasos não devolve o denominador por estado.*
- **3.159 pedidos (3,2%)** têm frete maior que o valor dos itens. O frete mediano nesses casos é R$ 14,90 e a média R$ 21,59, com 164 pedidos acima de R$ 50 e um extremo de R$ 1.050. Isso indica pedidos de baixo valor onde o frete inviabiliza a compra.

### 3. Vendedores: cauda longa e forte dependência de poucos

- O **top 10 de vendedores** soma R$ 1,79 mi (**13,1%** do faturamento); nove são de SP e um da BA.
- 30 vendedores (1%) geram **25,7%** do faturamento. **130 vendedores (4,2%) geram metade**. O top 10% concentra 67,5% e o top 20%, 82,7%.
- No outro extremo: mediana de **R$ 821** por vendedor, 1.667 vendedores (53,9%) abaixo de R$ 1.000 e 416 abaixo de R$ 100. **24,3% venderam em um único mês** e a mediana é de 3 meses ativos; apenas 425 vendedores venderam em 12 meses ou mais.
- Estados com **vendedor único**: AC, AM, MA, PA e PI (participação de 100%). Em outros 7 estados o maior vendedor tem 50% ou mais (PB 84%, BA 78%, RO 75%, SE 68%, PE 61%, RN 58%, ES 53%). Em SP o mercado é pulverizado: o maior vendedor tem apenas 2,6% do estado.
- **181 vendedores (5,8%) vendem em mais de 5 categorias** e respondem por R$ 3,61 mi (**26,5%**) do faturamento; 123 são de SP e cinco estão no top 10. O maior atua em 27 categorias.
- **342 vendedores (11,1%) têm nota média abaixo de 3**, mas somam só R$ 398 mil (**2,9%**) e nenhum passa de R$ 50 mil. 151 têm nota exatamente 1,00. O risco reputacional está na cauda, não nos grandes. Vale cruzar com o volume de avaliações antes de agir.
- **Variação mensal do faturamento por vendedor:** mediana de 0%, 48,6% dos meses de alta e 47,6% de queda; 23,7% dos meses sobem mais de 100% e 22,3% caem mais de 50%. O faturamento individual é muito instável.

### 4. Categorias: o que vende, o que custa, o que é pesado

- As 5 maiores categorias em faturamento somam **39,7%**: `health_beauty` (9,3%), `watches_gifts` (8,9%), `bed_bath_table` (7,6%), `sports_leisure` (7,3%) e `computers_accessories` (6,7%).
- **Ticket médio:** `computers` lidera com R$ 1.098, seguido de `small_appliances_home_oven_and_coffee` (R$ 624) e `home_appliances_2` (R$ 476). A mediana das categorias é R$ 115. `watches_gifts` combina volume alto e ticket de R$ 201.
- **Parcelamento acompanha o preço:** `computers` tem 6,01 parcelas em média e `small_appliances_home_oven_and_coffee`, 5,49; as categorias mais baratas ficam perto de 1. A correlação entre ticket médio e número médio de parcelas é de **0,68** (73 categorias).
- **Peso:** `furniture_mattress_and_upholstery` (13,2 kg) e `office_furniture` (12,7 kg) são as mais pesadas em média; `telephony` (237 g), a mais leve. 1.891 produtos passam de 10 kg, com destaque para `moveis_escritorio` (202), `moveis_decoracao` (197) e `utilidades_domesticas` (185). O mais pesado, de `cama_mesa_banho`, tem 40,4 kg.

### 5. Reputação: móveis e itens volumosos têm as piores notas

Entre os 66 grupos de categoria com volume mínimo de avaliações (o menor tem 31; um deles reúne os produtos sem categoria):

- **Piores notas:** `diapers_and_hygiene` 3,26 (só 39 avaliações), **`office_furniture` 3,49 (1.687 avaliações, o pior caso com volume relevante)**, `fashion_male_clothing` 3,64, `fixed_telephony` 3,68 e `furniture_mattress_and_upholstery` 3,82.
- **Grandes volumes com nota mediana:** `bed_bath_table` 3,90 (11.137 avaliações), `furniture_decor` 3,90 (8.331) e `computers_accessories` 3,93 (7.849). Por serem as maiores em volume, elas puxam a reputação geral.
- **Melhores:** `books_general_interest` 4,45, `costruction_tools_tools` 4,44, `flowers` 4,42 e `books_technical` 4,37.
- Categorias mais pesadas tendem a ter nota menor (correlação de -0,21 entre peso médio e nota, fraca mas consistente com o padrão de móveis). Ticket médio e nota não se relacionam (0,10).

### 6. Pagamentos: cartão domina e o parcelamento é a regra

- Pedidos por forma de pagamento: cartão de crédito 76.505 (76,9%), boleto 19.784 (19,9%), voucher 3.866, débito 1.528 e `not_defined` 3.
- A soma (101.686) passa do total de pedidos: **2.246 pedidos usam mais de uma forma**, quase todos cartão + voucher (2.245). Também há 2.961 pedidos (3,0%) com mais de um registro de pagamento, chegando a 29 registros em um único pedido.
- Na classificação dos 103.886 pagamentos: **à vista 50,6%**, **parcelado 37,7%** e **parcelado longo (mais de 6x) 11,8%**.
- Boleto, voucher e débito são sempre à vista. Portanto o parcelamento é um fenômeno do cartão: **66,9% dos pagamentos no cartão são parcelados** e 15,9% deles passam de 6x (máximo de 24x, média de 3,5 parcelas).

### 7. Clientes: quem gasta acima da média concentra dois terços da receita

- **27.347 clientes acima do gasto médio** somam R$ 9,04 mi, ou **66,5%** do faturamento. O corte fica em torno de R$ 142; a média desse grupo é R$ 330 e a mediana, R$ 221.
- 975 clientes gastaram mais de R$ 1.000 e 7 passaram de R$ 5.000 (o maior, R$ 13.440).
- **162 produtos nunca receberam avaliação** (considerando que a avaliação é do pedido).

### 8. Sazonalidade e crescimento

- O faturamento mensal sai de R$ 120 mil em jan/2017 para **R$ 1,01 mi em nov/2017 (+52,1% sobre outubro)**, o pico de Black Friday. 19 dos 27 estados cresceram em novembro e, para 8 deles, foi o melhor mês da série. Em dezembro há queda de 26,4%.
- Em 2018 o crescimento estabiliza num patamar de **R$ 0,85–1,0 mi/mês**: mar–mai ficam perto de R$ 1 mi, e de junho a agosto o faturamento recua para R$ 855–895 mil. Mesmo assim, jan–ago/2018 (R$ 7,39 mi) supera jan–ago/2017 (R$ 3,11 mi) em **+137%**.
- **Volatilidade por estado:** dos 532 comparativos mês a mês estado a estado, 85 (16%) sobem mais de 100% e 43 (8%) caem mais de 50%. Estados pequenos oscilam muito com poucos pedidos.

## Qualidade dos dados

- **Categorias:** 610 produtos (1,9%) não têm categoria e 13 têm categoria sem tradução (`portateis_cozinha_e_preparadores_de_alimentos` e `pc_gamer`). Um `INNER JOIN` com a tabela de tradução perderia 623 produtos; por isso foi usado `LEFT JOIN`. Nos itens vendidos, 1.603 (1,4%) ficam sem categoria. Há também erros de grafia nos nomes originais (`fashio_female_clothing`, `costruction_tools_garden`, `home_confort`).
- **Cidades de vendedores:** 611 valores distintos, com 28 grafias fora do padrão (`sao paulo - sp`, `auriflama/sp`, `santa barbara d'oeste` versus `d´oeste`, até e-mail e CEP no campo cidade). Rankings por cidade precisam de normalização.
- **Pagamentos:** 3 registros `not_defined` e 2 pagamentos de cartão com 0 parcelas (classificados como à vista).
- **Pedidos:** 774 pedidos têm pagamento mas nenhum item, compatíveis com os cancelados e indisponíveis da base (625 e 609).
- **Último mês e início:** 2016 soma só R$ 49,8 mil (sem nenhuma venda em nov/2016) e set/2018 tem R$ 145. Variações percentuais nas pontas da série (como +18.417% ou -100%) são artefatos.

## Cuidados de interpretação

1. **`LAG()` compara linhas, não meses do calendário.** No bloco I, 17,2% das comparações "mês anterior" por vendedor saltam mais de um mês (o vendedor não vendeu no intervalo); no bloco F isso ocorre em 24 dos 532 comparativos (4,5%). Para uma variação estritamente mês a mês, seria preciso gerar a série de meses (`generate_series`) e preencher zeros.
2. **"Frete médio geral" no bloco F** (R$ 30,47) coincide com a média simples dos 27 estados, não com a média ponderada por pedidos. Como SP tem frete baixo e muito volume, a média ponderada é menor e mais estados ficariam "acima da média".
3. **Nota por vendedor ou categoria sem volume mínimo** exagera a cauda: muitos vendedores com nota 1,00 provavelmente têm poucas avaliações.
4. **Os 20 pedidos "mais recentes" por data de entrega (bloco A)** foram entregues entre 12/set e 17/out/2018, mas com 29 a 208 dias após a compra (média de 72). Ordenar por entrega traz para o topo os casos mais demorados, e não os pedidos mais recentes de fato.

## Como reproduzir

1. Instale PostgreSQL e DBeaver Community e crie uma conexão local.
2. Baixe o dataset no Kaggle e importe os CSVs (uma tabela por arquivo).
3. Confira a carga: contagem de linhas por tabela e tipos de dados.
4. Execute `bloco_A.sql` a `bloco_I.sql` em ordem. O bloco G cria as views usadas como base de consultas analíticas e o H cria as funções de leitura.
