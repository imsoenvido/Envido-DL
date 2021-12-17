USE envido_dl 


IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkCreateMaster')
DROP PROCEDURE [pr_LinkCreateMaster]
GO 

SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*=========================================================================================
    DESCRIPTION:	For each new data linkage various things need to be setup.
					What needs to be setup depends on how the data linkage will work.
					Potential options are
					- Is this a brand new data linkage?
					- Is this a data linkage that could potentially be used by multiple systems?
					- Is this a data linkage that is being added to an existign system?
					
					The following tables/data may need to be created
						- new data linkage collection in envido_dl database
						- new data linkage collection in envido database
						- new record in tblLinkImportMappingTable
						- numerous new records in tblLinkImportMappingFields
						- Add a new record to tblCoreDLSetMatching
					
					BEFORE THIS IS RUN EACH OF THE SP's WILL NEED TO BE REIEWED TO MAKE SURE THEY
					WILL DO WHAT IS INTENDED.
					THE INITIAL COLLECTION/SET NAMES etc WILL NEED TO BE CHANGED
					YES, THIS IS A PARTIAL AUTOMATION OF A MANUAL PROCESS

    USE:            EXEC dbo.pr_LinkCreateMaster
					
    REVISIONS:		10/12/2021	DJF			Created

					 			
   ========================================================================================*/


CREATE PROCEDURE [dbo].[pr_LinkCreateMaster] 
	
AS
BEGIN

Declare @EnvironmentName nVarChar(max)
exec pr_LinkWhichServer @EnvironmentName OUTPUT

-- ###### STEP 1 - Create new data linkage collection in envido_dl database ######
print 'STEP 1 - Create new data linkage collection in envido_dl database'

-- Setup all of the variables to be passed to the create SP
Declare @CollectionName NVARCHAR(100) = 'BDM'
Declare @CollectionDescription NVARCHAR(800) = 'Births, Deaths and Marriages'
Declare @CollectionRationale NVARCHAR(800) = 'Data from Births, Deaths and Marriages'
Declare @ToDate datetime = DATEADD(year, 1, getdate())
Declare @type smallint = 0
Declare @addedby int
Declare @lastmodifiedby int
Declare @AccountIDEnvidoDLOnEnvidoDLDB varchar(100)

if (@EnvironmentName = 'Development')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountIDEnvidoDLOnEnvidoDLDB = '2344886c-6d2f-443a-abee-93a31d83987b'
	END

if (@EnvironmentName = 'Staging')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountIDEnvidoDLOnEnvidoDLDB = '2344886c-6d2f-443a-abee-93a31d83987b'
	END

if (@EnvironmentName = 'Production')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountIDEnvidoDLOnEnvidoDLDB = '2344886c-6d2f-443a-abee-93a31d83987b'
	END

Declare @setname nvarchar(100) = 'BDM'
Declare @tblLinkStagingName nVarChar(max) = 'tblLinkStagingBDM'
Declare @Debug int = 0
Declare @NewCollectionIDOnEnvidoDL int
Declare @NewSetIDOnEnvidoDL int
Declare @DefaultUserIDEnvidoDL int = 28		-- SA-PCCOC Data Linkage username for the Envido DL collection on Envido core DB
Declare @DefaultUserIDEnvido int = 59		-- SA-PCCOC collection project userID on Envido core DB

exec envido_dl.dbo.pr_LinkCreateEnvidoDLCollectionOnEnvidoDLDB	@CollectionName, @CollectionDescription, @CollectionRationale, @ToDate, @type, 
																@addedby, @lastmodifiedby, @AccountIDEnvidoDLOnEnvidoDLDB, @setname, @tblLinkStagingName, @Debug, 
																@NewCollectionIDOnEnvidoDL OUTPUT, @NewSetIDOnEnvidoDL OUTPUT




-- ###### STEP 2 - Create new data linkage collection in envido database ######
-- NOTE: Before this is run you wll need to determine if this is needed.
-- If there is already a DL collection in Envido for this account then a new collection may not be needed
print 'STEP 2 - Create new data linkage collection in envido database - Not needed for BDM collection - will use the current DL collection'

Declare @AccountIDEnvidoDLOnEnvidoDB varchar(100)
Declare @AccountIDEnvidoOnEnvidoDB varchar(100)

if (@EnvironmentName = 'Development')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountIDEnvidoDLOnEnvidoDB = '6e2bd4c4-fc61-42e2-9fc3-6365616f4d18'
	set @AccountIDEnvidoOnEnvidoDB = '6e2bd4c4-fc61-42e2-9fc3-6365616f4d18'
	END

if (@EnvironmentName = 'Staging')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountIDEnvidoDLOnEnvidoDB = '6e2bd4c4-fc61-42e2-9fc3-6365616f4d18'
	set @AccountIDEnvidoOnEnvidoDB = '6e2bd4c4-fc61-42e2-9fc3-6365616f4d18'
	END

if (@EnvironmentName = 'Production')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountIDEnvidoDLOnEnvidoDB = '6e2bd4c4-fc61-42e2-9fc3-6365616f4d18'
	set @AccountIDEnvidoOnEnvidoDB = '6e2bd4c4-fc61-42e2-9fc3-6365616f4d18'
	END

Declare @NewCollectionIDOnEnvido int = 114
Declare @NewSetIDOnEnvido int = 470

--exec envido.dbo.pr_LinkCreateEnvidoDLCollectionOnEnvidoDB @CollectionName, @CollectionDescription, @CollectionRationale, @ToDate, @type,
--															@addedby, @lastmodifiedby, @AccountIDEnvidoDLOnEnvidoDB, @setname, @tblLinkStagingName, @Debug,
--															@NewCollectionIDOnEnvido OUTPUT, @NewSetIDOnEnvido OUTPUT




-- ###### STEP 3 - Create a new record in tblLinkImportMappingTable ######
print 'STEP 3 - Create a new record in tblLinkImportMappingTable'

Declare @ImportTableMappingIDEnvidoDL int = 0
Declare @ImportTableMappingIDEnvido int = 0
Declare @DefaultGroupIDEnvidoDLOnEnvidoDL int = 1
Declare @DefaultGroupIDEnvidoDLOnEnvido int = 51

insert into tblLinkImportMappingTable (SourceDatabase, SourceTable, DestDatabase, DestCollectionID, DefaultGroupID, DefaultUserID, CreateSourceAnswerSetIDs, ImportStoredProcedure) 
	values ('envido_dl', 'tblLinkStagingBDM', 'envido_dl', @NewCollectionIDOnEnvidoDL, @DefaultGroupIDEnvidoDLOnEnvidoDL, @DefaultUserIDEnvidoDL, 1, null)
set @ImportTableMappingIDEnvidoDL  = @@identity  

insert into tblLinkImportMappingTable (SourceDatabase, SourceTable, DestDatabase, DestCollectionID, DefaultGroupID, DefaultUserID, CreateSourceAnswerSetIDs, ImportStoredProcedure) 
	values ('envido_dl', 'tblLinkStagingBDM', 'envido', 114, @DefaultGroupIDEnvidoDLOnEnvido, @DefaultUserIDEnvido, 0, null)
set @ImportTableMappingIDEnvido  = @@identity  




-- ###### STEP 4 - Create a new records in tblLinkImportMappingFields ######
print 'STEP 4 - Create a new records in tblLinkImportMappingFields'

-- **** Step 4A - populate tblLinkImportMappingFields for envido_dl

set @sequence = 0
Declare @QuestionID int
Declare @QuestionText nVarChar(max)
Declare @sequence int
Declare @questionTypeID int

DECLARE tblQuestionEnvidoDLSearch CURSOR FOR select QuestionID, QuestionText, sequence, questionTypeID from tblQuestion WHERE collectionID = @NewCollectionIDOnEnvidoDL and SetID = @NewSetIDOnEnvidoDL
OPEN tblQuestionEnvidoDLSearch
FETCH NEXT FROM tblQuestionEnvidoDLSearch INTO @QuestionID, @QuestionText, @sequence, @questionTypeID
WHILE @@FETCH_STATUS = 0  
	BEGIN

	print 'Adding: CollectionID - ' + convert(varchar, @NewCollectionIDOnEnvidoDL) + ', ' + @QuestionText + ', ' + convert(varchar, @QuestionID) + ', ' + convert(varchar, @questionTypeID)

	insert into tblLinkImportMappingFields (ImportTableMappingID, SourceField, IncludeField, FieldInSourceFile, DefaultDestAnswersOptionID, DefaultDestValue, DestCollectionID, DestSetID,
											DestQuestionID, DestQuestionText, DestQuestionType, IsPivotKey, IsConcatinated, InObservationValue, Sequence)
		values (@ImportTableMappingIDEnvidoDL, @QuestionText, 1, 1, null, null, @NewCollectionIDOnEnvidoDL, @NewSetIDOnEnvidoDL, 00, @QuestionText, @questionTypeID, null, 0, 0, @sequence)

	FETCH NEXT FROM tblQuestionEnvidoDLSearch INTO @QuestionID, @QuestionText, @sequence, @questionTypeID
	END  

CLOSE tblQuestionEnvidoDLSearch
DEALLOCATE tblQuestionEnvidoDLSearch


--NOTE: Are we creating a new DL collection (see step 2) or is this just a new event type?

-- **** Step 4B - populate tblLinkImportMappingFields for envido

Declare @NewEventType int = 1	-- This was created for BDM for which we only needed a new event type
Declare @EventTypeQuestionID int
if (@NewEventType = 1)
	BEGIN
	Declare @NewSequence int = 1
	Declare @NewAnsCode nvarchar(50)
	select @EventTypeQuestionID=QuestionID from envido.dbo.tblQuestion WHERE SetID = 470 and QueCode = 'EventType'
	select @NewSequence=sequence from envido.dbo.tblAnswersOptions WHERE QuestionID = @EventTypeQuestionID order by sequence
	set @NewSequence = @NewSequence + 1

	select @NewAnsCode=AnsCode from envido.dbo.tblAnswersOptions WHERE QuestionID = @EventTypeQuestionID order by sequence
	if (ISNUMERIC(@NewAnsCode) = 1)
		BEGIN
		set @NewAnsCode = Convert (varchar, convert (int, @NewAnsCode)+1)
		END
	ELSE set @NewAnsCode = 'BDM'

	exec uspAnswersOptions_Add @EventTypeQuestionID, 'BDM', @addedby, @lastmodifiedby, @NewSequence, @NewAnsCode, '1', null, 0, null, null
	END
ELSE
	BEGIN
	DECLARE tblQuestionEnvidoSearch CURSOR FOR select QuestionID, QuestionText, sequence, questionTypeID from envido.dbo.tblQuestion WHERE SetID = 470
	OPEN tblQuestionEnvidoSearch
	FETCH NEXT FROM tblQuestionEnvidoDLSearch INTO @QuestionID, @QuestionText, @sequence, @questionTypeID
	WHILE @@FETCH_STATUS = 0  
		BEGIN

		print 'Adding: CollectionID - ' + convert(varchar, @NewCollectionIDOnEnvidoDL) + ', ' + @QuestionText + ', ' + convert(varchar, @QuestionID) + ', ' + convert(varchar, @questionTypeID)

		insert into tblLinkImportMappingFields (ImportTableMappingID, SourceField, IncludeField, FieldInSourceFile, DefaultDestAnswersOptionID, DefaultDestValue, DestCollectionID, DestSetID,
												DestQuestionID, DestQuestionText, DestQuestionType, IsPivotKey, IsConcatinated, InObservationValue, Sequence)
			values (@ImportTableMappingIDEnvido, @QuestionText, 1, 1, null, null, @NewCollectionIDOnEnvido, @NewSetIDOnEnvido, 00, @QuestionText, @questionTypeID, null, 0, 0, @sequence)

		FETCH NEXT FROM tblQuestionEnvidoDLSearch INTO @QuestionID, @QuestionText, @sequence, @questionTypeID
		END  

	CLOSE tblQuestionEnvidoDLSearch
	DEALLOCATE tblQuestionEnvidoDLSearch
	END


-- ###### STEP 5 - Add a new record to tblCoreDLSetMatching ######
print 'STEP 5 - Add a new record to tblCoreDLSetMatching'

Declare @SourceCollectionID int = 114		-- CollectionID from the DL collection on Envido core
Declare @SourceSetID int = 470
Declare @DestCollectionID int = 1			-- CollectionID from the main collection on Envido core
Declare @DestSetID int = 1

Declare @SourceFirstNameQuestionID int
Declare @SourceMiddleNameQuestionID int
Declare @SourceLastNameQuestionID int
Declare @SourceDefaultGender char = 'M'		-- For SA-PCCOC only interested in males ... sorry ladies :-)
Declare @SourceGenderQuestionID int
Declare @SourceDOBQuestionID int
Declare @SourceMedicareQuestionID int

Declare @SourceDestFirstNameQuestionID int
Declare @SourceDestMiddleNameQuestionID int
Declare @SourceDestLastNameQuestionID int
Declare @SourceDestDefaultGender char = 'M'		-- For SA-PCCOC only interested in males ... sorry ladies :-)
Declare @SourceDestGenderQuestionID int
Declare @SourceDestDOBQuestionID int
Declare @SourceDestMedicareQuestionID int
Declare @SourceDestMatchScoreQuestionID int
Declare @SourceDestMatchFlagQuestionID int

Declare @DestCollectionID int
Declare @DestSetID int
Declare @DestAnswerSetIDQuestionID int
Declare @DestFirstNameQuestionID int
Declare @DestMiddleNameQuestionID int
Declare @DestLastNameQuestionID int
Declare @DestDefaultGender char = 'M'		-- For SA-PCCOC only interested in males ... sorry ladies :-)
Declare @DestGenderQuestionID int
Declare @DestDOBQuestionID int
Declare @DestMedicareQuestionID int
Declare @StatusQuestionID int

select @SourceFirstNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'SourceFirstname'
select @SourceMiddleNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'SourceMiddleName'
select @SourceLastNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'SourceLastName'
select @SourceGenderQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'SourceGender'
select @SourceDOBQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'SourceBirthDate'
select @SourceMedicareQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'SourceMedicareNo'

select @SourceDestFirstNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'DestFirstName'
select @SourceDestMiddleNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'DestMiddleName'
select @SourceDestLastNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'DestLastName'
select @SourceDestGenderQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'DestGender'
select @SourceDestDOBQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'DestBirthDate'
select @SourceDestMedicareQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'MedicareNo'
select @SourceDestMatchScoreQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'DestMatchScore'
select @SourceDestMatchFlagQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'DestMatchFlag'

select @DestFirstNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @DestSetID and QueCode = 'FIRSTNAME'
select @DestMiddleNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @DestSetID and QueCode = 'OTHERNAMES'
select @DestLastNameQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @DestSetID and QueCode = 'SURNAME'
set @DestGenderQuestionID = null
select @DestDOBQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @DestSetID and QueCode = 'BIRTHDATE'
select @DestMedicareQuestionID = QuestionID from envido.dbo.tblQuestion where setId = 2 and QueCode = 'IdValue'							-- For SA-PCCOC. Set 2 is the Patient - IDs set

select @StatusQuestionID = QuestionID from envido.dbo.tblQuestion where setId = @SourceSetID and QueCode = 'Status'


INSERT INTO envido.dbo.tblCoreDLSetMatching
           ([MatchDescription], [DefaultUserID], [SourceDatabase], [SourceAccountID],
            [SourceCollectionID], [SourceSetID], [SourceFirstNameQuestionID], [SourceMiddleNameQuestionID], [SourceLastNameQuestionID], [SourceDefaultGender], [SourceGenderQuestionID], [SourceDOBQuestionID], [SourceMedicareQuestionID],
            [SourceDestFirstNameQuestionID], [SourceDestMiddleNameQuestionID], [SourceDestLastNameQuestionID], [SourceDestDefaultGender], [SourceDestGenderQuestionID], [SourceDestDOBQuestionID], [SourceDestMedicareQuestionID], [SourceDestMatchScoreQuestionID], [SourceDestMatchFlagQuestionID],
			[DestDatabase], [DestAccountID], [DestGroupID],
			[DestCollectionID], [DestSetID], [DestAnswerSetIDQuestionID], [DestFirstNameQuestionID], [DestMiddleNameQuestionID], [DestLastNameQuestionID], [DestDefaultGender], [DestGenderQuestionID], [DestDOBQuestionID], [DestMedicareQuestionID],
			[StatusQuestionID], [ActionSP])
     VALUES
           ('DataLinkage-SA-PCCOC-BDM', @DefaultUserIDEnvidoDL, 'envido', @AccountIDEnvidoDLOnEnvidoDB, 
			@SourceCollectionID, @SourceSetID, @SourceFirstNameQuestionID, @SourceMiddleNameQuestionID, @SourceLastNameQuestionID, @SourceDefaultGender, @SourceGenderQuestionID, @SourceDOBQuestionID, @SourceMedicareQuestionID,
			@SourceDestFirstNameQuestionID, @SourceDestMiddleNameQuestionID, @SourceDestLastNameQuestionID, @SourceDestDefaultGender, @SourceDestGenderQuestionID, @SourceDestDOBQuestionID, @SourceDestMedicareQuestionID, @SourceDestMatchScoreQuestionID, @SourceDestMatchFlagQuestionID,
			'envido', @AccountIDEnvidoOnEnvidoDB, @DefaultGroupIDEnvidoDLOnEnvido,
			@DestCollectionID, @DestSetID, @DestFirstNameQuestionID, @DestMiddleNameQuestionID, @DestLastNameQuestionID, @DestDefaultGender, @DestGenderQuestionID, @DestDOBQuestionID, @DestMedicareQuestionID,
			@StatusQuestionID, null)
END			 