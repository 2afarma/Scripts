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

    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'Core')
        EXEC(N'CREATE SCHEMA Core AUTHORIZATION dbo');

    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'Seguranca')
        EXEC(N'CREATE SCHEMA Seguranca AUTHORIZATION dbo');

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Core' AND TABLE_NAME = 'Organizacao')
    BEGIN
        CREATE TABLE Core.Organizacao
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

        ALTER TABLE Core.Organizacao
            ADD CONSTRAINT DF_Organizacao_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Core.Organizacao
            ADD CONSTRAINT DF_Organizacao_Ativa DEFAULT (1) FOR Ativa;
        ALTER TABLE Core.Organizacao
            ADD CONSTRAINT DF_Organizacao_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Core' AND TABLE_NAME = 'Filial')
    BEGIN
        CREATE TABLE Core.Filial
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

        ALTER TABLE Core.Filial
            ADD CONSTRAINT DF_Filial_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Core.Filial
            ADD CONSTRAINT DF_Filial_Ativa DEFAULT (1) FOR Ativa;
        ALTER TABLE Core.Filial
            ADD CONSTRAINT DF_Filial_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE Core.Filial WITH CHECK
            ADD CONSTRAINT FK_Filial_Organizacao FOREIGN KEY (CodigoOrganizacao)
            REFERENCES Core.Organizacao (Codigo);
        ALTER TABLE Core.Filial CHECK CONSTRAINT FK_Filial_Organizacao;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Seguranca' AND TABLE_NAME = 'GrupoUsuario')
    BEGIN
        CREATE TABLE Seguranca.GrupoUsuario
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

        ALTER TABLE Seguranca.GrupoUsuario
            ADD CONSTRAINT DF_GrupoUsuario_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Seguranca.GrupoUsuario
            ADD CONSTRAINT DF_GrupoUsuario_Ativo DEFAULT (1) FOR Ativo;
        ALTER TABLE Seguranca.GrupoUsuario
            ADD CONSTRAINT DF_GrupoUsuario_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE Seguranca.GrupoUsuario WITH CHECK
            ADD CONSTRAINT FK_GrupoUsuario_Organizacao FOREIGN KEY (CodigoOrganizacao)
            REFERENCES Core.Organizacao (Codigo);
        ALTER TABLE Seguranca.GrupoUsuario CHECK CONSTRAINT FK_GrupoUsuario_Organizacao;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Seguranca' AND TABLE_NAME = 'Permissao')
    BEGIN
        CREATE TABLE Seguranca.Permissao
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

        ALTER TABLE Seguranca.Permissao
            ADD CONSTRAINT DF_Permissao_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Seguranca.Permissao
            ADD CONSTRAINT DF_Permissao_Ativa DEFAULT (1) FOR Ativa;
        ALTER TABLE Seguranca.Permissao
            ADD CONSTRAINT DF_Permissao_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Seguranca' AND TABLE_NAME = 'GrupoPermissao')
    BEGIN
        CREATE TABLE Seguranca.GrupoPermissao
        (
            CodigoGrupoUsuario  INT NOT NULL,
            CodigoPermissao     INT NOT NULL,
            Permitido           BIT NOT NULL,
            CadastradoEm        DATETIME2(3) NOT NULL,
            CONSTRAINT PK_GrupoPermissao PRIMARY KEY CLUSTERED
                (CodigoGrupoUsuario ASC, CodigoPermissao ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE)
        );

        ALTER TABLE Seguranca.GrupoPermissao
            ADD CONSTRAINT DF_GrupoPermissao_Permitido DEFAULT (1) FOR Permitido;
        ALTER TABLE Seguranca.GrupoPermissao
            ADD CONSTRAINT DF_GrupoPermissao_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE Seguranca.GrupoPermissao WITH CHECK
            ADD CONSTRAINT FK_GrupoPermissao_Grupo FOREIGN KEY (CodigoGrupoUsuario)
            REFERENCES Seguranca.GrupoUsuario (Codigo) ON DELETE CASCADE;
        ALTER TABLE Seguranca.GrupoPermissao CHECK CONSTRAINT FK_GrupoPermissao_Grupo;
        ALTER TABLE Seguranca.GrupoPermissao WITH CHECK
            ADD CONSTRAINT FK_GrupoPermissao_Permissao FOREIGN KEY (CodigoPermissao)
            REFERENCES Seguranca.Permissao (Codigo);
        ALTER TABLE Seguranca.GrupoPermissao CHECK CONSTRAINT FK_GrupoPermissao_Permissao;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Seguranca' AND TABLE_NAME = 'Usuario')
    BEGIN
        CREATE TABLE Seguranca.Usuario
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

        ALTER TABLE Seguranca.Usuario
            ADD CONSTRAINT DF_Usuario_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Seguranca.Usuario
            ADD CONSTRAINT DF_Usuario_SenhaIteracoes DEFAULT (100000) FOR SenhaIteracoes;
        ALTER TABLE Seguranca.Usuario
            ADD CONSTRAINT DF_Usuario_TodosPrivilegios DEFAULT (0) FOR TodosPrivilegios;
        ALTER TABLE Seguranca.Usuario
            ADD CONSTRAINT DF_Usuario_DeveAlterarSenha DEFAULT (1) FOR DeveAlterarSenha;
        ALTER TABLE Seguranca.Usuario
            ADD CONSTRAINT DF_Usuario_Ativo DEFAULT (1) FOR Ativo;
        ALTER TABLE Seguranca.Usuario
            ADD CONSTRAINT DF_Usuario_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE Seguranca.Usuario WITH CHECK
            ADD CONSTRAINT FK_Usuario_Organizacao FOREIGN KEY (CodigoOrganizacao)
            REFERENCES Core.Organizacao (Codigo);
        ALTER TABLE Seguranca.Usuario CHECK CONSTRAINT FK_Usuario_Organizacao;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Seguranca' AND TABLE_NAME = 'UsuarioGrupo')
    BEGIN
        CREATE TABLE Seguranca.UsuarioGrupo
        (
            CodigoUsuario       INT NOT NULL,
            CodigoGrupoUsuario  INT NOT NULL,
            Ativo               BIT NOT NULL,
            CadastradoEm        DATETIME2(3) NOT NULL,
            CONSTRAINT PK_UsuarioGrupo PRIMARY KEY CLUSTERED
                (CodigoUsuario ASC, CodigoGrupoUsuario ASC)
                WITH (FILLFACTOR = 97, DATA_COMPRESSION = PAGE)
        );

        ALTER TABLE Seguranca.UsuarioGrupo
            ADD CONSTRAINT DF_UsuarioGrupo_Ativo DEFAULT (1) FOR Ativo;
        ALTER TABLE Seguranca.UsuarioGrupo
            ADD CONSTRAINT DF_UsuarioGrupo_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE Seguranca.UsuarioGrupo WITH CHECK
            ADD CONSTRAINT FK_UsuarioGrupo_Usuario FOREIGN KEY (CodigoUsuario)
            REFERENCES Seguranca.Usuario (Codigo) ON DELETE CASCADE;
        ALTER TABLE Seguranca.UsuarioGrupo CHECK CONSTRAINT FK_UsuarioGrupo_Usuario;
        ALTER TABLE Seguranca.UsuarioGrupo WITH CHECK
            ADD CONSTRAINT FK_UsuarioGrupo_Grupo FOREIGN KEY (CodigoGrupoUsuario)
            REFERENCES Seguranca.GrupoUsuario (Codigo);
        ALTER TABLE Seguranca.UsuarioGrupo CHECK CONSTRAINT FK_UsuarioGrupo_Grupo;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Seguranca' AND TABLE_NAME = 'UsuarioFilial')
    BEGIN
        CREATE TABLE Seguranca.UsuarioFilial
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

        ALTER TABLE Seguranca.UsuarioFilial
            ADD CONSTRAINT DF_UsuarioFilial_Principal DEFAULT (0) FOR Principal;
        ALTER TABLE Seguranca.UsuarioFilial
            ADD CONSTRAINT DF_UsuarioFilial_Ativo DEFAULT (1) FOR Ativo;
        ALTER TABLE Seguranca.UsuarioFilial
            ADD CONSTRAINT DF_UsuarioFilial_CadastradoEm DEFAULT SYSUTCDATETIME() FOR CadastradoEm;
        ALTER TABLE Seguranca.UsuarioFilial WITH CHECK
            ADD CONSTRAINT FK_UsuarioFilial_Usuario FOREIGN KEY (CodigoUsuario)
            REFERENCES Seguranca.Usuario (Codigo) ON DELETE CASCADE;
        ALTER TABLE Seguranca.UsuarioFilial CHECK CONSTRAINT FK_UsuarioFilial_Usuario;
        ALTER TABLE Seguranca.UsuarioFilial WITH CHECK
            ADD CONSTRAINT FK_UsuarioFilial_Filial FOREIGN KEY (CodigoFilial)
            REFERENCES Core.Filial (Codigo);
        ALTER TABLE Seguranca.UsuarioFilial CHECK CONSTRAINT FK_UsuarioFilial_Filial;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'Seguranca' AND TABLE_NAME = 'EventoAuditoriaAcesso')
    BEGIN
        CREATE TABLE Seguranca.EventoAuditoriaAcesso
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

        ALTER TABLE Seguranca.EventoAuditoriaAcesso
            ADD CONSTRAINT DF_EventoAuditoriaAcesso_Id DEFAULT NEWSEQUENTIALID() FOR Id;
        ALTER TABLE Seguranca.EventoAuditoriaAcesso
            ADD CONSTRAINT DF_EventoAuditoriaAcesso_OcorridoEm DEFAULT SYSUTCDATETIME() FOR OcorridoEm;
        ALTER TABLE Seguranca.EventoAuditoriaAcesso WITH CHECK
            ADD CONSTRAINT FK_EventoAuditoriaAcesso_Usuario FOREIGN KEY (CodigoUsuario)
            REFERENCES Seguranca.Usuario (Codigo);
        ALTER TABLE Seguranca.EventoAuditoriaAcesso CHECK CONSTRAINT FK_EventoAuditoriaAcesso_Usuario;
        ALTER TABLE Seguranca.EventoAuditoriaAcesso WITH CHECK
            ADD CONSTRAINT FK_EventoAuditoriaAcesso_Filial FOREIGN KEY (CodigoFilial)
            REFERENCES Core.Filial (Codigo);
        ALTER TABLE Seguranca.EventoAuditoriaAcesso CHECK CONSTRAINT FK_EventoAuditoriaAcesso_Filial;
    END;

    IF NOT EXISTS (SELECT 1 FROM Core.Organizacao WHERE Codigo = 1)
    BEGIN
        SET IDENTITY_INSERT Core.Organizacao ON;
        INSERT INTO Core.Organizacao
            (Codigo, Id, RazaoSocial, NomeFantasia, Cnpj, Ativa,
             CodigoUsuarioCadastro, CadastradoEm)
        VALUES
            (1, NEWID(), N'2A FARMA - MATRIZ', N'2A FARMA', NULL, 1, 1, SYSUTCDATETIME());
        SET IDENTITY_INSERT Core.Organizacao OFF;
    END;

    IF NOT EXISTS (SELECT 1 FROM Core.Filial WHERE Codigo = 1)
    BEGIN
        SET IDENTITY_INSERT Core.Filial ON;
        INSERT INTO Core.Filial
            (Codigo, Id, CodigoOrganizacao, RazaoSocial, NomeFantasia,
             Ativa, CodigoUsuarioCadastro, CadastradoEm)
        VALUES
            (1, NEWID(), 1, N'2A FARMA - MATRIZ', N'2A FARMA - MATRIZ',
             1, 1, SYSUTCDATETIME());
        SET IDENTITY_INSERT Core.Filial OFF;
    END;

    IF NOT EXISTS (SELECT 1 FROM Seguranca.GrupoUsuario WHERE Codigo = 1)
    BEGIN
        SET IDENTITY_INSERT Seguranca.GrupoUsuario ON;
        INSERT INTO Seguranca.GrupoUsuario
            (Codigo, Id, CodigoOrganizacao, Nome, Descricao, Ativo,
             CodigoUsuarioCadastro, CadastradoEm)
        VALUES
            (1, NEWID(), 1, N'Administrador',
             N'Acesso administrativo completo ao ERP.', 1, 1, SYSUTCDATETIME());
        SET IDENTITY_INSERT Seguranca.GrupoUsuario OFF;
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

    INSERT INTO Seguranca.Permissao (Chave, Modulo, Nome, Ativa, CadastradoEm)
    SELECT S.Chave, S.Modulo, S.Nome, 1, SYSUTCDATETIME()
    FROM @Permissoes S
    WHERE NOT EXISTS (
        SELECT 1 FROM Seguranca.Permissao P WHERE P.Chave = S.Chave);

    IF NOT EXISTS (SELECT 1 FROM Seguranca.Usuario WHERE Codigo = 1)
    BEGIN
        SET IDENTITY_INSERT Seguranca.Usuario ON;
        INSERT INTO Seguranca.Usuario
            (Codigo, Id, CodigoOrganizacao, Login, NomeCompleto, Email,
             SenhaHash, SenhaSalt, SenhaIteracoes, TodosPrivilegios,
             DeveAlterarSenha, Ativo, CodigoUsuarioCadastro, CadastradoEm)
        VALUES
            (1, NEWID(), 1, N'admin', N'Administrador do Sistema', NULL,
             0x3BD08EF44E13D150E03CA2AACED499D4375BF5B7456AF608AF12C06C99DE75F1,
             0x85F3DE6EF8368D50B14D1D40BCBBE311AD942562CC296C41F814A1A86B730760,
             100000, 1, 1, 1, 1, SYSUTCDATETIME());
        SET IDENTITY_INSERT Seguranca.Usuario OFF;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM Seguranca.UsuarioGrupo
        WHERE CodigoUsuario = 1 AND CodigoGrupoUsuario = 1)
        INSERT INTO Seguranca.UsuarioGrupo
            (CodigoUsuario, CodigoGrupoUsuario, Ativo, CadastradoEm)
        VALUES (1, 1, 1, SYSUTCDATETIME());

    IF NOT EXISTS (
        SELECT 1 FROM Seguranca.UsuarioFilial
        WHERE CodigoUsuario = 1 AND CodigoFilial = 1)
        INSERT INTO Seguranca.UsuarioFilial
            (CodigoUsuario, CodigoFilial, Principal, Ativo, CadastradoEm)
        VALUES (1, 1, 1, 1, SYSUTCDATETIME());

    INSERT INTO Seguranca.GrupoPermissao
        (CodigoGrupoUsuario, CodigoPermissao, Permitido, CadastradoEm)
    SELECT 1, P.Codigo, 1, SYSUTCDATETIME()
    FROM Seguranca.Permissao P
    WHERE NOT EXISTS (
        SELECT 1
        FROM Seguranca.GrupoPermissao GP
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
FROM Seguranca.Usuario U
INNER JOIN Seguranca.UsuarioFilial UF ON UF.CodigoUsuario = U.Codigo
INNER JOIN Core.Filial F ON F.Codigo = UF.CodigoFilial
WHERE U.Codigo = 1;
GO
