/*
Начало проектной работы. 
Создание таблиц и представлений для своего проекта.

Нужно написать операторы DDL для создания БД вашего проекта:
1. Создать базу данных.
2. 3-4 основные таблицы для своего проекта. 
3. Первичные и внешние ключи для всех созданных таблиц.
4. 1-2 индекса на таблицы.
5. Наложите по одному ограничению в каждой таблице на ввод данных.

Обязательно (если еще нет) должно быть описание предметной области.
*/


/*
Предметная область - финансовое учреждение (банк/брокерская компания).
В полной версии будут Клиенты, их документы, счета и остатки по ним, тарифные планы и . Дополнительные таблицы - справочники (типы документов,статусов, операций и тп) и таблицы для
Операции будут влиять на остатки по счетам и будут создаваться как по запросу (переводы, вводы/выводы), так и автоматически (начисление процентов, списание периодических комиссий).
Также при создании операций определённого типа, например переводов, будут автоматически создаваться операции вроде списания комиссий за услугу.
Счёт будет привязан к тарифу, тариф будет включать несколько услуг, которые будет иметь ставку, периодичность и тип (%, фиксированная и тп)
*/

/* скрипт для создания базы - частично сгенерирован MSSQL Studio
Индексы созданы для полей, по которым чаще всего ожидаем поиск/джойн для таблиц, где ожидается хотя бы 100 тысяч записей
Ограничения на ввод - NOT NULL, местами CHECK/DEFAULT
*/

Create DATABASE [AShishov_project]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'AShishov_project', FILENAME = N'D:\MSSQL_DB\Data\AShishov_project.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'AShishov_project_log', FILENAME = N'D:\MSSQL_DB\Log\AShishov_project_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [AShishov_project] SET RECOVERY FULL 
GO
ALTER DATABASE [AShishov_project] SET  MULTI_USER 
GO
ALTER DATABASE [AShishov_project] SET  READ_WRITE 
GO

USE [AShishov_project];
GO
CREATE SCHEMA Clients;
GO
CREATE SCHEMA RefBooks;
GO
CREATE SCHEMA MainData;
GO

/* создаём справочники */
CREATE TABLE RefBooks.DocTypes
(
[ClientDocTypeID] int NOT NULL identity(1,1) CONSTRAINT PK_ClientDocs primary key,
[DocTypeName] int NOT NULL,
)

CREATE TABLE RefBooks.ClientStatuses
(
[ClientStatusID] int NOT NULL identity(1,1) CONSTRAINT PK_ClientStatuses primary key,
[ClientStatus] nvarchar(30) NOT NULL,
)

CREATE TABLE RefBooks.OperTypes
(
[OperTypeID] int NOT NULL identity(1,1) CONSTRAINT PK_OperTypes primary key,
[OperType] nvarchar(30) NOT NULL,
)

CREATE TABLE RefBooks.PaymentTypes
(
[PaymentTypeID] int NOT NULL identity(1,1) CONSTRAINT PK_PaymentTypes primary key,
[PaymentTypes] nvarchar(30) NOT NULL,
)

CREATE TABLE RefBooks.PayPeriodTypes
(
[PayPeriodTypeID] int NOT NULL identity(1,1) CONSTRAINT PK_PayPeriodTypes primary key,
[PayPeriodType] nvarchar(30) NOT NULL,
)

CREATE TABLE RefBooks.AssetTypes
(
[AssetTypeID] int NOT NULL identity(1,1) CONSTRAINT PK_AssetTypeTypes primary key,
[AssetType] nvarchar(30) NOT NULL,
)

CREATE TABLE RefBooks.Tariffs
(
[TariffID] int NOT NULL identity(1,1) CONSTRAINT PK_TariffID primary key,
[TariffName] nvarchar(100) NOT NULL,
)

/* создаём таблицы с данными о клиентах */
CREATE TABLE Clients.Clients
(
[ClientID] int NOT NULL identity(1,1) CONSTRAINT PK_Clients primary key,
[ShortName] nvarchar(50) NOT NULL,
[Status] int REFERENCES RefBooks.ClientStatuses (ClientStatusID)
)
CREATE INDEX IDX_Clients_ShortName ON Clients.Clients (ShortName)


CREATE TABLE Clients.ClientsAddInfo
(
[ClAddInfoID] int NOT NULL identity(1,1) CONSTRAINT PK_ClAddInfoID primary key,
[ClientID] int REFERENCES Clients.Clients (ClientID),
[FullName] nvarchar(150) NOT NULL,
[ShortName] nvarchar(50)NOT NULL,
[NameEng] nvarchar(150) NULL,
[Email] nvarchar(50) CHECK (Email LIKE '%@%.%'),
[Website] xml NULL,
[Phone] nvarchar(15) NOT NULL, --будет свой тип данных с проверкой корректности ввода, с реализацией через CLR
[Phone2] nvarchar(15) NULL, --будет свой тип данных с проверкой корректности ввода, с реализацией через CLR
[BirthDate] datetime NULL,
[INN] int,
[RegCityID] int NOT NULL,
[RegAddr] xml NULL,
[FactCityID] int NOT NULL,
[TactAddr] xml NULL,
[PropertyFlags] int NOT NULL
)
CREATE INDEX IDX_ClientsAddInf_ClientID ON Clients.ClientsAddInfo (ClientID)


CREATE TABLE Clients.ClientDocs
(
[ClientDocID] int NOT NULL identity(1,1) CONSTRAINT PK_ClientDocs primary key,
[DocType] int NOT NULL REFERENCES RefBooks.DocTypes (ClientDocTypeID),
[DocOwnerID] int REFERENCES Clients.Clients (ClientID),
[DocIssuedBy] nvarchar(150) NOT NULL,
[DocIssueDate] datetime DEFAULT (getdate()) NOT NULL,
[DocValidToDate] datetime DEFAULT (getdate()) NOT NULL
)
CREATE INDEX IDX_ClientDocs_DocOwnerID ON Clients.ClientDocs (DocOwnerID)


CREATE TABLE Clients.Accounts
(
[AccountID] int NOT NULL identity(1,1) CONSTRAINT PK_AccountIDs primary key,
[OwnerID] int REFERENCES Clients.Clients (ClientID) NOT NULL,
[DocName] nvarchar(50) NOT NULL,
[DateStart] datetime DEFAULT (getdate()) NOT NULL,
[DateEnd] datetime DEFAULT (getdate()) NOT NULL
)
CREATE INDEX IDX_ClientAccounts_DocName ON Clients.Accounts (DocName)
CREATE INDEX IDX_ClientAccounts_OwnerID ON Clients.Accounts (OwnerID)


CREATE TABLE Clients.ClientTariffs
(
[ClientTariffID] int NOT NULL identity(1,1) CONSTRAINT PK_ClientTariffs primary key,
[ClientID] int REFERENCES Clients.Clients (ClientID) NOT NULL,
[TariffID] int REFERENCES RefBooks.Tariffs (TariffID) NOT NULL,
[DateStart] datetime DEFAULT (getdate()) NOT NULL,
[DateEnd] datetime DEFAULT (getdate()) NOT NULL,
[AccCredit] int REFERENCES Clients.Accounts (AccountID),
[AccPayments] int REFERENCES Clients.Accounts (AccountID)
)
CREATE INDEX IDX_ClientTariffs_ClientID ON Clients.ClientTariffs (ClientID)
CREATE INDEX IDX_ClientTariffs_TariffID ON Clients.ClientTariffs (TariffID)


/* создаём таблицы с общими данными */
CREATE TABLE MainData.Assets
(
[AssetID] int NOT NULL identity(1,1) CONSTRAINT PK_Assets primary key,
[ShortName] nvarchar(50) NOT NULL
)

CREATE TABLE MainData.AssetsAddInfo
(
[AssetAddInfoID] int NOT NULL identity(1,1) CONSTRAINT PK_AssetAddInfoID primary key,
[AssetID] int REFERENCES MainData.Assets (AssetID),
[FullName] nvarchar(150) NOT NULL,
[ShortName] nvarchar(50)NOT NULL,
[ISIN] nvarchar(16) NULL,
[BaseValue] float,
[BaseValueAssetID] int REFERENCES MainData.Assets (AssetID),
[AssetType] int REFERENCES RefBooks.AssetTypes (AssetTypeID),
[IsDocumentary] bit NULL
)

CREATE TABLE MainData.Operations
(
[OperationID] int NOT NULL identity(1,1) CONSTRAINT PK_Operations primary key,
[OperType] int NOT NULL REFERENCES RefBooks.OperTypes (OperTypeID),
[DateTimeCreated] datetime DEFAULT (getdate()) NOT NULL,
[CreatedByUser] int NOT NULL REFERENCES Clients.Clients (ClientID),
[OperDateTime] datetime,
[AccSource] int,
[AccDest] int,
[Comment] nvarchar(150),
[Asset] int NOT NULL REFERENCES MainData.Assets (AssetID),
[Amount] money,
[Price] float,
[PriceAsset] int NOT NULL REFERENCES MainData.Assets (AssetID),
[IsCanceled] bit DEFAULT (0) NOT NULL
)

CREATE INDEX IDX_Operations_Asset ON MainData.Operations (Asset)
CREATE INDEX IDX_Operations_Comment ON MainData.Operations (Comment)

CREATE TABLE MainData.AccountBalances
(
[ID] int NOT NULL identity(1,1) CONSTRAINT PK_Balances primary key,
[AccountID] int REFERENCES Clients.Accounts (AccountID) NOT NULL,
[AssetID] int REFERENCES MainData.Assets (AssetID) NOT NULL,
[BalanceDate] datetime DEFAULT (getdate()) NOT NULL,
[BalanceValue] money DEFAULT (0) NOT NULL
)
CREATE INDEX IDX_Balances_AccountID ON MainData.AccountBalances (AccountID)
CREATE INDEX IDX_Balances_AssetID ON MainData.AccountBalances (AssetID)
CREATE INDEX IDX_Balances_BalanceDate ON MainData.AccountBalances (BalanceDate)

CREATE TABLE MainData.TariffServices
(
[ServiceID] int NOT NULL identity(1,1) CONSTRAINT PK_Services primary key,
[TariffID] int REFERENCES Refbooks.Tariffs (TariffID) NOT NULL,
[PaymentType] int REFERENCES RefBooks.PaymentTypes (PaymentTypeID) NOT NULL,
[PayPeriodType] int REFERENCES RefBooks.PayPeriodTypes (PayPeriodTypeID) NOT NULL,
[Rate] Float DEFAULT (0) NOT NULL
)

/*
DROP DATABASE [AShishov_project] 
GO
*/