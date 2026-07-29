SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
USE [2A_farmaProd];
GO

IF OBJECT_ID(N'Organizacao', N'U') IS NULL
    THROW 51000, 'Tabela Organizacao não encontrada.', 1;
IF OBJECT_ID(N'Filial', N'U') IS NULL
    THROW 51000, 'Tabela Filial não encontrada.', 1;
IF OBJECT_ID(N'GrupoUsuario', N'U') IS NULL
    THROW 51000, 'Tabela GrupoUsuario não encontrada.', 1;
IF OBJECT_ID(N'Permissao', N'U') IS NULL
    THROW 51000, 'Tabela Permissao não encontrada.', 1;
IF OBJECT_ID(N'GrupoPermissao', N'U') IS NULL
    THROW 51000, 'Tabela GrupoPermissao não encontrada.', 1;
IF OBJECT_ID(N'Usuario', N'U') IS NULL
    THROW 51000, 'Tabela Usuario não encontrada.', 1;
IF OBJECT_ID(N'UsuarioGrupo', N'U') IS NULL
    THROW 51000, 'Tabela UsuarioGrupo não encontrada.', 1;
IF OBJECT_ID(N'UsuarioFilial', N'U') IS NULL
    THROW 51000, 'Tabela UsuarioFilial não encontrada.', 1;
IF OBJECT_ID(N'EventoAuditoriaAcesso', N'U') IS NULL
    THROW 51000, 'Tabela EventoAuditoriaAcesso não encontrada.', 1;
IF NOT EXISTS (
    SELECT 1
    FROM Usuario U
    INNER JOIN UsuarioFilial UF ON UF.CodigoUsuario = U.Codigo
    WHERE U.Codigo = 1
      AND U.Login = N'admin'
      AND U.TodosPrivilegios = 1
      AND U.Ativo = 1
      AND UF.CodigoFilial = 1
      AND UF.Ativo = 1)
    THROW 51000, 'Usuário administrador inicial ou vínculo com a filial não foi criado.', 1;

SELECT
    N'VALIDAÇÃO CONCLUÍDA' AS Resultado,
    (SELECT COUNT(*) FROM Organizacao) AS Organizacoes,
    (SELECT COUNT(*) FROM Filial) AS Filiais,
    (SELECT COUNT(*) FROM Usuario) AS Usuarios,
    (SELECT COUNT(*) FROM Permissao) AS Permissoes;
GO
