/*

*/

Create DATABASE [DW_AShishov_project]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'AShishov_project', FILENAME = N'D:\MSSQL_DB\Data\DW_AShishov_project.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'AShishov_project_log', FILENAME = N'D:\MSSQL_DB\Log\DW_AShishov_project_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [AShishov_project] SET RECOVERY FULL 
GO
ALTER DATABASE [AShishov_project] SET  MULTI_USER 
GO
ALTER DATABASE [AShishov_project] SET  READ_WRITE 
GO

USE [DW_AShishov_project];
GO

CREATE SCHEMA ReportData;
GO


CREATE TABLE ReportData.Balances
(
[ID] int NOT NULL identity(1,1) CONSTRAINT PK_Balances primary key,
[AssetID] int,
[AssetName] nvarchar(50) NOT NULL,
[BalanceDate] datetime DEFAULT (getdate()) NOT NULL,
[BalanceValue] money DEFAULT (0) NOT NULL
)
CREATE INDEX IDX_Balances_AssetName ON ReportData.Balances (AssetName)
CREATE INDEX IDX_Balances_AssetID ON ReportData.Balances (AssetID)
CREATE INDEX IDX_Balances_BalanceDate ON ReportData.Balances (BalanceDate)

--создаём сервисного пользователя для выполнения запросов
CREATE USER ReqUser WITHOUT LOGIN;
EXEC sp_addrolemember 'db_datawriter', ReqUser
EXEC sp_addrolemember 'db_datareader', ReqUser


/* DROP DATABASE 

DECLARE @DatabaseName nvarchar(50)
SET @DatabaseName = N'AShishov_project'
DECLARE @SQL varchar(max)
SELECT @SQL = COALESCE(@SQL,'') + 'Kill ' + Convert(varchar, SPId) + ';'
FROM MASTER..SysProcesses
WHERE DBId = DB_ID(@DatabaseName) AND SPId <> @@SPId
--SELECT @SQL
EXEC(@SQL)

USE master
GO
DROP DATABASE [DW_AShishov_project] 
GO

*/