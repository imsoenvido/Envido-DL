USE envido


IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkCreateEnvidoDLCollectionOnEnvidoDB')
DROP PROCEDURE [pr_LinkCreateEnvidoDLCollectionOnEnvidoDB]
GO 

SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*=========================================================================================
    DESCRIPTION:	This creates a new DL collection in the envido database
					
    USE:            EXEC dbo.pr_LinkCreateEnvidoDLCollectionOnEnvidoDB
					
    REVISIONS:		10/12/2021	DJF			Created

					 			
   ========================================================================================*/


CREATE PROCEDURE [dbo].[pr_LinkCreateEnvidoDLCollectionOnEnvidoDB] 
	@CollectionName NVARCHAR(100),
	@CollectionDescription NVARCHAR(800),
	@CollectionRationale NVARCHAR(800),
	@ToDate datetime,
	@type smallint,
	@addedby int,
	@lastmodifiedby int,
	@AccountID varchar(100),
	@setname nvarchar(100),
	@tblLinkStagingName nVarChar(max),
	@Debug int = 0,
	@NewCollectionID int OUTPUT,
	@NewSetID int OUTPUT
AS
BEGIN

Declare @CollectionID int = 0
-- Add in the collection details
declare @tc table(CollectionID int)
insert @tc
	exec uspCollection_Add @CollectionName, @CollectionDescription, @CollectionRationale, @ToDate, @type, @addedby, @lastmodifiedby, @AccountID
select @CollectionID = CollectionID from @tc
set @NewCollectionID = @CollectionID

-- tblSet details
Declare @parentsetId int = null
set @addedby = 1			-- Previously declared
set @lastmodifiedby = 1		-- Previously declared
Declare @AllowOnlyOne bit = 0

Declare @SetID int = 0
-- Add in the set details
declare @ts table(SetID int)
insert @ts
	exec uspSet_Add @setname, @collectionid, @parentsetId, @addedby, @lastmodifiedby, @AllowOnlyOne
select @SetID = SetID from @ts
set @NewSetID = @SetID

-- tblQuestion details
Declare @Column_Name nVarChar(max) = ''
Declare @Column_Type nVarChar(max) = ''
Declare @Column_Length nVarChar(max) = ''

Declare @questiontext nvarchar(max)
Declare @questionTypeid int
Declare @defaultvalue nvarchar(255) = null
Declare @sequence int = 0
set @addedby = 1			-- Previously declared
Declare @ispublished bit = 1
Declare @isfilter bit = 0
Declare @isrequired bit = 0
Declare @tooltip nvarchar(max) = ''
Declare @quecode nvarchar(50)
Declare @validation nvarchar(50) = ''
Declare @value1 nvarchar(50) = ''
Declare @value2 nvarchar(50) = ''
Declare @IsDisplayInTable bit = 0
Declare @NoOfCol int = null
Declare @UnitID int = null
Declare @Formula nvarchar(max) = null
Declare @ConQuestionID int = null
Declare @Operator nvarchar(50) = null
Declare @CompareValue nvarchar(250) = null
Declare @OtherText bit = null
Declare @ConQuestionTypeID int = null
Declare @DateConditionOperator nvarchar(50) = null
Declare @SSRSReportID int = null
Declare @Format varchar(50) = ''
Declare @IsNumericOptions bit = 0
Declare @CalculationType bit = 0
Declare @Interval nvarchar(20) = null
Declare @DisplayOnLightBox bit = 0
Declare @ValidForCurrentDate bit = 0
set @Rationale = ''				-- Previously declared
Declare @IsComplianceReport bit = 0
Declare @IsTrackStatus bit = 0
Declare @AllowedExt nvarchar(200) = null
Declare @IsInline bit = 0
Declare @IsQuestionOnly bit = 0
Declare @IsInlineNew varchar(5) = null


-- Add in the EventID
exec uspQuestion_Add 'EventID', 7, @setid, @defaultvalue, 2, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the EventType
exec uspQuestion_Add 'EventType', 10, @setid, @defaultvalue, 4, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the Provider
exec uspQuestion_Add 'Provider', 10, @setid, @defaultvalue, 6, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the ServiceDate
exec uspQuestion_Add 'ServiceDate', 9, @setid, @defaultvalue, 8, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the ObservationValue
exec uspQuestion_Add 'ObservationValue', 6, @setid, @defaultvalue, 10, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the ReferringDoctor
exec uspQuestion_Add 'ReferringDoctor', 5, @setid, @defaultvalue, 12, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '30', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the SourceKey
exec uspQuestion_Add 'SourceKey', 5, @setid, @defaultvalue, 14, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '60', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the SourceAnswerSetID
exec uspQuestion_Add 'SourceAnswerSetID', 7, @setid, @defaultvalue, 16, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestAnswerSetId
exec uspQuestion_Add 'DestAnswerSetId', 7, @setid, @defaultvalue, 18, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the SourceFirstname
exec uspQuestion_Add 'SourceFirstname', 5, @setid, @defaultvalue, 20, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '50', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestFirstName
exec uspQuestion_Add 'DestFirstName', 5, @setid, @defaultvalue, 22, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '50', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the SourceMiddleName
exec uspQuestion_Add 'SourceMiddleName', 5, @setid, @defaultvalue, 24, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '50', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestMiddleName
exec uspQuestion_Add 'DestMiddleName', 5, @setid, @defaultvalue, 26, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '50', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the SourceLastName
exec uspQuestion_Add 'SourceLastName', 5, @setid, @defaultvalue, 28, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '50', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestLastName
exec uspQuestion_Add 'DestLastName', 5, @setid, @defaultvalue, 30, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '50', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the SourceBirthDate
exec uspQuestion_Add 'SourceBirthDate', 9, @setid, @defaultvalue, 32, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestBirthDate
exec uspQuestion_Add 'DestBirthDate', 9, @setid, @defaultvalue, 34, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the SourceGender
exec uspQuestion_Add 'SourceGender', 1, @setid, @defaultvalue, 36, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestGender
exec uspQuestion_Add 'DestGender', 1, @setid, @defaultvalue, 38, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the SourceMedicareNo
exec uspQuestion_Add 'SourceMedicareNo', 5, @setid, @defaultvalue, 40, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '20', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestMedicareNo
exec uspQuestion_Add 'DestMedicareNo', 5, @setid, @defaultvalue, 42, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 'MaxLength', '20', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestMatchScore
exec uspQuestion_Add 'DestMatchScore', 11, @setid, @defaultvalue, 44, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DestMatchFlag
exec uspQuestion_Add 'DestMatchFlag', 1, @setid, @defaultvalue, 46, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the Status
exec uspQuestion_Add 'Status', 1, @setid, @defaultvalue, 48, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

-- Add in the DateTimeAdded
exec uspQuestion_Add 'DateTimeAdded', 9, @setid, @defaultvalue, 50, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew

END			 