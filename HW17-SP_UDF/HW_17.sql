/*
1. Написать хранимую процедуру возвращающую
Клиента с набольшей разовой суммой покупки.

5. По уровню изоляции - сложно аргументировать без понимания всей бизнес-логики по работе с БД. 
Но если абстрагироваться, здесь и далее я использовал бы дефолтный уровень изоляции - READ COMMITTED, тк запросы нетяжёлые, исполняются быстро.
Разменивать достоверность на скорость не хотелось бы, тк в запросах типа "вывести максимальное/минимальное значение" (как в п.1) изменение одной записи может изменить весь результат.
Хотя, если для запросов из пп 2-4 это будет необходимо для бизнес логики, то использовать READ UNCOMMITTED возможно - там используются вывод среднего значения или всех значений, где влияние 1 записи будет не столь значительным
*/

USE WideWorldImporters;
GO

DROP PROCEDURE IF EXISTS sp_ClientIDWithMaxInvoiceSum
GO

CREATE PROCEDURE sp_ClientIDWithMaxInvoiceSum
AS 
	SELECT top(1) inv.CustomerID FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	GROUP BY il.InvoiceID, inv.CustomerID 
	ORDER BY SUM(il.quantity*il.UnitPrice) DESC;
GO

DROP PROCEDURE IF EXISTS sp_ClientWithMaxInvoiceSum 
GO

CREATE PROCEDURE sp_ClientWithMaxInvoiceSum
AS
	SELECT top(1) cust.CustomerID, cust.CustomerName, inv.InvoiceID, SUM(il.quantity*il.UnitPrice) as ChequeSum FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID
	GROUP BY il.InvoiceID, cust.CustomerID, cust.CustomerName, inv.InvoiceID 
	ORDER BY SUM(il.quantity*il.UnitPrice) DESC;
GO

Exec sp_ClientIDWithMaxInvoiceSum;
Exec sp_ClientWithMaxInvoiceSum;

/*
2. Написать хранимую процедуру с входящим
параметром СustomerID, выводящую сумму
покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

DROP PROCEDURE IF EXISTS sp_ShowClientInvoices
GO

CREATE PROCEDURE sp_ShowClientInvoices
	@СustomerID INT
AS
	SET NOCOUNT ON;
	SELECT cust.CustomerID, cust.CustomerName, inv.InvoiceID, SUM(il.quantity*il.UnitPrice) as ChequeSum FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID
	WHERE cust.CustomerID = @СustomerID
	GROUP BY il.InvoiceID, cust.CustomerID, cust.CustomerName, inv.InvoiceID 
	ORDER BY inv.InvoiceID;
GO

Exec sp_ShowClientInvoices 123;

/*
3. Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

DROP PROCEDURE IF EXISTS sp_AvgInvoiceSumForCust 
GO

CREATE PROCEDURE sp_AvgInvoiceSumForCust
AS
	SELECT CustomerID, Name, AVG(ChequeSum) as AvgInvoiceSum FROM
	(SELECT 
	cust.CustomerID as CustomerID,  
	cust.CustomerName as Name,
	SUM(il.quantity*il.UnitPrice) OVER (partition by inv.InvoiceID ) as ChequeSum 
	FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID) as sumdata
	GROUP BY CustomerID, Name
	ORDER BY CustomerID
GO

DROP FUNCTION IF EXISTS ufn_AvgInvoiceSumForCust; 
GO
CREATE FUNCTION ufn_AvgInvoiceSumForCust ()
RETURNS TABLE 
AS  
RETURN 
(
SELECT CustomerID, Name, AVG(ChequeSum) as AvgInvoiceSum FROM
	(SELECT 
	cust.CustomerID as CustomerID,  
	cust.CustomerName as Name,
	SUM(il.quantity*il.UnitPrice) OVER (partition by inv.InvoiceID ) as ChequeSum 
	FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID) as sumdata
	GROUP BY CustomerID, Name
)
GO

EXEC sp_AvgInvoiceSumForCust
SELECT * FROM ufn_AvgInvoiceSumForCust() ORDER BY CustomerID;
GO
/*
Query cost у обоих вариантов - 50%, планы исполнения идентичны. 
Предположу, что это вызвано тем, что внутри один и тот же запрос, и если и есть разница в скорости обработки контейнера(функция или процедура) для этого кода, то она ничтожно мала
*/

/*
4. Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.
*/
DROP FUNCTION IF EXISTS ufn_AllOrdersForClient; 
GO
CREATE FUNCTION ufn_AllOrdersForClient (@СustomerID INT)
RETURNS TABLE 
AS  
RETURN 
(
	SELECT cust.CustomerID, inv.InvoiceDate, inv.InvoiceID, SUM(il.quantity*il.UnitPrice) as ChequeSum 
	FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID
	WHERE cust.CustomerID = @СustomerID
	GROUP BY cust.CustomerID, inv.InvoiceDate, inv.InvoiceID
)
GO


SELECT c.CustomerID, CustomerName, funcuse.* FROM Sales.Customers c
CROSS APPLY (SELECT * FROM ufn_AllOrdersForClient(CustomerID)) as funcuse
ORDER BY c.CustomerID

-- наводим порядок

DROP PROCEDURE IF EXISTS sp_ClientIDWithMaxInvoiceSum
DROP PROCEDURE IF EXISTS sp_ClientWithMaxInvoiceSum
DROP PROCEDURE IF EXISTS sp_ShowClientInvoices
DROP PROCEDURE IF EXISTS sp_AvgInvoiceSumForCust 
DROP FUNCTION IF EXISTS ufn_AvgInvoiceSumForCust 
DROP FUNCTION IF EXISTS ufn_AllOrdersForClient