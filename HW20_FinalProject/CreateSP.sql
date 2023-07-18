USE AShishov_project
GO

DROP PROCEDURE IF EXISTS sp_GetClientDataByID
GO

CREATE PROCEDURE sp_GetClientDataByID @clientID int
WITH EXECUTE AS 'ReqUser'

AS SELECT
c.[ClientName]
,c.[Status]
		,ca.[FullName]
      ,ca.[ShortName]
      ,ca.[NameEng]
      ,ca.[Email]
      ,ca.[Website]
      ,ca.[Phone]
      ,ca.[Phone2]
      ,ca.[BirthDate]
      ,ca.[INN]
      ,ca.[RegCityID]
      ,ca.[RegAddr]
      ,ca.[FactCityID]
      ,ca.[FactAddr]
      ,ca.[PropertyFlags]
FROM [AShishov_project].[Clients].[Clients] c
LEFT JOIN [AShishov_project].[Clients].[ClientsAddInfo] ca on c.ClientID = ca.ClientID
WHERE c.ClientID = @clientID;

GO

-- EXEC sp_GetClientDataByID 100

DROP PROCEDURE IF EXISTS sp_AddNewClient
GO

CREATE PROCEDURE sp_AddNewClient @fullname nvarchar(150), @nameeng nvarchar(150), @email nvarchar(50), @website xml, @phone1 nvarchar(15)
	,@phone2 nvarchar(15), @birthdate datetime, @inn int, @regcityid int, @regaddr xml, @factcityid int, @factaddr xml, @propertyflags int

WITH EXECUTE AS 'ReqUser'

AS
DECLARE @shortname nvarchar(50)
DECLARE @userid int
SET @shortname = left(@fullname,1) + '. ' + RIGHT(@fullname, LEN(@fullname)-CHARINDEX( ' ', @fullname))

BEGIN TRY
INSERT INTO Clients.Clients ([ClientName]) VALUES (@fullname)
SET @userid = SCOPE_IDENTITY()

INSERT INTO [Clients].[ClientsAddInfo]
           ([ClientID], [FullName], [ShortName]
           ,[NameEng], [Email], [Website]
           ,[Phone], [Phone2], [BirthDate]
           ,[INN], [RegCityID], [RegAddr]
           ,[FactCityID], [FactAddr], [PropertyFlags])
     VALUES
		(@userid, @fullname, @shortname
		,@nameeng, @email, @website
		,@phone1, @phone2, @birthdate
		,@inn, @regcityid, @regaddr
		,@factcityid, @factaddr, @propertyflags) 

END TRY
BEGIN CATCH
	PRINT N'ERROR WHILE INSERTING DATA'
	PRINT(ERROR_MESSAGE())
END CATCH
GO


DROP PROCEDURE IF EXISTS sp_RecalculateBalancesForDate
GO
CREATE PROCEDURE sp_RecalculateBalancesForDate @DateToCalc datetime
WITH EXECUTE AS 'ReqUser'
AS 

DECLARE @acc_id int
DECLARE @asset_id int
DECLARE @balance money

BEGIN TRY
BEGIN TRANSACTION

DELETE FROM MainData.AccountBalances WHERE BalanceDate = @DateToCalc
DECLARE db_cursor CURSOR FOR
SELECT 
accs.AccountID, a.AssetID, ISNULL(ab.BalanceValue,0)
FROM Clients.Accounts accs
	LEFT JOIN MainData.Assets a ON 1=1
	LEFT JOIN MainData.AccountBalances ab ON accs.AccountID = ab.AccountID AND ab.AssetID = a.AssetID
WHERE accs.DateStart <= @DateToCalc + 1 
	AND ISNULL(ab.BalanceDate, @DateToCalc-1) = @DateToCalc - 1
--PRINT N'Opening cursor'
OPEN db_cursor
--PRINT N'Fetch first row'
FETCH NEXT FROM db_cursor INTO @acc_id,@asset_id,@balance
--PRINT N'Got data: ' + CAST(@acc_id AS NVARCHAR(30)) + ',' +  CAST(@asset_id  AS NVARCHAR(30)) + ',' +  CAST(@balance AS NVARCHAR(30))
WHILE @@FETCH_STATUS = 0  
BEGIN
	--PRINT N'inside step'
	--PRINT N'balance: ' + CAST(@balance AS NVARCHAR(30))

	SET @balance = @balance + ISNULL((SELECT sum(ISNULL(Amount,0)) FROM MainData.Operations WHERE Asset = @asset_id AND AccDest = @acc_id AND (OperDateTime > @DateToCalc AND OperDateTime < @DateToCalc + 1)) - (SELECT sum(ISNULL(Amount,0)) FROM MainData.Operations WHERE Asset = @asset_id AND AccSource = @acc_id AND (OperDateTime > @DateToCalc AND OperDateTime < @DateToCalc + 1)) ,0)
	
	--PRINT N'balance: ' + CAST(@balance AS NVARCHAR(30))
	--PRINT N'Inserting: ' + CAST(@acc_id AS NVARCHAR(30)) + ',' +  CAST(@asset_id  AS NVARCHAR(30)) + ',' +  CAST(@DateToCalc AS NVARCHAR(30)) +  ',' +  CAST(@balance AS NVARCHAR(30))
	
	INSERT INTO MainData.AccountBalances (AccountID, AssetID, BalanceDate, BalanceValue)
		SELECT @acc_id, @asset_id, @DateToCalc,@balance
		
		
	FETCH NEXT FROM db_cursor INTO @acc_id,@asset_id,@balance
	--PRINT N'Got data: ' + CAST(@acc_id AS NVARCHAR(30)) + ',' +  CAST(@asset_id  AS NVARCHAR(30)) + ',' +  CAST(@balance AS NVARCHAR(30))
END
CLOSE db_cursor  
COMMIT TRANSACTION
DEALLOCATE db_cursor 
END TRY
BEGIN CATCH
	ROLLBACK
	PRINT N'GOT ERROR, EXITING LOOP'
	PRINT(ERROR_MESSAGE())
END CATCH
GO

DROP PROCEDURE IF EXISTS sp_RecalculateAllBalances
GO

CREATE PROCEDURE sp_RecalculateAllBalances 
WITH EXECUTE AS 'ReqUser'
AS
BEGIN TRY
	DECLARE @DateToCalc datetime
	SET @DateToCalc  = '2001-01-01'
	WHILE @DateToCalc < GETDATE() - 1
	BEGIN
		EXEC sp_RecalculateBalancesForDate @DateToCalc
		PRINT N'PROCESSED DATE ' + CAST(@DateToCalc as NVARCHAR(50))
		SET @DateToCalc = @DateToCalc + 1
	END
END TRY
BEGIN CATCH
	PRINT N'GOT ERROR WHILE PROCESSING DATE ' +CAST(@DateToCalc as NVARCHAR(50))+ ', EXITING LOOP'
	PRINT(ERROR_MESSAGE())
END CATCH
GO

USE AShishov_project
GO
EXEC sp_RecalculateAllBalances

-- создаём джобу,считающую балансы за предыдущий день
USE [msdb]
GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Create_Balances', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'LELIKWINDESKTOP\Лелик', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- создаём шаг в  джобе
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Calculate_Balances', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC sp_RecalculateBalancesForDate GETDATE() - 1', 
		@database_name=N'AShishov_project', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EveryNight_1_AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230615, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=N'514a5111-6db5-4afe-8565-048253d08bd1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/*
DROP PROCEDURE IF EXISTS sp_RecalculateAllBalances
GO

CREATE PROCEDURE sp_RecalculateAllBalances
WITH EXECUTE AS 'ReqUser'
AS

DECLARE @startdate date = 2001-01-01
DECLARE @
*/

	/*
	(ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  )
	*/