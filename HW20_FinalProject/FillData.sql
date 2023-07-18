USE AShishov_project
GO

--наполняем справочники
INSERT INTO [RefBooks].[ClientStatuses]
           ([ClientStatus])
     VALUES
           ('New'),('Active'),('Closed'),('Limited'),('Opening'),('Closing')
GO

INSERT INTO [RefBooks].[AssetTypes]
           ([AssetType])
     VALUES
           ('Bond'),('Share'),('Currency')
GO

INSERT INTO [RefBooks].[DocTypes]
           ([DocTypeName])
     VALUES
           ('Passport'),('InternalPassport'),('DrivingLicense'),('BirthCertificate'),('INN'),('SNILS')
GO

INSERT INTO [RefBooks].[OperTypes]
           ([OperType])
     VALUES
           ('Transfer'),('In'),('Out'),('Tax'),('Commission'),('Interest')
GO

INSERT INTO [RefBooks].[PaymentTypes]
           ([PaymentTypes])
     VALUES
           ('Fixed'),('Percent'),('Percent_max'),('Percent_min'),('Percent_min_max'),('Interest')
GO

INSERT INTO [RefBooks].[PayPeriodTypes]
           ([PayPeriodType])
     VALUES
           ('OneTime'),('Day'),('Month'),('Quarter'),('Year'),('Date')
GO

--возьмём тестовые данные из WideWorldImporters
INSERT INTO [Clients].[Clients] ([ClientName], [Status])
     SELECT CustomerName, 2 FROM [WideWorldImporters].[Sales].[Customers] WHERE CustomerName NOT LIKE '%Toys%'
GO

INSERT INTO [Clients].[Accounts]
           ([OwnerID], [DocName], [DateStart],[DateEnd])

           SELECT ClientID 
           ,Cast (ClientID as nvarchar) +'\0001'
		   ,GETDATE() - 3650 + (3650 * 2 * RAND() - 3650)
           ,'2030-01-01' FROM Clients.Clients 
GO

-- для упрощения используем только валюты
INSERT INTO [MainData].[Assets]
           ([ShortName])
     VALUES
           ('RUR'),('USD'),('EUR'),('GBP'),('JPY')
GO

--наполним таблицу данными об операциях
DROP TABLE IF EXISTS #Tempdata 
CREATE TABLE #Tempdata (OperType int, DateTimeCreated datetime, CreatedByUser int
           ,OperDateTime datetime, AccSource int, AccDest int
           ,Comment nvarchar(150), Asset int, Amount money, Price float
           ,PriceAsset int, IsCanceled bit)

DECLARE @number INT, @randnum float, @assetid int, @opetype int
SET @number = 1;
WHILE @number <= 100000--(SELECT count(*) FROM Clients.Clients)
BEGIN
	SET @randnum = RAND()
	SET @opetype = ABS(CHECKSUM(NEWID())%6)+1
	SET @assetid = ABS(CHECKSUM(NEWID())%(SELECT count(*) FROM Maindata.Assets))+1
	Insert into #Tempdata SELECT @opetype,
		GETDATE() - 3650 + (3650 * 2 * RAND() - 3650)
		,123
		,GETDATE() - 3650 + (3650 * 2 * RAND() - 3650)
		,ABS(CHECKSUM(NEWID())%(SELECT count(*) FROM Clients.Accounts))+1
		,ABS(CHECKSUM(NEWID())%(SELECT count(*) FROM Clients.Accounts))+1
		,'random comment '+ cast(ROUND(rand()*@number,0) as nvarchar)
		, @assetid
		, round(CASE WHEN @opetype in (1,2) THEN 1 WHEN @opetype IN (2, 3, 4, 5) THEN -1 WHEN @opetype = 6 THEN (CASE WHEN (CHECKSUM(NEWID())%10) > 4 THEN -1 ELSE 1 END) END * Rand() * 10000,2)
		,1
		, @assetid
		, 0
	SET @number = @number + 1;
END;

--SELECT max(OperDateTime), min (OperDateTime) FROM #Tempdata
--SELECT max(DateTimeCreated), min (DateTimeCreated) FROM #Tempdata

INSERT INTO [MainData].[Operations] SELECT * FROM #Tempdata 
GO
DROP TABLE IF EXISTS #Tempdata
GO

--заносим расширенные данные о пользователях

DROP TABLE IF EXISTS #Tempdata 
CREATE TABLE #Tempdata (ClientID int,FullName nvarchar(150),ShortName nvarchar(50)
	,NameEng nvarchar(150),Email nvarchar(50),Website xml
	,Phone nvarchar(15),Phone2 nvarchar(15),BirthDate datetime
	,INN int,RegCityID int,RegAddr xml
	,FactCityID int,FactAddr xml,PropertyFlags int)

DECLARE @number INT, @randnum float, @shortname nvarchar(50), @fullname nvarchar(50), @netname nvarchar(50)
SET @number = 1;
WHILE @number <= (SELECT count(*) FROM Clients.Clients)
BEGIN
	SET @fullname = (SELECT ClientName FROM Clients.Clients c WHERE c.ClientID = @number)
	SET @shortname = left(@fullname,1) + '. ' + RIGHT(@fullname, LEN(@fullname)-CHARINDEX( ' ', @fullname))
	SET @netname = left(@fullname,1) + RIGHT(@fullname, LEN(@fullname)-CHARINDEX( ' ', @fullname))
	INSERT INTO #Tempdata  ([ClientID],[FullName],[ShortName]
           ,[NameEng],[Email],[Website]
           ,[Phone],[Phone2],[BirthDate]
           ,[INN],[RegCityID],[RegAddr]
           ,[FactCityID],[FactAddr],[PropertyFlags])
	SELECT @number, @fullname, @shortname 
	,@fullname, @netname + '@bestmail.com',('<sites><facebook>www.facebook.com/'+@netname+'</facebook><reddit>www.reddit.com/u/'+@netname+'</reddit></sites>')
	,'+'+CAST(ROUND(RAND()*10,0) AS nvarchar(10)) + ' ' + CAST(ROUND(RAND()*1000,0) AS nvarchar(10))+ '-' + CAST(ROUND(RAND()*1000000,0) AS nvarchar(15)), '+'+CAST(ROUND(RAND()*10,0) AS nvarchar(10)) + ' ' + CAST(ROUND(RAND()*1000,0) AS nvarchar(10))+ '-' + CAST(ROUND(RAND()*1000000,0) AS nvarchar(15)), GETDATE() - 14600 + (7300 * 2 * RAND() - 7300)
	,CAST(ROUND(RAND()*10000,0) AS nvarchar(12))+CAST(ROUND(RAND()*10000,0) AS nvarchar(12)), 321, ('<regaddr><city>SomeCity</city><street>SomeStreet</street><building>'+CAST(ROUND(RAND()*10,0) AS nvarchar(10))+'</building></regaddr>')
	,321, ('<factaddr><city>SomeCity</city><street>SomeStreet</street><building>'+CAST(ROUND(RAND()*10,0) AS nvarchar(10))+'</building></factaddr>'),123
	
	SET @number = @number + 1
END

INSERT INTO Clients.ClientsAddInfo SELECT * FROM #Tempdata
DROP TABLE IF EXISTS #Tempdata
GO

 --!!!
/*
-- get a random datetime +/- 365 days
SELECT GETDATE() + (365 * 2 * RAND() - 365)

This generates a random number between 0-9
SELECT ABS(CHECKSUM(NEWID()) % 10)

1 through 6
SELECT ABS(CHECKSUM(NEWID()) % 6) + 1

3 through 6
SELECT ABS(CHECKSUM(NEWID()) % 4) + 3

Common formula
SELECT ABS(CHECKSUM(NEWID()) % (@max - @min + 1)) + @min

DROP TABLE IF EXISTS #Tempdata 
CREATE TABLE #Tempdata (num int)
DECLARE @number INT
SET @number = 1;
WHILE @number <= (SELECT count(*) FROM Clients.Clients)
BEGIN
	Insert into #Tempdata SELECT ABS(CHECKSUM(NEWID())%262)
	SET @number = @number + 1;
END;
SELECT * FROM #Tempdata

*/

