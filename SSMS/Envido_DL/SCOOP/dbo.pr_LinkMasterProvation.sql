USE [envido_dl]
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
	Declare @Id int; Set @ID = null
	Declare @SetID int ; Set @SetID = 2

--STEP-1:  Move the data to staging ; select count(*) from tblLinkStagingProvation
	EXEC envido_dl.dbo.pr_LinkStagingProvation 

-- Step-2: Retrofit the observation value as needed
	--	Declare @ID int ; Set @SetID = 2	
	EXEC envido_dl.dbo.pr_LinkObservationValue @ID = @SetID

-- Step-3: Import the source data to the collection on Data linkage
	--	Declare @ID int ; Set @SetID = 2	
	EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = @SetID, @debug = 0

-- Step-4: Retrofit the AnswerSetID to the Staging table 

	-- This is currently happening in pr_LinkStagingToCollectionSet
	-- consider moving to a separte procedure 

-- Step-5: Import the data to the SCOOP Data-Linkage collection on Core
	
	EXEC envido_dl.dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 3
	
-- Step-6:  Perform the match to SCOOP to pull the identifiers and AnswerSetID's back to the linakge collection
	
	/****		****/
	EXEC envido.dbo.pr_DLCore_DataSetMatching @ID = 1

END