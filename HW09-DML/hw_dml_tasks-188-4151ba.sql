/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

USE [WideWorldImporters]
GO

-- делаем временную таблицу
Declare @temptable Table(
Name nvarchar(100) NOT NULL
,email nvarchar(100) NOT NULL
,city nvarchar(100) NOT NULL
,street nvarchar(100) NOT NULL
,postal_code nvarchar(100) NOT NULL
,Latitude FLOAT NOT NULL
,Longitude FLOAT NOT NULL
,Phone nvarchar(20) NOT NULL
);

-- закидываем в неё данные из генератора рандомных данных
INSERT into  @temptable
VALUES 
('Nissy Gouinlock','ngouinlockl@hatena.ne.jp','Braga','63736 Crescent Oaks Street','4700-005',41.5678915,-8.4219601,'(716) 7562177'),
('Jillene Woodland','jwoodland15@msn.com','Engenho','20 Novick Park','4620-207',41.2681051,-8.308171,'(623) 4016076'),
('Cissiee Duggon','cduggony@upenn.edu','Kirovskaya','8719 Columbus Road','353276',55.5834553,38.1546279,'(287) 7547845'),
('Johnna Meneux','jmeneux1@house.gov','West Palm Beach','227 Basil Crossing','33416',26.6664174,-80.0894977,'(561) 2765950'),
('Emile Elson','eelsono@kickstarter.com','Zagreb','11656 Drewry Junction','10020',45.7307005,15.9513163,'(364) 6209316');

INSERT INTO [Sales].[Customers]
           ([CustomerID]
           ,[CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[BuyingGroupID]
           ,[PrimaryContactPersonID]
           ,[AlternateContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[CreditLimit]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[DeliveryRun]
           ,[RunPosition]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryAddressLine2]
           ,[DeliveryPostalCode]
           ,[DeliveryLocation]
           ,[PostalAddressLine1]
           ,[PostalAddressLine2]
           ,[PostalPostalCode]
           ,[LastEditedBy])
     
           (SELECT
		   (SELECT MAX(CustomerID) FROM .[WideWorldImporters].[Sales].[Customers]) + ROW_NUMBER() OVER (ORDER BY Name) as custID
		   ,Name
		   ,(SELECT MAX(CustomerID) FROM .[WideWorldImporters].[Sales].[Customers]) + ROW_NUMBER() OVER (ORDER BY Name)
           ,(SELECT [CustomerCategoryID] FROM [WideWorldImporters].[Sales].[CustomerCategories] WHERE CustomerCategoryID = ROUND(10*RAND(),0))
           ,NULL
           ,(SELECT MAX(CustomerID) FROM .[WideWorldImporters].[Sales].[Customers]) + ROW_NUMBER() OVER (ORDER BY Name)
           ,NULL
           ,3
           ,ISNULL((SELECT CityID FROM Application.Cities where CityName = city) ,24690)
           ,ISNULL((SELECT CityID FROM Application.Cities where CityName = city),24690)
           ,NULL
           ,CONVERT(date, GETDATE())
           ,0.00
           ,0
           ,0
           ,7
           ,Phone
           ,Phone
           ,''
           ,''
           ,''
           ,'Unit1'
           ,Street
           ,postal_code
           ,geography::Point(Latitude, Longitude , 4326)
           ,'Unit1'
           ,Street
           ,postal_code
           ,1

		   FROM @temptable)
GO


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM [Sales].[Customers] WHERE CustomerName = 'Nissy Gouinlock'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE WideWorldImporters.[Sales].[Customers] SET DeliveryAddressLine1 = 'Suite 20' ,  PostalAddressLine1 = 'PO Box 12345' WHERE CustomerName = 'Johnna Meneux'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

-- делаем вторую временную таблицу

Declare @temptable2 Table(
Name nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL 
,email nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL
,city nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL
,street nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL
,postal_code nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL
,Latitude FLOAT NOT NULL
,Longitude FLOAT NOT NULL
,Phone nvarchar(20) COLLATE Latin1_General_100_CI_AS NOT NULL
) ;

-- закидываем в неё данные из генератора рандомных данных

INSERT into  @temptable2
VALUES 
('Nissy Gouinlock','ngouinlockl@hatena.ne.jp','Lake Havasu City','63736 Crescent Oaks Street','4700-005',41.5678915,-8.4219601,'(716) 7562177'),
('Jillene Woodland','jwoodland15@msn.com','Newlonsburg','417 Sachtjen Crossing','4620-207',41.2681051,-8.308171,'(623) 4016076'),
('Cissiee Duggon','cduggony@upenn.edu','Stockholm','37042 Killdeer Circle','353276',55.5834553,38.1546279,'(287) 7547845'),
('Johnna Meneux','jmeneux1@house.gov','Santa Monica','991 Hanson Terrace','33416',26.6664174,-80.0894977,'(561) 2765950'),
('Emile Elson','eelsono@kickstarter.com','Zahl','91319 Debra Court','10020',45.7307005,15.9513163,'(364) 6209316');

-- у 4 пользователей должны обновиться город и адрес
-- Клиент Nissy Gouinlock снова должен появиться в таблице
MERGE WideWorldImporters.[Sales].[Customers] as cust
	USING @temptable2 as src
	ON (cust.CustomerName = src.Name)
		WHEN MATCHED THEN
			UPDATE SET DeliveryAddressLine2 = Street
				,DeliveryCityID = ISNULL((SELECT TOP(1) CityID FROM Application.Cities where CityName = city) ,24690)
				,PostalCityID = ISNULL((SELECT TOP(1) CityID FROM Application.Cities where CityName = city) ,24690)
		WHEN NOT MATCHED THEN
			INSERT ([CustomerID]
           ,[CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[BuyingGroupID]
           ,[PrimaryContactPersonID]
           ,[AlternateContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[CreditLimit]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[DeliveryRun]
           ,[RunPosition]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryAddressLine2]
           ,[DeliveryPostalCode]
           ,[DeliveryLocation]
           ,[PostalAddressLine1]
           ,[PostalAddressLine2]
           ,[PostalPostalCode]
           ,[LastEditedBy])
			VALUES
           ((SELECT MAX(CustomerID) FROM .[WideWorldImporters].[Sales].[Customers]) + 1
		   ,src.Name
		   ,(SELECT MAX(CustomerID) FROM .[WideWorldImporters].[Sales].[Customers]) + 1
           ,ISNULL((SELECT [CustomerCategoryID] FROM [WideWorldImporters].[Sales].[CustomerCategories] WHERE CustomerCategoryID = ROUND(10*RAND(),0)), 1)
           ,NULL
           ,(SELECT MAX(CustomerID) FROM .[WideWorldImporters].[Sales].[Customers]) + 1
           ,NULL
           ,3
           ,ISNULL((SELECT TOP(1) CityID FROM Application.Cities where CityName = src.city),24690)
           ,ISNULL((SELECT TOP(1) CityID FROM Application.Cities where CityName = src.city),24690)
           ,NULL
           ,CONVERT(date, GETDATE())
           ,0.00
           ,0
           ,0
           ,7
           ,src.Phone
           ,src.Phone
           ,''
           ,''
           ,''
           ,'Unit1'
           ,src.Street
           ,src.postal_code
           ,geography::Point(src.Latitude, src.Longitude , 4326)
           ,'Unit1'
           ,src.Street
           ,src.postal_code
           ,1); 

--проверка - верхние 5 клиентов должны быть наши
--SELECT * FROM WideWorldImporters.Sales.Customers order BY CustomerID desc

--удалить наших новых клиентов
--DELETE FROM WideWorldImporters.Sales.Customers WHERE CustomerName in ('Nissy Gouinlock','Jillene Woodland','Cissiee Duggon','Johnna Meneux','Emile Elson')

/*	
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

-- bcp out
exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[Customers]" OUT "D:\MSSQL_DB\ExportedData\ClientExport.txt" -T -w -t;'


-- bulk insert

Create Table [WideWorldImporters].[Sales].MockClients
(id int
,Name nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL 
,email nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL
,city nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL
,street nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL
,postal_code nvarchar(100) COLLATE Latin1_General_100_CI_AS NOT NULL
,Latitude FLOAT NOT NULL
,Longitude FLOAT NOT NULL
,Phone nvarchar(20) COLLATE Latin1_General_100_CI_AS NOT NULL
);

--файл также будет в git'e
BULK INSERT [WideWorldImporters].[Sales].MockClients
FROM 'D:\MSSQL_DB\ExportedData\MOCK_DATA.csv'
WITH (
  FIELDTERMINATOR = ',',
  ROWTERMINATOR = '\n',
  FIRSTROW = 2
);

/*
вывод:
(50 rows affected)

Completion time: 2023-04-09T20:47:22.9381331+03:00
*/

