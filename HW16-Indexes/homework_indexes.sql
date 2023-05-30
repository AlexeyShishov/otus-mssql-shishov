/*

Думаем какие запросы у вас будут в базе и добавляем для них индексы. Проверяем, что они используются в запросе. 

*/

-- Сначала нужно выполнить запросы из Create_DB.sql , это файл для создания БД к проекту, индексы создаются в основном скрипте



USE AShishov_project
GO

INSERT INTO [RefBooks].[ClientStatuses]
           ([ClientStatus])
     VALUES
           ('New'),('Active'),('Closed'),('Limited'),('Opening'),('Closing')
GO

--возьмём тестовые данные из WideWorldImporters
INSERT INTO [Clients].[Clients] ([ShortName], [Status])
     SELECT CustomerName, 2 FROM [WideWorldImporters].[Sales].[Customers]
GO

INSERT INTO [Clients].[Accounts]
           ([OwnerID], [DocName], [DateEnd])

           SELECT ClientID 
           ,Cast (ClientID as nvarchar) +'\0001'
           ,'2030-01-01' FROM Clients.Clients WHERE ShortName = 'Philip Walker'
GO

--в данно запросе планировщик показывал использование Index Seek
SELECT * FROM Clients.Clients WHERE ShortName = 'Philip Walker'
SELECT * FROM Clients.Accounts accs LEFT JOIN Clients.Clients as c on accs.OwnerID = c.ClientID WHERE c.ShortName = 'Philip Walker'