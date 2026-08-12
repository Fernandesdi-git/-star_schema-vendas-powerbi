-- ============================================================
-- Star Schema - Cenário de Vendas (baseado no Financial Sample)
-- Fato central: Fato_Vendas
-- Dimensões: Dim_Produto, Dim_Segmento, Dim_Pais, Dim_FaixaDesconto, Dim_Data
-- ============================================================

-- ==========================
-- DIMENSÕES
-- ==========================

CREATE TABLE Dim_Produto (
    ProdutoID      INT PRIMARY KEY,
    Nome_Produto   VARCHAR(100) NOT NULL
);

CREATE TABLE Dim_Segmento (
    SegmentoID     INT PRIMARY KEY,
    Nome_Segmento  VARCHAR(100) NOT NULL
);

CREATE TABLE Dim_Pais (
    PaisID         INT PRIMARY KEY,
    Nome_Pais      VARCHAR(100) NOT NULL
);

CREATE TABLE Dim_FaixaDesconto (
    FaixaDescontoID INT PRIMARY KEY,
    Faixa_Desconto  VARCHAR(50) NOT NULL
);

CREATE TABLE Dim_Data (
    DataID         INT PRIMARY KEY,       -- formato AAAAMMDD
    Data           DATE NOT NULL,
    Ano            INT NOT NULL,
    Trimestre      INT NOT NULL,
    Mes_Numero     INT NOT NULL,
    Mes_Nome       VARCHAR(20) NOT NULL
);

-- ==========================
-- TABELA FATO
-- ==========================

CREATE TABLE Fato_Vendas (
    VendaID              INT PRIMARY KEY AUTO_INCREMENT,
    ProdutoID            INT NOT NULL,
    SegmentoID           INT NOT NULL,
    PaisID               INT NOT NULL,
    FaixaDescontoID      INT NOT NULL,
    DataID               INT NOT NULL,

    Unidades_Vendidas    INT NOT NULL,
    Preco_Fabricacao     DECIMAL(10,2),
    Preco_Venda          DECIMAL(10,2),
    Vendas_Brutas        DECIMAL(12,2),
    Descontos            DECIMAL(12,2),
    Vendas_Liquidas      DECIMAL(12,2),
    COGS                 DECIMAL(12,2),
    Lucro                DECIMAL(12,2),

    CONSTRAINT fk_produto        FOREIGN KEY (ProdutoID)       REFERENCES Dim_Produto(ProdutoID),
    CONSTRAINT fk_segmento       FOREIGN KEY (SegmentoID)      REFERENCES Dim_Segmento(SegmentoID),
    CONSTRAINT fk_pais           FOREIGN KEY (PaisID)          REFERENCES Dim_Pais(PaisID),
    CONSTRAINT fk_faixadesconto  FOREIGN KEY (FaixaDescontoID) REFERENCES Dim_FaixaDesconto(FaixaDescontoID),
    CONSTRAINT fk_data           FOREIGN KEY (DataID)          REFERENCES Dim_Data(DataID)
);

-- ==========================
-- ÍNDICES (melhoram performance de junção fato -> dimensões)
-- ==========================

CREATE INDEX idx_fato_produto   ON Fato_Vendas (ProdutoID);
CREATE INDEX idx_fato_segmento  ON Fato_Vendas (SegmentoID);
CREATE INDEX idx_fato_pais      ON Fato_Vendas (PaisID);
CREATE INDEX idx_fato_desconto  ON Fato_Vendas (FaixaDescontoID);
CREATE INDEX idx_fato_data      ON Fato_Vendas (DataID);
