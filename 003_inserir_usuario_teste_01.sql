SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE [2A_farmaProd];
GO

/*
  Usuário destinado aos testes da tela de login.

  Login: teste01
  Senha: Teste@123
  Filial: 1 - 2A FARMA - MATRIZ
  Administrador: não

  O script pode ser executado novamente para restaurar os dados e a senha
  desse usuário de teste.
*/
BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'Usuario', N'U') IS NULL
        THROW 51000, 'Tabela Usuario não encontrada.', 1;
    IF OBJECT_ID(N'UsuarioFilial', N'U') IS NULL
        THROW 51000, 'Tabela UsuarioFilial não encontrada.', 1;
    IF OBJECT_ID(N'UsuarioGrupo', N'U') IS NULL
        THROW 51000, 'Tabela UsuarioGrupo não encontrada.', 1;
    IF NOT EXISTS (SELECT 1 FROM Organizacao WHERE Codigo = 1 AND Ativa = 1)
        THROW 51000, 'Organização 1 não encontrada ou inativa.', 1;
    IF NOT EXISTS (SELECT 1 FROM Filial WHERE Codigo = 1 AND Ativa = 1)
        THROW 51000, 'Filial 1 não encontrada ou inativa.', 1;

    DECLARE @CodigoUsuario INT;
    DECLARE @Login NVARCHAR(80) = N'teste01';
    DECLARE @NomeCompleto NVARCHAR(200) = N'Teste 01';
    DECLARE @SenhaSalt VARBINARY(32) =
        0x19CDD0AB72AB21CC8A85602D368741C1D518361774782A5CDFA024B9F7E37DDA;
    DECLARE @SenhaHash VARBINARY(32) =
        0xB3A067769418A249A9E2C42A87C3F13AB245A53638F34820F8FE9E27A14A75B2;

    SELECT @CodigoUsuario = Codigo
    FROM Usuario
    WHERE LoginNormalizado = UPPER(LTRIM(RTRIM(@Login)));

    IF @CodigoUsuario IS NULL
    BEGIN
        INSERT INTO Usuario
        (
            Id,
            CodigoOrganizacao,
            Login,
            NomeCompleto,
            Email,
            SenhaHash,
            SenhaSalt,
            SenhaIteracoes,
            TodosPrivilegios,
            DeveAlterarSenha,
            Ativo,
            CodigoUsuarioCadastro,
            CadastradoEm
        )
        VALUES
        (
            NEWID(),
            1,
            @Login,
            @NomeCompleto,
            NULL,
            @SenhaHash,
            @SenhaSalt,
            100000,
            0,
            0,
            1,
            1,
            SYSUTCDATETIME()
        );

        SET @CodigoUsuario = CONVERT(INT, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE Usuario
        SET
            CodigoOrganizacao = 1,
            Login = @Login,
            NomeCompleto = @NomeCompleto,
            SenhaHash = @SenhaHash,
            SenhaSalt = @SenhaSalt,
            SenhaIteracoes = 100000,
            TodosPrivilegios = 0,
            DeveAlterarSenha = 0,
            Ativo = 1,
            CodigoUsuarioAlteracao = 1,
            AlteradoEm = SYSUTCDATETIME()
        WHERE Codigo = @CodigoUsuario;
    END;

    -- O usuário de teste não recebe grupo nem permissões administrativas.
    DELETE FROM UsuarioGrupo
    WHERE CodigoUsuario = @CodigoUsuario;

    IF EXISTS (
        SELECT 1
        FROM UsuarioFilial
        WHERE CodigoUsuario = @CodigoUsuario
          AND CodigoFilial = 1)
    BEGIN
        UPDATE UsuarioFilial
        SET Principal = 1, Ativo = 1
        WHERE CodigoUsuario = @CodigoUsuario
          AND CodigoFilial = 1;
    END
    ELSE
    BEGIN
        INSERT INTO UsuarioFilial
            (CodigoUsuario, CodigoFilial, Principal, Ativo, CadastradoEm)
        VALUES
            (@CodigoUsuario, 1, 1, 1, SYSUTCDATETIME());
    END;

    COMMIT TRANSACTION;

    SELECT
        U.Codigo,
        U.Login,
        U.NomeCompleto,
        U.TodosPrivilegios AS Administrador,
        UF.CodigoFilial,
        UF.Principal,
        U.Ativo
    FROM Usuario U
    INNER JOIN UsuarioFilial UF ON UF.CodigoUsuario = U.Codigo
    WHERE U.Codigo = @CodigoUsuario
      AND UF.CodigoFilial = 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
