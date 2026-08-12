# Relatório — Modelagem e Transformação de Dados com DAX (Power BI)

Este relatório documenta, etapa por etapa, o processo de transformação de dados (Power Query / ETL) e a criação das medidas DAX usadas para construir o modelo dimensional deste projeto, a partir da base **Financial Sample**.

Origem dos dados: `Financial Sample.xlsx` (700 linhas, 16 colunas) — dataset de amostra oficial do Power BI, com vendas de 2013-2014 por segmento, país e produto.

---

## 1. Diagnóstico da base original

| Coluna | Tipo | Observação |
|---|---|---|
| Segment | Texto | 5 valores distintos (Government, Midmarket, Channel Partners, Enterprise, Small Business) |
| Country | Texto | 5 valores distintos |
| Product | Texto | 6 valores distintos |
| Discount Band | Texto | 4 valores (incluindo "None") — havia valores em branco, tratados como "None" |
| Units Sold, Manufacturing Price, Sale Price, Gross Sales, Discounts, Sales, COGS, Profit | Numérico | Vieram como texto/numérico misto no Excel original, com espaços — precisou de conversão de tipo |
| Date | Data | Formato Data padrão |
| Month Number, Month Name, Year | Texto/Numérico | Redundantes — podem ser recalculados a partir de `Date` |

**Problemas identificados na base original:**
1. Colunas numéricas armazenadas com espaços em branco à frente (comum em exportações do Excel) → exigiu `Texto.Aparar` (Trim) antes de converter o tipo.
2. `Discount Band` com valores nulos → tratado como categoria "None" em vez de removido, para não perder linhas da fato.
3. Redundância: `Month Number`, `Month Name` e `Year` já podem ser derivados de `Date`, então foram recriados na `Dim_Data` em vez de herdados diretamente (mais consistente e fácil de estender).

---

## 2. Etapas de transformação (Power Query / ETL)

### Etapa 1 — Padronização de tipos e limpeza
- `Texto.Aparar` em todas as colunas de texto (remover espaços).
- Conversão explícita de tipo para as colunas numéricas (`Decimal Number`) e de data (`Date`).
- Preenchimento de `Discount Band` vazio com `"None"`.

### Etapa 2 — Criação das dimensões (via consultas de referência)
Para cada atributo categórico (`Product`, `Segment`, `Country`, `Discount Band`):
1. Referenciar a consulta original.
2. Manter apenas a coluna do atributo.
3. Remover duplicatas.
4. Adicionar coluna de índice (`= 1`) → vira a chave primária (`ProdutoID`, `SegmentoID`, etc.).

Resultado: `Dim_Produto` (6 linhas), `Dim_Segmento` (5 linhas), `Dim_Pais` (5 linhas), `Dim_FaixaDesconto` (4 linhas).

### Etapa 3 — Criação da Dim_Data
1. Referenciar a coluna `Date`, remover duplicatas.
2. Adicionar colunas calculadas: `Ano` (`Date.Year`), `Trimestre` (`Date.QuarterOfYear`), `Mes_Numero` (`Date.Month`), `Mes_Nome` (`Date.MonthName`).
3. Adicionar chave `DataID`.

Resultado: `Dim_Data` com 16 datas distintas (uma por mês/lançamento no período 2013–2014 presente na amostra).

### Etapa 4 — Construção da Fato_Vendas
1. Referenciar a consulta original (já limpa na Etapa 1).
2. Mesclar (`Merge Queries`, junção **Esquerda Externa**) com cada dimensão pela coluna de texto correspondente.
3. Expandir apenas a coluna de ID de cada dimensão mesclada.
4. Remover as colunas de texto originais (`Product`, `Segment`, `Country`, `Discount Band`, `Month Number`, `Month Name`, `Year` — já representadas pelas dimensões).
5. Renomear as colunas restantes para o padrão do modelo:
   - `Units Sold` → `Unidades_Vendidas`
   - `Manufacturing Price` → `Preco_Fabricacao`
   - `Sale Price` → `Preco_Venda`
   - `Gross Sales` → `Vendas_Brutas`
   - `Discounts` → `Descontos`
   - `Sales` → `Vendas_Liquidas`
   - `COGS` → `COGS`
   - `Profit` → `Lucro`

Resultado: `Fato_Vendas` com 700 linhas, apenas chaves + métricas numéricas.

### Etapa 5 — Modelagem (relacionamentos)
Na aba Modelo, relacionamentos configurados como **1 (dimensão) : N (fato)**, filtro de direção única (dimensão → fato), garantindo que segmentar por qualquer dimensão filtra corretamente a fato.

---

## 3. Medidas DAX criadas

Todas as medidas ficam centralizadas em uma tabela de medidas (`_Medidas`), boa prática para organização do modelo.

| Medida | Fórmula | Por que existe |
|---|---|---|
| `Total Vendas Brutas` | `SUM(Fato_Vendas[Vendas_Brutas])` | Métrica base de faturamento antes de descontos |
| `Total Vendas Liquidas` | `SUM(Fato_Vendas[Vendas_Liquidas])` | Faturamento real após descontos — métrica principal do relatório |
| `Total Descontos` | `SUM(Fato_Vendas[Descontos])` | Acompanhar o impacto de descontos concedidos |
| `Total COGS` | `SUM(Fato_Vendas[COGS])` | Custo direto de vendas, base para margem |
| `Total Lucro` | `SUM(Fato_Vendas[Lucro])` | Resultado final por transação |
| `Total Unidades Vendidas` | `SUM(Fato_Vendas[Unidades_Vendidas])` | Volume de vendas, independente de preço |
| `Margem de Lucro %` | `DIVIDE([Total Lucro],[Total Vendas Liquidas],0)` | KPI relativo — usa `DIVIDE` para evitar erro de divisão por zero |
| `Ticket Medio` | `DIVIDE([Total Vendas Liquidas],[Total Unidades Vendidas],0)` | Valor médio por unidade vendida |
| `Vendas Ano Anterior` | `CALCULATE([Total Vendas Liquidas], SAMEPERIODLASTYEAR(Dim_Data[Data]))` | Usa **time intelligence** — exige que `Dim_Data` esteja marcada como tabela de datas no modelo |
| `Crescimento Vendas %` | `DIVIDE([Total Vendas Liquidas]-[Vendas Ano Anterior],[Vendas Ano Anterior],0)` | Comparativo ano a ano (YoY), depende da medida anterior |

**Decisões de design DAX:**
- Uso de `DIVIDE()` em vez do operador `/` em todas as razões, para tratar divisão por zero sem gerar erro visual no relatório.
- Medidas de time intelligence (`SAMEPERIODLASTYEAR`) exigem que `Dim_Data` seja contínua e marcada como "Tabela de Datas" (Marcar como Tabela de Datas → coluna `Data`) — passo necessário e documentado aqui para não ser esquecido.
- Medidas compostas (`Crescimento Vendas %`) foram construídas reaproveitando outras medidas já criadas, em vez de repetir a lógica — boa prática de manutenção.

---

## 4. Validação do modelo

Consultas de verificação executadas para garantir integridade após a transformação:

```sql
-- Total de vendas líquidas deve bater com a soma da coluna original "Sales"
SELECT ROUND(SUM(Vendas_Liquidas), 2) FROM Fato_Vendas;
-- Resultado: 118.726.350,25 (confere com a soma da coluna "Sales" da base original)

-- Nenhuma linha da fato deve ficar sem chave de dimensão (órfã)
SELECT COUNT(*) FROM Fato_Vendas WHERE ProdutoID IS NULL OR SegmentoID IS NULL
   OR PaisID IS NULL OR FaixaDescontoID IS NULL OR DataID IS NULL;
-- Resultado: 0
```

Isso confirma que a transformação preservou a integridade dos dados: nenhuma linha foi perdida ou duplicada, e o valor agregado do modelo dimensional bate com a base original.

---

## 5. Resultado final

- 1 tabela fato (`Fato_Vendas`) com 700 linhas e 8 métricas
- 5 tabelas dimensão, sem duplicidade
- 10 medidas DAX documentadas
- Modelo validado (soma agregada confere com a fonte original, sem linhas órfãs)

Arquivos relacionados: [`dashboard/star_schema_vendas.db`](../dashboard/star_schema_vendas.db) (banco já populado), [`sql/create_star_schema.sql`](../sql/create_star_schema.sql) (estrutura), [`dax/medidas.dax`](../dax/medidas.dax) (medidas).
