/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/


--OPENXML
DECLARE @xmlDocument XML,
@dochandle INT;
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'D:\Мое\SQL-Otus\lesson10_XML_JSON\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
AS data;

EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] [nvarchar](100) '@Name',
	[SupplierID] [int] 'SupplierID',
	[UnitPackageID] [int] 'Package/UnitPackageID',
	[OuterPackageID] [int] 'Package/OuterPackageID',
	[QuantityPerOuter] [int] 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] [decimal](18, 3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] [int] 'LeadTimeDays',
	[IsChillerStock] [bit] 'IsChillerStock',
	[TaxRate] [decimal](18, 3) 'TaxRate',
	[UnitPrice] [decimal](18, 2) 'UnitPrice'
	);


EXEC sp_xml_removedocument @docHandle;


--Xquery

DECLARE @xmlDocument2 XML;
SET @xmlDocument2 = ( 
  SELECT * FROM OPENROWSET
  (BULK 'D:\Мое\SQL-Otus\lesson10_XML_JSON\StockItems-188-1fb5df.xml',
   SINGLE_CLOB) AS d);

SELECT 
i.Item.value('@Name[1]', 'nvarchar(100)') as [StockItemName]
,i.Item.value('SupplierID[1]', 'int') as SupplierID
,i.Item.value('(Package/UnitPackageID)[1]', 'int') as UnitPackageID
,i.Item.value('(Package/OuterPackageID)[1]', 'int') as OuterPackageID
,i.Item.value('(Package/QuantityPerOuter)[1]', 'int') as QuantityPerOuter
,i.Item.value('(Package/TypicalWeightPerUnit)[1]', '[decimal](18, 3)') as TypicalWeightPerUnit
,i.Item.value('LeadTimeDays[1]', 'int') as LeadTimeDays
,i.Item.value('IsChillerStock[1]', '[bit]') as IsChillerStock
,i.Item.value('TaxRate[1]', '[decimal](18, 3)') as TaxRate
,i.Item.value('UnitPrice[1]', '[decimal](18, 2)') as UnitPrice
FROM @xmlDocument2.nodes('/StockItems/Item') as i(Item);

-- загрузка в Warehouse.StockItems
DECLARE @srcxml XML,
	@dochandle2 INT;
SELECT @srcxml = BulkColumn
FROM OPENROWSET
(BULK 'D:\Мое\SQL-Otus\lesson10_XML_JSON\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
AS data;

EXEC sp_xml_preparedocument @docHandle2 OUTPUT, @srcxml;

WITH datatable as 
(SELECT *
FROM OPENXML(@docHandle2, N'/StockItems/Item')
WITH ( 
	[StockItemName] [nvarchar](100) '@Name',
	[SupplierID] [int] 'SupplierID',
	[UnitPackageID] [int] 'Package/UnitPackageID',
	[OuterPackageID] [int] 'Package/OuterPackageID',
	[QuantityPerOuter] [int] 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] [decimal](18, 3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] [int] 'LeadTimeDays',
	[IsChillerStock] [bit] 'IsChillerStock',
	[TaxRate] [decimal](18, 3) 'TaxRate',
	[UnitPrice] [decimal](18, 2) 'UnitPrice'
	))

MERGE WideWorldImporters.Warehouse.StockItems as si
	USING datatable as src
	ON (si.StockItemName = src.StockItemName)
	WHEN MATCHED THEN UPDATE 
		SET [SupplierID] = src.[SupplierID]
      ,[UnitPackageID] = src.[UnitPackageID]
      ,[OuterPackageID] = src.[OuterPackageID]
      ,[LeadTimeDays] = src.[LeadTimeDays]
      ,[QuantityPerOuter] = src.[QuantityPerOuter]
      ,[IsChillerStock] = src.[IsChillerStock]
      ,[TaxRate] = src.[TaxRate]
      ,[UnitPrice] = src.[UnitPrice]
      ,[TypicalWeightPerUnit] = src.[TypicalWeightPerUnit]
	WHEN NOT MATCHED THEN INSERT
		(
		[StockItemName]
		,[SupplierID]
		,[UnitPackageID]
		,[OuterPackageID]
		,[LeadTimeDays]
		,[QuantityPerOuter]
		,[IsChillerStock]
		,[TaxRate]
		,[UnitPrice]
		,[TypicalWeightPerUnit]
		,[LastEditedBy]
	  )
	  VALUES
	  (
	  src.[StockItemName]
	  ,src.[SupplierID]
	  ,src.[UnitPackageID]
	  ,src.[OuterPackageID]
	  ,src.[LeadTimeDays]
	  ,src.[QuantityPerOuter]
	  ,src.[IsChillerStock]
	  ,src.[TaxRate]
	  ,src.[UnitPrice]
	  ,src.[TypicalWeightPerUnit]
	  ,1
	  );

EXEC sp_xml_removedocument @docHandle2;
/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

-- не получилось нормально присвоить имя полю, а без него получается XML_свой ID
SELECT
StockItemName as '@Name'
,SupplierID
,UnitPackageID as 'Package/UnitPackageID'
,OuterPackageID as 'Package/OuterPackageID'
,QuantityPerOuter as 'Package/QuantityPerOuter'
,TypicalWeightPerUnit as 'Package/TypicalWeightPerUnit'
,LeadTimeDays
,IsChillerStock
,TaxRate
,UnitPrice
FROM WideWorldImporters.Warehouse.StockItems

FOR XML PATH ('Item'), root('StockItems') 
/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT
StockItemID
,StockItemName
,JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture
,ISNULL(JSON_VALUE(CustomFields, '$.Tags[0]'), '!!! No tag found !!!') as FirstTag
FROM WideWorldImporters.Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

SELECT
StockItemID
,StockItemName
,String_Agg(Tags.value, ',')
FROM WideWorldImporters.Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields, '$.Tags') Tags
WHERE Tags.value = 'Vintage'
GROUP BY StockItemID,StockItemName; 
