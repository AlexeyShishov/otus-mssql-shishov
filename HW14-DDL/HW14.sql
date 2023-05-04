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
Индексы созданя для полей, по которым чаще всего ожидаем поиск/джойн
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

CREATE TABLE [AShishov_project].RefBooks.DocTypes
(
[ClientDocTypeID] int NOT NULL identity(1,1) CONSTRAINT PK_ClientDocs primary key,
[DocTypeName] int NOT NULL,
)

CREATE TABLE [AShishov_project].RefBooks.ClientStatuses
(
[ClientStatusID] int NOT NULL identity(1,1) CONSTRAINT PK_ClientStatuses primary key,
[ClientStatus] int NOT NULL,
)

CREATE TABLE [AShishov_project].Clients.Clients
(
[ClientID] int NOT NULL identity(1,1) CONSTRAINT PK_Clients primary key,
[ShortName] varchar(50) NOT NULL,
[Status] int REFERENCES RefBooks.ClientStatuses (ClientStatusID)
)
CREATE INDEX IDX_Clients ON [AShishov_project].Clients.Clients (ClientID,ShortName)

CREATE TABLE [AShishov_project].Clients.ClientsAddInfo
(
[ID] int NOT NULL identity(1,1) CONSTRAINT PK_ClAddInfoID primary key,
[ClientID] int REFERENCES Clients.Clients (ClientID),
[FullName] varchar(150) NOT NULL,
[ShortName] varchar(50)NOT NULL,
[NameEng] varchar(150) NULL,
[Email] varchar(50) CHECK (Email LIKE '%@%'),
[Website] xml NULL,
[Phone] varchar(15) NOT NULL, --будет свой тип данных с проверкой корректности ввода, с реализацией через CLR
[Phone2] varchar(15) NULL, --будет свой тип данных с проверкой корректности ввода, с реализацией через CLR
[BirthDate] datetime NULL,
[INN] int,
[RegCityID] int NOT NULL,
[RegAddr] xml NULL,
[FactCityID] int NOT NULL,
[TactAddr] xml NULL,
[PropertyFlags] int NOT NULL
)
CREATE INDEX IDX_ClientsAddInf ON [AShishov_project].Clients.ClientsAddInfo (ID)


CREATE TABLE [AShishov_project].Clients.ClientDocs
(
[ClientDocID] int NOT NULL identity(1,1) CONSTRAINT PK_ClientDocs primary key,
[DocType] int NOT NULL REFERENCES RefBooks.DocTypes (ClientDocTypeID),
[DocOwnerID] int REFERENCES Clients.Clients (ClientID),
[DocIssuedBy] varchar(150) NOT NULL,
[DocIssueDate] datetime DEFAULT (getdate()) NOT NULL,
[DocValidToDate] datetime DEFAULT (getdate()) NOT NULL
)
CREATE INDEX IDX_ClientDocs ON [AShishov_project].Clients.ClientDocs (ClientDocID,DocOwnerID)


/*
DROP DATABASE [AShishov_project] 
GO
*/