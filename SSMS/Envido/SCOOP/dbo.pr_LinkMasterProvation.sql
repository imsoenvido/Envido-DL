USE [envido]
GO

IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkMasterProvation')
DROP PROCEDURE [pr_LinkMasterProvation]


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=========================================================================================


   DESCRIPTION:     Master to manage the Provation import to DL

	USE:			EXEC pr_LinkMasterProvation
    
	PARAMETERS:		 

    REVISIONS:		13/06/2021	S.Walsh		Created 
					26/07/2021	DJF			Added in step 7
											Run the entire SP from Envido DB rather than Envido_DL DB
					
	PROCESS TO DELETE DATA FOR A FRESH LOAD:

					-- STEP-2: Clear the provation data on Envido_DL ready to test from the beginning 
							;select  * from envido_DL.dbo.tblCollection
							;select  * from envido_DL.dbo.tblset where collectionID = 2
								
						begin tran 
							delete from tblAnswer where AnswerSetID in ( Select AnswerSEtID from tblAnswerSet where setID = 2)
							delete from tblAnswerSet where setID = 2
							truncate table [2]
		
							truncate table dbo.tblLinkStagingProvation

						commit

					-- Step-3: Remove any data from DL-SCOOP-EVENTS on Envido that has previously been loaded; 
								;select  * from envido.dbo.tblCollection
								;select  * from envido.dbo.tblset where collectionID = 36

						begin tran 
		
							delete from tblAnswer where AnswerSetID in (select AnswerSetID from tblAnswerset where setID = 276)
							delete from tblAnswerset where setID = 276
							truncate table [276]
						commit

	PROCESS:		-- STEP-1: The source data is landed ; select count(*)  from tblLinkLandProvation


	DEVELOPMENT STEPS
	- Step-1 is now loading from the SP
	- Step-2 is now loading for the SP - updates the Obseravation values in Staging

-- ========================================================================================*/


CREATE PROCEDURE [dbo].[pr_LinkMasterProvation]  
	   	
AS
BEGIN

	declare @bodyMessage nVarChar (max)

	BEGIN TRY
		Declare @Id int; Set @ID = null
		Declare @ImportTableMappingID int ; Set @ImportTableMappingID = 2

		set @bodyMessage = 'SCOOP data linkage - At the start<BR><BR>'

		--STEP-1:  Move the data to staging ; select count(*) from tblLinkStagingProvation
		set @bodyMessage = @bodyMessage + 'Step-1: pr_LinkStagingProvation<BR><BR>'
		EXEC envido_dl.dbo.pr_LinkStagingProvation 

		-- Step-2: Retrofit the observation value as needed
		--	Declare @ID int ; Set @SetID = 2	
		set @bodyMessage = @bodyMessage + 'Step-2: pr_LinkObservationValue<BR><BR>'
		EXEC envido_dl.dbo.pr_LinkObservationValue @ID = @ImportTableMappingID

		-- Step-3: Import the source data to the collection on Data linkage
		--	Declare @ID int ; Set @SetID = 2	
		set @bodyMessage = @bodyMessage + 'Step-3: pr_LinkStagingToCollectionSet - Core to DL on Data linkage<BR><BR>'
		EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = @ImportTableMappingID, @debug = 0

		-- Step-4: Retrofit the AnswerSetID to the Staging table 

		set @bodyMessage = @bodyMessage + 'Step-4: Not used at this stage as this is currently happening in pr_LinkStagingToCollectionSet<BR><BR>'
		-- This is currently happening in pr_LinkStagingToCollectionSet
		-- consider moving to a separte procedure 

		-- Step-5: Import the data to the SCOOP Data-Linkage collection on Core
	
		set @bodyMessage = @bodyMessage + 'Step-5: pr_LinkStagingToCollectionSet - Copy to DL on Core<BR><BR>'
		EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 3
	
		-- Step-6:  Perform the match to SCOOP to pull the identifiers and AnswerSetID's back to the linkage collection
	
		set @bodyMessage = @bodyMessage + 'Step-6: pr_DLCore_DataSetMatching<BR><BR>'
		EXEC envido.dbo.pr_DLCore_DataSetMatching @ID = 1
	
		-- Step-7:  Move the matched data from Envido core data linkage collection to Envido core SCOOP collection
	
		set @bodyMessage = @bodyMessage + 'Step-7: pr_SCOOPMoveDLSetToCore<BR><BR>'
		EXEC envido.dbo.pr_SCOOPMoveDLSetToCore @ID = 1, @Debug = 0, @SearchAnswerSetID = 0

		set @bodyMessage = @bodyMessage + 'SCOOP data linkage - successfully completed<BR><BR>'

		EXEC msdb.dbo.sp_send_dbmail  
			@profile_name='PCCOC',
			@from_address= 'DLDatabase.Notification@Health.sa.gov.au',
			@recipients='operations@envido.com.au',
			@subject='Success for SCOOP data linkage',
			@body_format= 'html',
			@body = @bodyMessage,
			@query_result_header= 0,
			@query_result_separator='	',
			@query_result_no_padding=1,
			@exclude_query_output =0

	END TRY
	BEGIN CATCH
		EXEC msdb.dbo.sp_send_dbmail  
			@profile_name='PCCOC',
			@from_address= 'DLDatabase.Notification@Health.sa.gov.au',
			@recipients='operations@envido.com.au',
			@subject='Error in SCOOP/Provation data linkage',
			@body_format= 'html',
			@body = @bodyMessage,
			@query_result_header= 0,
			@query_result_separator='	',
			@query_result_no_padding=1,
			@exclude_query_output =0
	END CATCH 

END