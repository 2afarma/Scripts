SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

USE [2A_farmaProd];
GO

BEGIN TRY
    BEGIN TRANSACTION;

    /*
      Compatibilidade com instalações anteriores:
      transfere as tabelas dos schemas Core e Seguranca para o schema padrão.
      ALTER SCHEMA preserva dados, chaves, índices e relacionamentos.
    */
    DECLARE @SchemaOrigem SYSNAME;
    DECLARE @Tabela SYSNAME;
    DECLARE @SqlMigracao NVARCHAR(MAX);
    DECLARE @MensagemMigracao NVARCHAR(2048);

    DECLARE TabelasMigracao CURSOR LOCAL FAST_FORWARD FOR
        SELECT SchemaOrigem, Tabela
        FROM (VALUES
            (N'Core',      N'Organizacao'),
            (N'Core',      N'Filial'),
            (N'Seguranca', N'GrupoUsuario'),
            (N'Seguranca', N'Permissao'),
            (N'Seguranca', N'GrupoPermissao'),
            (N'Seguranca', N'Usuario'),
            (N'Seguranca', N'UsuarioGrupo'),
            (N'Seguranca', N'UsuarioFilial'),
            (N'Seguranca', N'EventoAuditoriaAcesso')
        ) AS Origem(SchemaOrigem, Tabela);

    OPEN TabelasMigracao;
    FETCH NEXT FROM TabelasMigracao INTO @SchemaOrigem, @Tabela;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF OBJECT_ID(
            QUOTENAME(@SchemaOrigem) + N'.' + QUOTENAME(@Tabela),
            N'U') IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'dbo.' + QUOTENAME(@Tabela), N'U') IS NOT NULL
            BEGIN
                SET @MensagemMigracao =
                    N'Conflito ao migrar a tabela ' + QUOTENAME(@Tabela) +
                    N': existem versões no schema dbo e no schema ' +
                    QUOTENAME(@SchemaOrigem) + N'.';
                THROW 51000, @MensagemMigracao, 1;
            END;

            SET @SqlMigracao =
                N'ALTER SCHEMA dbo TRANSFER ' +
                QUOTENAME(@SchemaOrigem) + N'.' + QUOTENAME(@Tabela) + N';';
            EXEC sys.sp_executesql @SqlMigracao;
        END;

        FETCH NEXT FROM TabelasMigracao INTO @SchemaOrigem, @Tabela;
    END;

    CLOSE TabelasMigracao;
    DEALLOCATE TabelasMigracao;

    IF SCHEMA_ID(N'Core') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'Core'))
        EXEC(N'DROP SCHEMA Core');

    IF SCHEMA_ID(N'Seguranca') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'Seguranca'))
        EXEC(N'DROP SCHEMA Seguranca');

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Organizacao')
    BEGIN
        CREATE TABLE Organizacao
        (
            Codigo                  INT IDENTITY(1,1) NOT NULL,
            Id                      UNIQUEIDENTIFIER NOT NULL,
            RazaoSocial             NVARCHAR(200) NOT NULL,
            NomeFantasia            NVARCHAR(200) NOT NULL,
            Cnpj                    VARCHAR(14) NULL,
            Ativa                   BIT NOT NULL,
            CodigoUsuarioCadastro   INT NULL,
            CadastradoEm            DATETIME2(3) NOT NULL,
            CodigoUsuarioAlteracao  INT NULL,
            AlteradoEm              DATETIME2(3) NULL,
            CONSTRAINT PK_Organizacao PRIMARY KEY CLUSTERED (Codigo ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE),
            CONSTRAINT UQ_Organizacao_Id UNIQUE (Id)
        );

        ALTER TABLE Organizacao
            ADD CONSTRAINT DF_Organizacao_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Organizacao
            ADD CONSTRAINT DF_Organizacao_Ativa DEFAULT (1) FOR Ativa;
        ALTER TABLE Organizacao
            ADD CONSTRAINT DF_Organizacao_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Filial')
    BEGIN
        CREATE TABLE Filial
        (
            Codigo                  INT IDENTITY(1,1) NOT NULL,
            Id                      UNIQUEIDENTIFIER NOT NULL,
            CodigoOrganizacao       INT NOT NULL,
            RazaoSocial             NVARCHAR(200) NOT NULL,
            NomeFantasia            NVARCHAR(200) NOT NULL,
            Cnpj                    VARCHAR(14) NULL,
            Latitude                DECIMAL(9,6) NULL,
            Longitude               DECIMAL(9,6) NULL,
            Ativa                   BIT NOT NULL,
            CodigoUsuarioCadastro   INT NULL,
            CadastradoEm            DATETIME2(3) NOT NULL,
            CodigoUsuarioAlteracao  INT NULL,
            AlteradoEm              DATETIME2(3) NULL,
            CONSTRAINT PK_Filial PRIMARY KEY CLUSTERED (Codigo ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE),
            CONSTRAINT UQ_Filial_Id UNIQUE (Id),
            CONSTRAINT CK_Filial_Latitude CHECK
                (Latitude IS NULL OR Latitude BETWEEN -90 AND 90),
            CONSTRAINT CK_Filial_Longitude CHECK
                (Longitude IS NULL OR Longitude BETWEEN -180 AND 180)
        );

        ALTER TABLE Filial
            ADD CONSTRAINT DF_Filial_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Filial
            ADD CONSTRAINT DF_Filial_Ativa DEFAULT (1) FOR Ativa;
        ALTER TABLE Filial
            ADD CONSTRAINT DF_Filial_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE Filial WITH CHECK
            ADD CONSTRAINT FK_Filial_Organizacao FOREIGN KEY (CodigoOrganizacao)
            REFERENCES Organizacao (Codigo);
        ALTER TABLE Filial CHECK CONSTRAINT FK_Filial_Organizacao;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'GrupoUsuario')
    BEGIN
        CREATE TABLE GrupoUsuario
        (
            Codigo                  INT IDENTITY(1,1) NOT NULL,
            Id                      UNIQUEIDENTIFIER NOT NULL,
            CodigoOrganizacao       INT NOT NULL,
            Nome                    NVARCHAR(80) NOT NULL,
            Descricao               NVARCHAR(250) NULL,
            Ativo                   BIT NOT NULL,
            CodigoUsuarioCadastro   INT NULL,
            CadastradoEm            DATETIME2(3) NOT NULL,
            CodigoUsuarioAlteracao  INT NULL,
            AlteradoEm              DATETIME2(3) NULL,
            CONSTRAINT PK_GrupoUsuario PRIMARY KEY CLUSTERED (Codigo ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE),
            CONSTRAINT UQ_GrupoUsuario_Id UNIQUE (Id),
            CONSTRAINT UQ_GrupoUsuario_Organizacao_Nome
                UNIQUE (CodigoOrganizacao, Nome)
        );

        ALTER TABLE GrupoUsuario
            ADD CONSTRAINT DF_GrupoUsuario_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE GrupoUsuario
            ADD CONSTRAINT DF_GrupoUsuario_Ativo DEFAULT (1) FOR Ativo;
        ALTER TABLE GrupoUsuario
            ADD CONSTRAINT DF_GrupoUsuario_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE GrupoUsuario WITH CHECK
            ADD CONSTRAINT FK_GrupoUsuario_Organizacao FOREIGN KEY (CodigoOrganizacao)
            REFERENCES Organizacao (Codigo);
        ALTER TABLE GrupoUsuario CHECK CONSTRAINT FK_GrupoUsuario_Organizacao;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Permissao')
    BEGIN
        CREATE TABLE Permissao
        (
            Codigo          INT IDENTITY(1,1) NOT NULL,
            Id              UNIQUEIDENTIFIER NOT NULL,
            Chave           VARCHAR(100) NOT NULL,
            Modulo          VARCHAR(40) NOT NULL,
            Nome            NVARCHAR(120) NOT NULL,
            Descricao       NVARCHAR(250) NULL,
            Ativa           BIT NOT NULL,
            CadastradoEm    DATETIME2(3) NOT NULL,
            CONSTRAINT PK_Permissao PRIMARY KEY CLUSTERED (Codigo ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE),
            CONSTRAINT UQ_Permissao_Id UNIQUE (Id),
            CONSTRAINT UQ_Permissao_Chave UNIQUE (Chave)
        );

        ALTER TABLE Permissao
            ADD CONSTRAINT DF_Permissao_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Permissao
            ADD CONSTRAINT DF_Permissao_Ativa DEFAULT (1) FOR Ativa;
        ALTER TABLE Permissao
            ADD CONSTRAINT DF_Permissao_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'GrupoPermissao')
    BEGIN
        CREATE TABLE GrupoPermissao
        (
            CodigoGrupoUsuario  INT NOT NULL,
            CodigoPermissao     INT NOT NULL,
            Permitido           BIT NOT NULL,
            CadastradoEm        DATETIME2(3) NOT NULL,
            CONSTRAINT PK_GrupoPermissao PRIMARY KEY CLUSTERED
                (CodigoGrupoUsuario ASC, CodigoPermissao ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE)
        );

        ALTER TABLE GrupoPermissao
            ADD CONSTRAINT DF_GrupoPermissao_Permitido DEFAULT (1) FOR Permitido;
        ALTER TABLE GrupoPermissao
            ADD CONSTRAINT DF_GrupoPermissao_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE GrupoPermissao WITH CHECK
            ADD CONSTRAINT FK_GrupoPermissao_Grupo FOREIGN KEY (CodigoGrupoUsuario)
            REFERENCES GrupoUsuario (Codigo) ON DELETE CASCADE;
        ALTER TABLE GrupoPermissao CHECK CONSTRAINT FK_GrupoPermissao_Grupo;
        ALTER TABLE GrupoPermissao WITH CHECK
            ADD CONSTRAINT FK_GrupoPermissao_Permissao FOREIGN KEY (CodigoPermissao)
            REFERENCES Permissao (Codigo);
        ALTER TABLE GrupoPermissao CHECK CONSTRAINT FK_GrupoPermissao_Permissao;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Usuario')
    BEGIN
        CREATE TABLE Usuario
        (
            Codigo                  INT IDENTITY(1,1) NOT NULL,
            Id                      UNIQUEIDENTIFIER NOT NULL,
            CodigoOrganizacao       INT NOT NULL,
            Login                   NVARCHAR(80) NOT NULL,
            LoginNormalizado        AS UPPER(LTRIM(RTRIM(Login))) PERSISTED,
            NomeCompleto            NVARCHAR(200) NOT NULL,
            NomeNormalizado         AS UPPER(LTRIM(RTRIM(NomeCompleto))) PERSISTED,
            Email                   NVARCHAR(254) NULL,
            SenhaHash               VARBINARY(64) NOT NULL,
            SenhaSalt               VARBINARY(64) NOT NULL,
            SenhaIteracoes          INT NOT NULL,
            TodosPrivilegios        BIT NOT NULL,
            DeveAlterarSenha        BIT NOT NULL,
            Ativo                   BIT NOT NULL,
            UltimoAcessoEm          DATETIME2(3) NULL,
            CodigoUsuarioCadastro   INT NULL,
            CadastradoEm            DATETIME2(3) NOT NULL,
            CodigoUsuarioAlteracao  INT NULL,
            AlteradoEm              DATETIME2(3) NULL,
            CONSTRAINT PK_Usuario PRIMARY KEY CLUSTERED (Codigo ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE),
            CONSTRAINT UQ_Usuario_Id UNIQUE (Id),
            CONSTRAINT UQ_Usuario_Organizacao_Login
                UNIQUE (CodigoOrganizacao, LoginNormalizado),
            CONSTRAINT CK_Usuario_SenhaIteracoes CHECK (SenhaIteracoes >= 100000)
        );

        ALTER TABLE Usuario
            ADD CONSTRAINT DF_Usuario_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Usuario
            ADD CONSTRAINT DF_Usuario_SenhaIteracoes DEFAULT (100000) FOR SenhaIteracoes;
        ALTER TABLE Usuario
            ADD CONSTRAINT DF_Usuario_TodosPrivilegios DEFAULT (0) FOR TodosPrivilegios;
        ALTER TABLE Usuario
            ADD CONSTRAINT DF_Usuario_DeveAlterarSenha DEFAULT (1) FOR DeveAlterarSenha;
        ALTER TABLE Usuario
            ADD CONSTRAINT DF_Usuario_Ativo DEFAULT (1) FOR Ativo;
        ALTER TABLE Usuario
            ADD CONSTRAINT DF_Usuario_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE Usuario WITH CHECK
            ADD CONSTRAINT FK_Usuario_Organizacao FOREIGN KEY (CodigoOrganizacao)
            REFERENCES Organizacao (Codigo);
        ALTER TABLE Usuario CHECK CONSTRAINT FK_Usuario_Organizacao;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'UsuarioGrupo')
    BEGIN
        CREATE TABLE UsuarioGrupo
        (
            CodigoUsuario       INT NOT NULL,
            CodigoGrupoUsuario  INT NOT NULL,
            Ativo               BIT NOT NULL,
            CadastradoEm        DATETIME2(3) NOT NULL,
            CONSTRAINT PK_UsuarioGrupo PRIMARY KEY CLUSTERED
                (CodigoUsuario ASC, CodigoGrupoUsuario ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE)
        );

        ALTER TABLE UsuarioGrupo
            ADD CONSTRAINT DF_UsuarioGrupo_Ativo DEFAULT (1) FOR Ativo;
        ALTER TABLE UsuarioGrupo
            ADD CONSTRAINT DF_UsuarioGrupo_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE UsuarioGrupo WITH CHECK
            ADD CONSTRAINT FK_UsuarioGrupo_Usuario FOREIGN KEY (CodigoUsuario)
            REFERENCES Usuario (Codigo) ON DELETE CASCADE;
        ALTER TABLE UsuarioGrupo CHECK CONSTRAINT FK_UsuarioGrupo_Usuario;
        ALTER TABLE UsuarioGrupo WITH CHECK
            ADD CONSTRAINT FK_UsuarioGrupo_Grupo FOREIGN KEY (CodigoGrupoUsuario)
            REFERENCES GrupoUsuario (Codigo);
        ALTER TABLE UsuarioGrupo CHECK CONSTRAINT FK_UsuarioGrupo_Grupo;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'UsuarioFilial')
    BEGIN
        CREATE TABLE UsuarioFilial
        (
            CodigoUsuario   INT NOT NULL,
            CodigoFilial    INT NOT NULL,
            Principal       BIT NOT NULL,
            Ativo           BIT NOT NULL,
            CadastradoEm    DATETIME2(3) NOT NULL,
            CONSTRAINT PK_UsuarioFilial PRIMARY KEY CLUSTERED
                (CodigoUsuario ASC, CodigoFilial ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE)
        );

        ALTER TABLE UsuarioFilial
            ADD CONSTRAINT DF_UsuarioFilial_Principal DEFAULT (0) FOR Principal;
        ALTER TABLE UsuarioFilial
            ADD CONSTRAINT DF_UsuarioFilial_Ativo DEFAULT (1) FOR Ativo;
        ALTER TABLE UsuarioFilial
            ADD CONSTRAINT DF_UsuarioFilial_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE UsuarioFilial WITH CHECK
            ADD CONSTRAINT FK_UsuarioFilial_Usuario FOREIGN KEY (CodigoUsuario)
            REFERENCES Usuario (Codigo) ON DELETE CASCADE;
        ALTER TABLE UsuarioFilial CHECK CONSTRAINT FK_UsuarioFilial_Usuario;
        ALTER TABLE UsuarioFilial WITH CHECK
            ADD CONSTRAINT FK_UsuarioFilial_Filial FOREIGN KEY (CodigoFilial)
            REFERENCES Filial (Codigo);
        ALTER TABLE UsuarioFilial CHECK CONSTRAINT FK_UsuarioFilial_Filial;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'EventoAuditoriaAcesso')
    BEGIN
        CREATE TABLE EventoAuditoriaAcesso
        (
            Codigo          BIGINT IDENTITY(1,1) NOT NULL,
            Id              UNIQUEIDENTIFIER NOT NULL,
            CodigoUsuario   INT NULL,
            CodigoFilial    INT NULL,
            TipoEvento      VARCHAR(40) NOT NULL,
            Sucesso         BIT NOT NULL,
            Ip              VARCHAR(45) NULL,
            Motivo          NVARCHAR(500) NULL,
            OcorridoEm      DATETIME2(3) NOT NULL,
            CONSTRAINT PK_EventoAuditoriaAcesso PRIMARY KEY CLUSTERED (Codigo ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE),
            CONSTRAINT UQ_EventoAuditoriaAcesso_Id UNIQUE (Id)
        );

        ALTER TABLE EventoAuditoriaAcesso
            ADD CONSTRAINT DF_EventoAuditoriaAcesso_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE EventoAuditoriaAcesso
            ADD CONSTRAINT DF_EventoAuditoriaAcesso_OcorridoEm DEFAULT SYSUTCDATETIME() FOR OcorridoEm;
        ALTER TABLE EventoAuditoriaAcesso WITH CHECK
            ADD CONSTRAINT FK_EventoAuditoriaAcesso_Usuario FOREIGN KEY (CodigoUsuario)
            REFERENCES Usuario (Codigo);
        ALTER TABLE EventoAuditoriaAcesso CHECK CONSTRAINT FK_EventoAuditoriaAcesso_Usuario;
        ALTER TABLE EventoAuditoriaAcesso WITH CHECK
            ADD CONSTRAINT FK_EventoAuditoriaAcesso_Filial FOREIGN KEY (CodigoFilial)
            REFERENCES Filial (Codigo);
        ALTER TABLE EventoAuditoriaAcesso CHECK CONSTRAINT FK_EventoAuditoriaAcesso_Filial;
    END;

    IF NOT EXISTS (SELECT 1 FROM Organizacao WHERE Codigo = 1)
    BEGIN
        SET IDENTITY_INSERT Organizacao ON;
        INSERT INTO Organizacao
            (Codigo, Id, RazaoSocial, NomeFantasia, Cnpj, Ativa,
             CodigoUsuarioCadastro, CadastradoEm)
        VALUES
            (1, NEWID(), N'2A FARMA - MATRIZ', N'2A FARMA', NULL, 1, 1, SYSUTCDATETIME());
        SET IDENTITY_INSERT Organizacao OFF;
    END;

    IF NOT EXISTS (SELECT 1 FROM Filial WHERE Codigo = 1)
    BEGIN
        SET IDENTITY_INSERT Filial ON;
        INSERT INTO Filial
            (Codigo, Id, CodigoOrganizacao, RazaoSocial, NomeFantasia,
             Ativa, CodigoUsuarioCadastro, CadastradoEm)
        VALUES
            (1, NEWID(), 1, N'2A FARMA - MATRIZ', N'2A FARMA - MATRIZ',
             1, 1, SYSUTCDATETIME());
        SET IDENTITY_INSERT Filial OFF;
    END;

    IF NOT EXISTS (SELECT 1 FROM GrupoUsuario WHERE Codigo = 1)
    BEGIN
        SET IDENTITY_INSERT GrupoUsuario ON;
        INSERT INTO GrupoUsuario
            (Codigo, Id, CodigoOrganizacao, Nome, Descricao, Ativo,
             CodigoUsuarioCadastro, CadastradoEm)
        VALUES
            (1, NEWID(), 1, N'Administrador',
             N'Acesso administrativo completo ao ERP.', 1, 1, SYSUTCDATETIME());
        SET IDENTITY_INSERT GrupoUsuario OFF;
    END;

    DECLARE @Permissoes TABLE
    (
        Chave VARCHAR(100),
        Modulo VARCHAR(40),
        Nome NVARCHAR(120)
    );

    INSERT INTO @Permissoes (Chave, Modulo, Nome)
    VALUES
        ('CADASTROS.ACESSAR', 'CADASTROS', N'Acessar cadastros'),
        ('COMPRAS.ACESSAR', 'COMPRAS', N'Acessar compras'),
        ('ESTOQUE.ACESSAR', 'ESTOQUE', N'Acessar estoque'),
        ('PREVENDA.ACESSAR', 'PREVENDA', N'Acessar pré-venda'),
        ('PDV.ACESSAR', 'PDV', N'Acessar PDV'),
        ('FISCAL.ACESSAR', 'FISCAL', N'Acessar fiscal'),
        ('SANITARIO.ACESSAR', 'SANITARIO', N'Acessar sanitário'),
        ('FINANCEIRO.ACESSAR', 'FINANCEIRO', N'Acessar financeiro'),
        ('RELATORIOS.ACESSAR', 'RELATORIOS', N'Acessar relatórios'),
        ('USUARIOS.GERENCIAR', 'SEGURANCA', N'Gerenciar usuários e permissões');

    INSERT INTO Permissao (Chave, Modulo, Nome, Ativa, CadastradoEm)
    SELECT S.Chave, S.Modulo, S.Nome, 1, SYSUTCDATETIME()
    FROM @Permissoes S
    WHERE NOT EXISTS (
        SELECT 1 FROM Permissao P WHERE P.Chave = S.Chave);

    IF NOT EXISTS (SELECT 1 FROM Usuario WHERE Codigo = 1)
    BEGIN
        SET IDENTITY_INSERT Usuario ON;
        INSERT INTO Usuario
            (Codigo, Id, CodigoOrganizacao, Login, NomeCompleto, Email,
             SenhaHash, SenhaSalt, SenhaIteracoes, TodosPrivilegios,
             DeveAlterarSenha, Ativo, CodigoUsuarioCadastro, CadastradoEm)
        VALUES
            (1, NEWID(), 1, N'admin', N'Administrador do Sistema', NULL,
             0x3BD08EF44E13D150E03CA2AACED499D4375BF5B7456AF608AF12C06C99DE75F1,
             0x85F3DE6EF8368D50B14D1D40BCBBE311AD942562CC296C41F814A1A86B730760,
             100000, 1, 1, 1, 1, SYSUTCDATETIME());
        SET IDENTITY_INSERT Usuario OFF;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM UsuarioGrupo
        WHERE CodigoUsuario = 1 AND CodigoGrupoUsuario = 1)
        INSERT INTO UsuarioGrupo
            (CodigoUsuario, CodigoGrupoUsuario, Ativo, CadastradoEm)
        VALUES (1, 1, 1, SYSUTCDATETIME());

    IF NOT EXISTS (
        SELECT 1 FROM UsuarioFilial
        WHERE CodigoUsuario = 1 AND CodigoFilial = 1)
        INSERT INTO UsuarioFilial
            (CodigoUsuario, CodigoFilial, Principal, Ativo, CadastradoEm)
        VALUES (1, 1, 1, 1, SYSUTCDATETIME());

    INSERT INTO GrupoPermissao
        (CodigoGrupoUsuario, CodigoPermissao, Permitido, CadastradoEm)
    SELECT 1, P.Codigo, 1, SYSUTCDATETIME()
    FROM Permissao P
    WHERE NOT EXISTS (
        SELECT 1
        FROM GrupoPermissao GP
        WHERE GP.CodigoGrupoUsuario = 1
          AND GP.CodigoPermissao = P.Codigo);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT
    U.Codigo,
    U.Login,
    U.NomeCompleto,
    U.TodosPrivilegios,
    F.Codigo AS CodigoFilial,
    F.NomeFantasia AS Filial
FROM Usuario U
INNER JOIN UsuarioFilial UF ON UF.CodigoUsuario = U.Codigo
INNER JOIN Filial F ON F.Codigo = UF.CodigoFilial
WHERE U.Codigo = 1;
GO
