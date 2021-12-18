USE [envido]
GO

IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkMasterBDM')
DROP PROCEDURE [pr_LinkMasterBDM]


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=========================================================================================


   DESCRIPTION:     Master to manage the BDM import to DL

	USE:			EXEC pr_LinkMasterBDM
    
	PARAMETERS:		 

    REVISIONS:		09/12/2021	DJF		Created 
					
-- ========================================================================================*/


CREATE PROCEDURE [dbo].[pr_LinkMasterBDM]  
	   	
AS

BEGIN

declare @ServerName nVarChar(max)
declare @EnvironmentName nVarChar(max)
SELECT @ServerName=@@SERVERNAME
if @ServerName='HLT142SQL034'
	set @EnvironmentName = 'Production'
if @ServerName='HLT439SQL014'
	set @EnvironmentName = 'Staging'
if @ServerName='HLT439SQL014\dev'
	set @EnvironmentName = 'Development'

declare @EmailSubjectMessage nVarChar(max) = ''
declare @EmailBodyMessage nVarChar (max)

Set @EmailBodyMessage = '<B>Processing BDM (' + @EnvironmentName + ')</B><BR><BR>'

BEGIN TRY

--STEP-1:  Move the data to staging ; select count(*) from tblLinkStagingBDM
Set @EmailBodyMessage = @EmailBodyMessage + 'Step 1 - Moving data from landing to staging<BR>'
EXEC envido_dl.dbo.pr_LinkStagingBDM


-- Step-2: Retrofit the observation value as needed - Found in tblLinkStagingBDM
Set @EmailBodyMessage = @EmailBodyMessage + 'Step 2 - Adding observation value to tblLinkStagingBDM<BR>'
if (@EnvironmentName = 'Development')
	EXEC envido_dl.dbo.pr_LinkObservationValue @ID = 22

-- Step-3: Import the source data to the collection on Envido_dl
Set @EmailBodyMessage = @EmailBodyMessage + 'Step 3 - Move data from staging into Envido_dl collection<BR>'
if (@EnvironmentName = 'Development')
	EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 22, @debug = 0
if (@EnvironmentName = 'Staging')
	EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 1, @debug = 0
if (@EnvironmentName = 'Production')
	EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 1, @debug = 0

-- Step-4: Retrofit the AnswerSetID to the Staging table 
Set @EmailBodyMessage = @EmailBodyMessage + 'Step 4 - Retrofit AnswerSetID - Currently done in Stage 3<BR>'
-- This is currently happening in pr_LinkStagingToCollectionSet
-- consider moving to a separte procedure 


	-- Step-5: Import the data to the SA-PCCOC Data-Linkage collection on Core
	Set @EmailBodyMessage = @EmailBodyMessage + 'Step 5 - Move data from envido_dl collection to Envido core collection<BR>'
	if (@EnvironmentName = 'Development')
		EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 23
	if (@EnvironmentName = 'Staging')
		EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 3
	if (@EnvironmentName = 'Production')
		EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 3
	
	-- Step-6:  Perform the match to SA-PCCOC to pull the identifiers and AnswerSetID's back to the linkage collection
	Set @EmailBodyMessage = @EmailBodyMessage + 'Step 6 - Not needed for cancer notification<BR>'
	-- ##### This step is not required for cancer notification #####
	--EXEC envido.dbo.pr_DLCore_DataSetMatching @ID = 1
	
	-- Step-7:  Move the matched data from Envido core data linkage collection to Envido core SCOOP collection
	Set @EmailBodyMessage = @EmailBodyMessage + 'Step 7 - Not needed for cancer notification<BR>'
	-- ##### This step is not required for cancer notification #####

	set @EmailSubjectMessage = 'Success for Cancer notification (' + @EnvironmentName + ')'

	EXEC msdb.dbo.sp_send_dbmail  
			@profile_name='PCCOC',
			@from_address= 'DLDatabase.Notification@Health.sa.gov.au',
			@recipients='operations@envido.com.au',
			@subject=@EmailSubjectMessage,
			@body_format= 'html',
			@body = @EmailBodyMessage,
			@query_result_header= 0,
			@query_result_separator='	',
			@query_result_no_padding=1,
			@exclude_query_output =0

END TRY

BEGIN CATCH

	set @EmailBodyMessage = @EmailBodyMessage + 'Cancer notification failed.'
	set @EmailSubjectMessage = 'Error in Cancer notification (' + @EnvironmentName + ')'
		
	EXEC msdb.dbo.sp_send_dbmail  
			@profile_name='PCCOC',
			@from_address= 'DLDatabase.Notification@Health.sa.gov.au',
			@recipients='operations@envido.com.au',
			@subject=@EmailSubjectMessage,
			@body_format= 'html',
			@body = @EmailBodyMessage,
			@query_result_header= 0,
			@query_result_separator='	',
			@query_result_no_padding=1,
			@exclude_query_output =0
END CATCH

END