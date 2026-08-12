# Passo a passo — Construindo o Star Schema no Power Query

Este guia mostra como transformar a tabela única (`Financial Sample` ou similar) em um modelo dimensional dentro do Power BI.

## 1. Carregue a base original

`Página Inicial > Obter Dados` e carregue a tabela de vendas (ex.: Financial Sample). Ela chega como uma única tabela larga — essa será a base para gerar as dimensões.

## 2. Crie cada dimensão como uma "Consulta de Referência"

Para cada atributo que vira dimensão (Produto, Segmento, País, Faixa de Desconto):

1. Clique com o botão direito na consulta original → **Referência**.
2. Renomeie para `Dim_Produto` (ou o nome correspondente).
3. Selecione **apenas** a coluna do atributo (ex.: `Product`).
4. `Página Inicial > Remover Linhas > Remover Duplicatas`.
5. `Adicionar Coluna > Coluna de Índice > A partir de 1` — essa vira `ProdutoID`.
6. Reordene as colunas para deixar o ID primeiro.

Repita para `Dim_Segmento`, `Dim_Pais` e `Dim_FaixaDesconto`.

## 3. Crie a Dim_Data

1. Referencie a consulta original, mantenha só a coluna `Date`, remova duplicatas.
2. Adicione colunas calculadas: `Ano`, `Trimestre`, `Mes_Numero`, `Mes_Nome` (via `Adicionar Coluna > Data`).
3. Adicione a coluna de índice `DataID` (ou use a própria data no formato AAAAMMDD como chave).

## 4. Monte a Fato_Vendas

1. Referencie a consulta original novamente, renomeie para `Fato_Vendas`.
2. Para cada dimensão, use `Página Inicial > Combinar Consultas > Mesclar Consultas`, unindo pela coluna de texto (ex.: `Product` com `Dim_Produto[Nome_Produto]`), tipo de junção **Esquerda Externa**.
3. Expanda apenas a coluna de **ID** de cada dimensão mesclada.
4. Remova as colunas de texto originais (`Product`, `Segment`, `Country`, `Discount Band`) — elas já estão representadas pelas chaves.
5. Renomeie as colunas restantes para o padrão do modelo (`Units Sold` → `Unidades_Vendidas`, `Sales` → `Vendas_Liquidas`, etc.).

## 5. Feche e aplique

`Página Inicial > Fechar e Aplicar`.

## 6. Monte os relacionamentos

Na aba **Modelo**, arraste a chave de cada dimensão até a chave correspondente na `Fato_Vendas`. Confirme que a cardinalidade ficou **1 (dimensão) para Muitos (fato)** e a direção do filtro é única (dimensão → fato).

## 7. Organize visualmente

Arraste as dimensões ao redor da tabela fato para formar visualmente uma estrela — isso é só estético, mas ajuda muito na hora de explicar o modelo.

Pronto: seu modelo relacional/flat virou um Star Schema.
