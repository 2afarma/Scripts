SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
USE [2A_farmaProd];
GO

IF OBJECT_ID(N'Core.Organizacao', N'U') IS NULL
    THROW 51000, 'Tabela Core.Organizacao não encontrada.', 1;
IF OBJECT_ID(N'Core.Filial', N'U') IS NULL
    THROW 51000, 'Tabela Core.Filial não encontrada.', 1;
IF OBJECT_ID(N'Seguranca.Usuario', N'U') IS NULL
    THROW 51000, 'Tabela Seguranca.Usuario não encontrada.', 1;
IF OBJECT_ID(N'Seguranca.UsuarioFilial', N'U') IS NULL
    THROW 51000, 'Tabela Seguranca.UsuarioFilial não encontrada.', 1;
IF NOT EXISTS (
    SELECT 1
    FROM Seguranca.Usuario U
    INNER JOIN Seguranca.UsuarioFilial UF ON UF.CodigoUsuario = U.Codigo
    WHERE U.Codigo = 1
      AND U.Login = N'admin'
      AND U.TodosPrivilegios = 1
      AND U.Ativo = 1
      AND UF.CodigoFilial = 1
      AND UF.Ativo = 1)
    THROW 51000, 'Usuário administrador inicial ou vínculo com a filial não foi criado.', 1;

SELECT
    N'VALIDAÇÃO CONCLUÍDA' AS Resultado,
    (SELECT COUNT(*) FROM Core.Organizacao) AS Organizacoes,
    (SELECT COUNT(*) FROM Core.Filial) AS Filiais,
    (SELECT COUNT(*) FROM Seguranca.Usuario) AS Usuarios,
    (SELECT COUNT(*) FROM Seguranca.Permissao) AS Permissoes;
GO
