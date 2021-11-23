USE [envido]
GO
/****** Object:  StoredProcedure [dbo].[pr_SCOOPMoveDLSetToCore]    Script Date: 16/06/2021 11:44:09 ******/

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'pr_SCOOPMoveDLSetToCore')
DROP PROCEDURE [pr_SCOOPMoveDLSetToCore]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*=========================================================================================
    DESCRIPTION:    This procedure searches through a data linkage collection/set.
					For SCOOP there are 2 possible events to look for
					1.	DestMatchFlag = 'No Match' and Status = 0 (not processed)
						In this scenario
						- We create a new patient details record.
						- Set DestMatchFlag = Match
					2.	DestMatchFlag = Match and Status = 0 (not sent)
						In this scenario (the patient already exists)
						- We updatie/create a new procedure set record
						- Set status to Processed
    
    USE:            EXEC pr_SCOOPMoveDLSetToCore 1, 0  or EXEC pr_SCOOPMoveDLSetToCore 1, 1, 7351768

	PARAMETERS:		@ID = THE ID
					@Debug : 1 = print various debugging messages, 0 do not print the messages
					@SearchAnswerSetID : If debug = 1 and there is a value in @SearchAnswerSetID then it will only process data for that AnswerSetID
							Note: This AnswerSetID will be from the Data Linkage Collection in Envido Core

    REVISIONS:		03/06/2021  DJF		Created
					30/07/2021	DJF		Add in IDLocation
					01/09/2021	DJF		The Proximal/Distal scores had been swapped from PROC42 to PROC44 and vice versa
					07/09/2021	DJF		Include all QuestionID's in tblAnswer not just the questions that you have data for
					24/09/2021	DJF		DO a whole lot of initialisations for variables that get data from tblAnswersOptions

-- ========================================================================================*/

CREATE PROCEDURE [dbo].[pr_SCOOPMoveDLSetToCore]  
	@ID int ,
	@Debug int,
	@SearchAnswerSetID int
AS
BEGIN

set nocount on

Set dateformat DMY
--Declare @ID int; Set @ID  = 1	

Declare @SourceKey nVarChar(max)

Declare @SourceCollectionID int
Declare @SourceSetID int
Declare @DefaultUserId int
Declare @SourceAnswersetIdQuestionID int
Declare @SourceAnswersetId nVarChar(max)

Declare @DestCollectionID int
Declare @DestPatientRegistrationSetID int
Declare @DestIDsSetID int
Declare @DestProcedureSetID int
Declare @DestAnswersetIdQuestionID int
Declare @DestAnswersetId int
Declare @DestGroupId int

Declare @SourceDestFirstNameQuestionID int
Declare @SourceDestMiddleNameQuestionID int
Declare @SourceDestLastNameQuestionID int
Declare @SourceDestGenderQuestionID int
Declare @SourceDestDOBQuestionID int
Declare @SourceDestMedicareQuestionID int

-- Use these AnswerID's to fill in the SourceDest fields after inserting a new patient record
Declare @StatusAnswerId int
Declare @SourceDestAnswerSetIDAnswerId int
Declare @SourceDestFirstNameAnswerId int
Declare @SourceDestMiddleNameAnswerId int
Declare @SourceDestLastNameAnswerId int
Declare @SourceDestGenderAnswerId int
Declare @SourceDestDOBAnswerId int
Declare @SourceDestMedicareAnswerId int
Declare @SourceDestMatchFlagAnswerId int

Declare @DLGroupId int			-- Group ID from tblAnswerSet of the DL collection in Envido core
Declare @QueryAnswer nVarChar(max)

Declare @SourceDestMatchFlagQuestionID int
Declare @StatusQuestionID int
Declare @SourceKeyQuestionID int

Select @SourceCollectionID = SourceCollectionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @SourceSetID = SourceSetID From dbo.tblCoreDLSetMatching where ID = @ID
Select @DestCollectionID = DestCollectionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @DestPatientRegistrationSetID = DestSetID From dbo.tblCoreDLSetMatching where ID = @ID
Select @DestProcedureSetID = SetID From tblSet where collectionID = @DestCollectionID and SetName = 'Procedure'
Select @DestIDsSetID = SetID From tblSet where collectionID = @DestCollectionID and SetName = 'IDs'
Select @DefaultUserId = DefaultUserId From dbo.tblCoreDLSetMatching where ID = @ID
Select @SourceDestMatchFlagQuestionID= SourceDestMatchFlagQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @StatusQuestionID= StatusQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @DestGroupId= DestGroupID From dbo.tblCoreDLSetMatching where ID = @ID

Select @SourceDestFirstNameQuestionID  = SourceDestFirstNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @SourceDestMiddleNameQuestionID = SourceDestMiddleNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @SourceDestLastNameQuestionID   = SourceDestLastNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @SourceDestGenderQuestionID     = SourceDestGenderQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @SourceDestDOBQuestionID        = SourceDestDOBQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
Select @SourceDestMedicareQuestionID   = SourceDestMedicareQuestionID From dbo.tblCoreDLSetMatching where ID = @ID

select @SourceKeyQuestionID = QuestionID from tblQuestion where SetID = @SourceSetID and QueCode = 'SourceReportKey'
select @SourceAnswersetIdQuestionID = QuestionID from tblQuestion where SetID = @SourceSetID and QueCode = 'AnswerSetID'
select @DestAnswersetIdQuestionID = QuestionID from tblQuestion where SetID = @SourceSetID and QueCode = 'DestAnswerSetId'

-- **** Variables used for the patient registration set
-- declare Question ID's
Declare @FamilynamekeyQuestionID int
Declare @TitleQuestionID int
Declare @GivenNameQuestionID int
Declare @PreferredNameQuestionID int
Declare @MiddleNameQuestionID int
Declare @MaidenNameQuestionID int
Declare @GenderQuestionID int
Declare @DateOfBirthQuestionID int
Declare @AgeQuestionID int
Declare @DeceasedQuestionID int
Declare @DateOfDeathQuestionID int
Declare @HighRiskPatientQuestionID int
Declare @DateOfOptOutQuestionID int
Declare @AddressUnknownQuestionID int
Declare @AddressLine1QuestionID int
Declare @AddressLine2QuestionID int
Declare @AddressLine3QuestionID int
Declare @SuburbStatePostcodeQuestionID int
Declare @ResidentialAddressDifferentFromPostalQuestionID int
Declare @PostalAddressLine1QuestionID int
Declare @PostalAddressLine2QuestionID int
Declare @PostalAddressLine3QuestionID int
Declare @PostalSuburbStatePostcodeQuestionID int
Declare @HomePhoneQuestionID int
Declare @MobilePhoneQuestionID int
Declare @WorkPhoneQuestionID int
Declare @EmailAddressQuestionID int
Declare @GpTitleQuestionID int
Declare @GpFullNameQuestionID int
Declare @GpMedicalCentreNameQuestionID int
Declare @GpAddressLine1QuestionID int
Declare @GpAddressLine2QuestionID int
Declare @GpSuburbStatePostcodeQuestionID int
Declare @GpFaxNumberQuestionID int
Declare @GpPhoneQuestionID int
Declare @TypeOfDoctorQuestionID int
Declare @CurrentFilingLocationQuestionID int
Declare @DateOfFilingLocationQuestionID int
Declare @CurrentScoopFolderQuestionID int
Declare @Comments1QuestionID int
Declare @ReasonForReferralOrReferralByQuestionID int
Declare @Comments2QuestionID int
Declare @ReasonForScoopEnrolmentQuestionID int
Declare @DateOfEnrollmentQuestionID int
Declare @WithdrawnByQuestionID int
Declare @ReasonForWithdrawalQuestionID int
Declare @DateOfWithdrawalQuestionID int
Declare @SurnameQuestionID int
Declare @AddressCommentQuestionID int
Declare @SpecialistTitleQuestionID int
Declare @SpecialistFullNameQuestionID int
Declare @SpecialistMedicalCentreNameQuestionID int
Declare @SpecialistAddressLine1QuestionID int
Declare @SpecialistAddressLine2QuestionID int
Declare @SpecialistSuburbStatePostcodeQuestionID int
Declare @SpecialistFaxNumberQuestionID int
Declare @SpecialistPhoneQuestionID int
Declare @GlobalidQuestionID int

-- Find the value of the QuestionID's
select @FamilynamekeyQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR2'
select @TitleQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR3'
select @GivenNameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR4'
select @PreferredNameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR5'
select @MiddleNameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR6'
select @MaidenNameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR8'
select @GenderQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR9'
select @DateOfBirthQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR10'
select @AgeQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR11'
select @DeceasedQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR12'
select @DateOfDeathQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR13'
select @HighRiskPatientQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR14'
select @DateOfOptoutQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR15'
select @AddressUnknownQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR17'
select @AddressLine1QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR18'
select @AddressLine2QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR19'
select @AddressLine3QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR20'
select @SuburbStatePostcodeQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR21'
select @ResidentialAddressDifferentFromPostalQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR23'
select @PostalAddressLine1QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR24'
select @PostalAddressLine2QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR25'
select @PostalAddressLine3QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR26'
select @PostalSuburbStatePostcodeQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR27'
select @HomePhoneQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR29'
select @MobilePhoneQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR30'
select @WorkPhoneQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR31'
select @EmailAddressQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR32'
select @GpTitleQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR34'
select @GpFullNameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR35'
select @GpMedicalCentreNameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR36'
select @GpAddressLine1QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR37'
select @GpAddressLine2QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR38'
select @GpSuburbStatePostcodeQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR39'
select @GpFaxNumberQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR40'
select @GpPhoneQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR41'
select @TypeOfDoctorQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR42'
select @CurrentFilingLocationQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR43'
select @DateOfFilingLocationQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR44'
select @CurrentScoopFolderQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR45'
select @Comments1QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR46'
select @ReasonForReferralOrReferralByQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR48'
select @Comments2QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR49'
select @ReasonForScoopEnrolmentQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR50'
select @DateOfEnrollmentQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR51'
select @WithdrawnByQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR53'
select @ReasonForWithdrawalQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR54'
select @DateOfWithdrawalQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR55'
select @SurnameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR56'
select @AddressCommentQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR57'
select @SpecialistTitleQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR59'
select @SpecialistFullNameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR60'
select @SpecialistMedicalCentreNameQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR61'
select @SpecialistAddressLine1QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR62'
select @SpecialistAddressLine2QuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR63'
select @SpecialistSuburbStatePostcodeQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR64'
select @SpecialistFaxNumberQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR65'
select @SpecialistPhoneQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR66'
select @GlobalidQuestionID = QuestionID from tblQuestion where SetID = @DestPatientRegistrationSetID and QueCode = 'PR68'

-- Declare variables for the actual values in the procedure set
declare @GivenName nVarChar(max)
declare @Surname nVarChar(max)
declare @DateOfBirth nVarChar(max)
declare @Gender nVarChar(max)
declare @AddressLine1 nVarChar(max)
declare @AddressLine2 nVarChar(max)
declare @SuburbStatePostcode nVarChar(max)
declare @Suburb nVarChar(max)
declare @State nVarChar(max)
declare @Postcode nVarChar(max)
declare @HomePhone nVarChar(max)
declare @WorkPhone nVarChar(max)
declare @MobilePhone nVarChar(max)
declare @CurrentSCOOPFolder nVarChar(max)

-- **** Variables used for the ID's set
-- declare Question ID's
declare @IDTypeQuestionID int
declare @LocationQuestionID int
declare @ValueQuestionID int
declare @CurrentIDQuestionID int
-- Find the value of the QuestionID's
select @IDTypeQuestionID = QuestionID from tblQuestion where SetID = @DestIDsSetID and QueCode = 'ID1'
select @LocationQuestionID = QuestionID from tblQuestion where SetID = @DestIDsSetID and QueCode = 'ID2'
select @ValueQuestionID = QuestionID from tblQuestion where SetID = @DestIDsSetID and QueCode = 'ID3'
select @CurrentIDQuestionID = QuestionID from tblQuestion where SetID = @DestIDsSetID and QueCode = 'ID4'
-- Declare variables for the actual values in the procedure set
declare @IDType nVarChar(max)
declare @Location nVarChar(max)
declare @LocationStr nVarChar(max)
declare @Value nVarChar(max)
declare @CurrentID nVarChar(max)

-- **** Variables used for the procedure set
-- declare Question ID's
declare @RecallIntervalQuestionID int	
declare @DateProcedureDueQuestionID int	
declare @PreviousDateProcedureDueQuestionID int	
declare @DateProcedureDoneQuestionID int	
declare @ProcedureNumberQuestionID int	
declare @DateReminderSentQuestionID int	
declare @ProcedureLocationQuestionID int	
declare @ProcedureSpecialistQuestionID int	
declare @ReasonForProcedureQuestionID int	
declare @TypeOfSymptomsQuestionID int	
declare @ProcedureTypeQuestionID int	
declare @PrimaryOutcomeQuestionID int	
declare @DetailsOfPrimaryOutcomeQuestionID int	
declare @OtherOutcome1QuestionID int	
declare @OtherOutcome2QuestionID int	
declare @OtherOutcome3QuestionID int	
declare @OtherOutcome4QuestionID int	
declare @DateFitSentQuestionID int	
declare @ReasonForReplacementFitQuestionID int	
declare @DateReplacementFitSentQuestionID int	
declare @DateFitDevelopedQuestionID int	
declare @DateOriginalKitReturnedQuestionID int	
declare @FitPdFormNotReturnedQuestionID int	
declare @SampleDate1QuestionID int	
declare @SampleResult1QuestionID int	
declare @SampleDate2QuestionID int	
declare @SampleResult2QuestionID int	
declare @StorageTempQuestionID int	
declare @BarcodeNumberQuestionID int	
declare @KitBatchNumberQuestionID int	
declare @ReasonForExclusionQuestionID int	
declare @CommentsQuestionID int	
declare @RecommendedColonoscopyFollowUpTimeMonthsQuestionID int	
declare @ActionNeededQuestionID int	
declare @CompliantWithNhmrcRecommendationQuestionID int	
declare @ReasonForNonComplianceQuestionID int	
declare @DateResultLetterSentQuestionID int	
declare @RecommendedOpdFollowUpTimeMonthsQuestionID int	
declare @BbpsLeftDistalColonQuestionID int	
declare @BbpsTransverseScoreQuestionID int	
declare @BbpsRightProximalColonQuestionID int	
declare @OverallScoreQuestionID int	
declare @AllSectionsQuestionID int	
declare @QualityOfBowelPrepQuestionID int	
declare @WithdrawalTimeQuestionID int	
declare @IntubationDistanceQuestionID int	
declare @CommentQuestionID int	
declare @MarkAsClosedQuestionID int	
declare @ExpiryQuestionID int	
declare @EmrVisitNumberQuestionID int	
declare @ScoopNurseQuestionID int	
declare @NotNeededDateAndTimeQuestionID int	
declare @DateOfScoopNurseReviewQuestionID int	
declare @DoctorToReviewRecommendationQuestionID int	
declare @DateReviewSentToDoctorQuestionID int	
declare @DateReviewReturnedByDoctorQuestionID int	
declare @ViewFobtResultsQuestionID int	
declare @PatientCardfileQuestionID int	
declare @BowelPrepGivenQuestionID int	
declare @NextColonoscopyDueDateQuestionID int	
declare @NotForScoopLetterTypeQuestionID int	
declare @NextEndoscopyDueDateQuestionID int	
declare @FitRecommendationQuestionID int	
declare @TypeOfSymptoms2QuestionID int	
declare @TypeOfSymptoms3QuestionID int	
declare @DateNotForScoopLetterSentQuestionID int	
declare @RecallRecommendationCommentsQuestionID int	
declare @SurveillanceRecommendationColonoscopyIntervalMonthsQuestionID int	
declare @SurveillanceRecommendationColonoscopyDueDateQuestionID int	
declare @SurveillanceRecommendationUpperEndoscopyIntervalMonthsQuestionID int	
declare @SurveillanceRecommendationUpperEndoscopyDueDateQuestionID int	
declare @SurveillanceRecommendationSigmoidoscopyIntervalMonthsQuestionID int	
declare @SurveillanceRecommendationSigmoidoscopyDueDateQuestionID int	
declare @SurveillanceRecommendationFitIntervalMonthsQuestionID int	
declare @SurveillanceRecommendationFitDueDateQuestionID int	
declare @SurveillanceRecommendationVirtualColonoscopyIntervalMonthsQuestionID int	
declare @SurveillanceRecommendationVirtualColonoscopyDueDateQuestionID int	
declare @SurveillanceRecommendationOutpatientAppointmentIntervalMonthsQuestionID int	
declare @SurveillanceRecommendationOutpatientAppointmentDueDateQuestionID int	
declare @SurveillanceRecommendationCaseReviewIntervalMonthsQuestionID int	
declare @SurveillanceRecommendationCaseReviewDueDateQuestionID int	

-- Find the value of the QuestionID's
select @RecallIntervalQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc1'
select @DateProcedureDueQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc2'
select @PreviousDateProcedureDueQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc3'
select @DateProcedureDoneQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc4'
select @ProcedureNumberQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc5'
select @DateReminderSentQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc6'
select @ProcedureLocationQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc7'
select @ProcedureSpecialistQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc8'
select @ReasonForProcedureQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc9'
select @TypeOfSymptomsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc10'
select @ProcedureTypeQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc11'
select @PrimaryOutcomeQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc12'
select @DetailsOfPrimaryOutcomeQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc13'
select @OtherOutcome1QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc14'
select @OtherOutcome2QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc15'
select @OtherOutcome3QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc16'
select @OtherOutcome4QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc17'
select @DateFitSentQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc19'
select @ReasonForReplacementFitQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc20'
select @DateReplacementFitSentQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc21'
select @DateFitDevelopedQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc22'
select @DateOriginalKitReturnedQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc23'
select @FitPdFormNotReturnedQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc24'
select @SampleDate1QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc25'
select @SampleResult1QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc26'
select @SampleDate2QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc27'
select @SampleResult2QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc28'
select @StorageTempQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc29'
select @BarcodeNumberQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc30'
select @KitBatchNumberQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc31'
select @ReasonForExclusionQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc33'
select @CommentsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc34'
select @RecommendedColonoscopyFollowUpTimeMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc35'
select @ActionNeededQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc36'
select @CompliantWithNhmrcRecommendationQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc37'
select @ReasonForNonComplianceQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc38'
select @DateResultLetterSentQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc39'
select @RecommendedOpdFollowUpTimeMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc41'
select @BbpsLeftDistalColonQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc42'
select @BbpsTransverseScoreQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc43'
select @BbpsRightProximalColonQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc44'
select @OverallScoreQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc45'
select @AllSectionsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc46'
select @QualityOfBowelPrepQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc47'
select @WithdrawalTimeQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc48'
select @IntubationDistanceQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc49'
select @CommentQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc50'
select @MarkAsClosedQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc51'
select @ExpiryQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc52'
select @EmrVisitNumberQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc53'
select @ScoopNurseQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'RevNurse'
select @NotNeededDateAndTimeQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'RevDate'
select @DateOfScoopNurseReviewQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'SCOOPRevDate'
select @DoctorToReviewRecommendationQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'DrForApproval'
select @DateReviewSentToDoctorQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'DateRevtoDr'
select @DateReviewReturnedByDoctorQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'DateReturnedDr'
select @ViewFobtResultsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'ViewFOBT'
select @PatientCardfileQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'PatientCardFileProcedure'
select @BowelPrepGivenQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'BowelPrep'
select @NextColonoscopyDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'ColDueDate'
select @NotForScoopLetterTypeQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'RecEndoDue'
select @NextEndoscopyDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'EndoDueDate'
select @FitRecommendationQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'FITRecom'
select @TypeOfSymptoms2QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Symp2'
select @TypeOfSymptoms3QuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Symp3'
select @DateNotForScoopLetterSentQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'NextOPDDate'
select @RecallRecommendationCommentsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'RecallRecCom'
select @SurveillanceRecommendationColonoscopyIntervalMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc55'
select @SurveillanceRecommendationColonoscopyDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc56'
select @SurveillanceRecommendationUpperEndoscopyIntervalMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc57'
select @SurveillanceRecommendationUpperEndoscopyDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc58'
select @SurveillanceRecommendationSigmoidoscopyIntervalMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc59'
select @SurveillanceRecommendationSigmoidoscopyDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc60'
select @SurveillanceRecommendationFitIntervalMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc61'
select @SurveillanceRecommendationFitDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc62'
select @SurveillanceRecommendationVirtualColonoscopyIntervalMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc63'
select @SurveillanceRecommendationVirtualColonoscopyDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc64'
select @SurveillanceRecommendationOutpatientAppointmentIntervalMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc65'
select @SurveillanceRecommendationOutpatientAppointmentDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc66'
select @SurveillanceRecommendationCaseReviewIntervalMonthsQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc67'
select @SurveillanceRecommendationCaseReviewDueDateQuestionID = QuestionID from tblQuestion where SetID = @DestProcedureSetID and QueCode = 'Proc68'

-- Declare variables for the actual values in the procedure set
declare @DateProcedureDone nVarChar(max)
declare @TypeOfProcedure nVarChar(max)
declare @TypeOfProcedureStr nVarChar(max)
declare @ProcedureLocation nVarChar(max)
declare @ProcedureLocationStr nVarChar(max)
declare @WithdrawlTime nVarChar(max)
declare @ReasonForProcedure nVarChar(max)
declare @ReasonForProcedureStr nVarChar(max)
declare @ReasonForProcedure2 nVarChar(max)
declare @ReasonForProcedure3 nVarChar(max)
declare @TypeOfSymptoms nVarChar(max)
declare @TypeOfSymptoms2 nVarChar(max)
declare @TypeOfSymptoms3 nVarChar(max)
declare @ProcedureSpecialist nVarChar(max)
declare @QualityOfBowelPrep nVarChar(max)
declare @ProximalScore nVarChar(max)
declare @TransverseScore nVarChar(max)
declare @DistalScore nVarChar(max)
declare @OverallScore nVarChar(max)
declare @IntubationDistance nVarChar(max)
declare @AllSections nVarChar(max)

declare @TempVariable nVarChar(max)

declare @DLAnswerSetID int
declare @TempMatchFlag nVarChar (10)
declare @MatchFlag nVarChar (20)
declare @TempRecordStatus nVarChar (20)
declare @RecordStatus nVarChar (20)
DECLARE @RecordsProcessed int = 0;
DECLARE @RecordsPreviouslyProcessed int = 0;
DECLARE @recordsMatchprocessed int = 0;
DECLARE @recordsNoMatchprocessed int = 0;
DECLARE @PossibleMatchNotProcessed int = 0;
DECLARE @PendingNotProcessed int = 0;

DECLARE @QueAns dbo.QueAns
DECLARE @QueAns1 dbo.QueAns
DECLARE @QueAnsUpdate dbo.QueAnsUpdate

Declare @AuditQueID int
Declare @AuditValue nVarChar(max)

DECLARE DL_Set CURSOR FOR
	select  AnswerSetID from  tblAnswerSet where (SetID = @SourceSetID and @SearchAnswerSetID = 0) or (SetID = @SourceSetID and @debug = 1 and AnswerSetID = @SearchAnswerSetID)

OPEN DL_Set  
FETCH NEXT FROM DL_Set INTO @DLAnswerSetID
WHILE @@FETCH_STATUS = 0  
	BEGIN

	set @RecordsProcessed = @RecordsProcessed + 1
	select @SourceKey=AnswerText from tblanswer where QuestionID = @SourceKeyQuestionID and AnswerSetID = @DLAnswerSetID
	
	select @SourceAnswersetId=AnswerText from tblAnswer where QuestionID = @SourceAnswersetIdQuestionID and AnswerSetID = @DLAnswerSetID
	select @DLGroupId=GoupID from tblAnswerSet where AnswerSetID = @DLAnswerSetID

	if (@Debug = 1)
		Begin
		print '###############################################################'
		print '@DLAnswerSetID = ' + convert (varchar, @DLAnswerSetID)
		print '@SourceAnswersetIdQuestionID = ' + convert (varchar, @SourceAnswersetIdQuestionID)
		print '@DLGroupId = ' + convert (varchar, @DLGroupId)
		print '@SourceAnswersetId = ' + convert (varchar, @SourceAnswersetId)
		print '@DestGroupId = ' + convert (varchar, @DestGroupId)
		end

	select @TempRecordStatus=AnswerText from tblanswer where QuestionID = @StatusQuestionID and AnswerSetID = @DLAnswerSetID
	select @RecordStatus=AnswerText from tblAnswersOptions TAO where AnswersOptionsID = @TempRecordStatus

	if (@Debug = 1)
		Begin
		print '@RecordStatus = ' + @RecordStatus
		print '--------------------------------------------------------------'
		end

	if (@RecordStatus <> 'Processed')
		BEGIN

		select @TempMatchFlag=AnswerText from tblanswer where QuestionID = @SourceDestMatchFlagQuestionID and AnswerSetID = @DLAnswerSetID
		select @MatchFlag=AnswerText from tblAnswersOptions TAO where AnswersOptionsID = @TempMatchFlag

	if (@Debug = 1)
		Begin
		print '@MatchFlag = ' + @MatchFlag
		print '--------------------------------------------------------------'
		end
		if (@MatchFlag = 'Match')																	-- If we have a match then we need to create a new procedure record.
			BEGIN
			set @recordsMatchprocessed = @recordsMatchprocessed + 1

			set @GivenName = ''
			select @GivenName=FirstName from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey										-- Used in the success/failure messages
			if (@GivenName is null)
				set @GivenName = ''

			set @Surname = ''
			select @Surname=Lastname from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey										-- Used in the success/failure messages
			if (@Surname is null)
				set @Surname = ''

			set @DateOfBirth = ''
			select @DateOfBirth=convert (varchar, BirthDate, 105) from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey			-- Used in the success/failure messages
			if (@DateOfBirth is null)
				set @DateOfBirth = ''
				
			set @DateProcedureDone = ''
			select @DateProcedureDone=convert (varchar, ExamDate, 105) from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@DateProcedureDone is null)
				set @DateProcedureDone = ''

			set @TypeOfProcedure = ''
			select @TypeOfProcedureStr=[Procedure] from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @TypeOfProcedure=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TypeOfProcedureStr and QuestionID = @ProcedureTypeQuestionID
			if (@TypeOfProcedure is null)
				set @TypeOfProcedure = ''

			set @ProcedureLocation = ''
			select @ProcedureLocationStr=ProcedureLocation from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @ProcedureLocation=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @ProcedureLocationStr and QuestionID = @ProcedureLocationQuestionID
			if (@ProcedureLocation is null)
				set @ProcedureLocation = ''

			set @WithdrawlTime = ''
			select @WithdrawlTime=WithdrawalTime from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@WithdrawlTime is null)
				set @WithdrawlTime = ''

			set @TempVariable = ''
			set @ReasonForProcedure = ''
			select @TempVariable=ReasonForProcedure from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @ReasonForProcedure=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @ReasonForProcedureQuestionID
			if (@ReasonForProcedure is null)
				set @ReasonForProcedure = ''

			set @ReasonForProcedure2 = ''
			select @ReasonForProcedure2=ReasonForProcedure2 from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@ReasonForProcedure2 is null)
				set @ReasonForProcedure2 = ''

			set @ReasonForProcedure3 = ''
			select @ReasonForProcedure3=ReasonForProcedure3 from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@ReasonForProcedure3 is null)
				set @ReasonForProcedure3 = ''

			set @TempVariable = ''
			set @TypeOfSymptoms = ''
			select @TempVariable=Symptom from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @TypeOfSymptoms=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @TypeOfSymptomsQuestionID
			if (@TypeOfSymptoms is null)
				set @TypeOfSymptoms = ''

			set @TempVariable = ''
			set @TypeOfSymptoms2 = ''
			select @TempVariable=Symptom2 from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @TypeOfSymptoms2=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @TypeOfSymptoms2QuestionID
			if (@TypeOfSymptoms2 is null)
				set @TypeOfSymptoms2 = ''

			set @TempVariable = ''
			set @TypeOfSymptoms3 = ''
			select @TempVariable=Symptom3 from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @TypeOfSymptoms3=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @TypeOfSymptoms3QuestionID
			if (@TypeOfSymptoms3 is null)
				set @TypeOfSymptoms3 = ''

			set @ProcedureSpecialist = ''
			select @ProcedureSpecialist=ProviderName from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@ProcedureSpecialist is null)
				set @ProcedureSpecialist = ''

			set @TempVariable = ''
			set @QualityOfBowelPrep = ''
			select @TempVariable=QualityOfBowelPrep from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @QualityOfBowelPrep=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @QualityOfBowelPrepQuestionID
			if (@QualityOfBowelPrep is null)
				set @QualityOfBowelPrep = ''

			set @TempVariable = ''
			set @ProximalScore = ''
			select @TempVariable=ProximalScore from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @ProximalScore=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @BbpsRightProximalColonQuestionID
			if (@ProximalScore is null)
				set @ProximalScore = ''

			set @TempVariable = ''
			set @TransverseScore = ''
			select @TempVariable=TransverseScore from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @TransverseScore=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @BbpsTransverseScoreQuestionID
			if (@TransverseScore is null)
				set @TransverseScore = ''

			set @TempVariable = ''
			set @DistalScore = ''
			select @TempVariable=DistalScore from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @DistalScore=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @BbpsLeftDistalColonQuestionID
			if (@DistalScore is null)
				set @DistalScore = ''

			set @TempVariable = ''
			set @OverallScore = ''
			select @TempVariable=OverallScore from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @OverallScore=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @OverallScoreQuestionID
			if (@OverallScore is null)
				set @OverallScore = ''

			set @TempVariable = ''
			set @IntubationDistance = ''
			select @TempVariable=AdvancedTo from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @IntubationDistance=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @IntubationDistanceQuestionID
			if (@IntubationDistance is null)
				set @IntubationDistance = ''

			set @TempVariable = ''
			set @AllSections = ''
			select @TempVariable=ProcedureAllSections from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			select @AllSections=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @AllSectionsQuestionID
			if (@AllSections is null)
				set @AllSections = ''
				
			delete from @QueAns
			delete from @QueAns1

			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@RecallIntervalQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateProcedureDueQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@PreviousDateProcedureDueQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateProcedureDoneQuestionID,@DateProcedureDone,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ProcedureNumberQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateReminderSentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ProcedureLocationQuestionID,@ProcedureLocation,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ProcedureSpecialistQuestionID,@ProcedureSpecialist,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ReasonForProcedureQuestionID,@ReasonForProcedure,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@TypeOfSymptomsQuestionID,@TypeOfSymptoms,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ProcedureTypeQuestionID,@TypeOfProcedure,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@PrimaryOutcomeQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DetailsOfPrimaryOutcomeQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@OtherOutcome1QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@OtherOutcome2QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@OtherOutcome3QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@OtherOutcome4QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateFitSentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ReasonForReplacementFitQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateReplacementFitSentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateFitDevelopedQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateOriginalKitReturnedQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@FitPdFormNotReturnedQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SampleDate1QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SampleResult1QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SampleDate2QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SampleResult2QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@StorageTempQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@BarcodeNumberQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@KitBatchNumberQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ReasonForExclusionQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@CommentsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@RecommendedColonoscopyFollowUpTimeMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ActionNeededQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@CompliantWithNhmrcRecommendationQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ReasonForNonComplianceQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateResultLetterSentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@RecommendedOpdFollowUpTimeMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@BbpsLeftDistalColonQuestionID,@DistalScore,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@BbpsTransverseScoreQuestionID,@TransverseScore,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@BbpsRightProximalColonQuestionID,@ProximalScore,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@OverallScoreQuestionID,@OverallScore,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@AllSectionsQuestionID,@AllSections,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@QualityOfBowelPrepQuestionID,@QualityOfBowelPrep,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@WithdrawalTimeQuestionID,@WithdrawlTime,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@IntubationDistanceQuestionID,@IntubationDistance,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@CommentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@MarkAsClosedQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ExpiryQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@EmrVisitNumberQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ScoopNurseQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@NotNeededDateAndTimeQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateOfScoopNurseReviewQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DoctorToReviewRecommendationQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateReviewSentToDoctorQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateReviewReturnedByDoctorQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ViewFobtResultsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@PatientCardfileQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@BowelPrepGivenQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@NextColonoscopyDueDateQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@NotForScoopLetterTypeQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@NextEndoscopyDueDateQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@FitRecommendationQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@TypeOfSymptoms2QuestionID,@TypeOfSymptoms2,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@TypeOfSymptoms3QuestionID,@TypeOfSymptoms3,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateNotForScoopLetterSentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@RecallRecommendationCommentsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationColonoscopyIntervalMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationColonoscopyDueDateQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationUpperEndoscopyIntervalMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationUpperEndoscopyDueDateQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationSigmoidoscopyIntervalMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationSigmoidoscopyDueDateQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationFitIntervalMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationFitDueDateQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationVirtualColonoscopyIntervalMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationVirtualColonoscopyDueDateQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationOutpatientAppointmentIntervalMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationOutpatientAppointmentDueDateQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationCaseReviewIntervalMonthsQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurveillanceRecommendationCaseReviewDueDateQuestionID,'',0)

			insert into @QueAns1 select * from @QueAns

			select @DestAnswersetId=convert(int,AnswerText) from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @DestAnswerSetIDQuestionID

			if (@Debug = 1)
				begin
				print 'Match found - create new procedure record: ' + convert (varchar,@DLAnswerSetID) + ', ' + @SourceKey + 
					  ', SourceAnswerSetID (envido_dlR2.dbo.tblLinkStagingProvation) = ' + convert (varchar,@SourceAnswersetId)
				print '    @DateProcedureDone            = ' + @DateProcedureDone
				print '    @TypeOfProcedure              = ' + @TypeOfProcedure
				print '    @ProcedureLocation            = ' + @ProcedureLocation
				print '    @WithdrawlTime                = ' + @WithdrawlTime
				print '    @ReasonForProcedure           = ' + @ReasonForProcedure
				print '    @TypeOfSymptoms               = ' + @TypeOfSymptoms
				print '    @TypeOfSymptoms2              = ' + @TypeOfSymptoms2
				print '    @TypeOfSymptoms3              = ' + @TypeOfSymptoms3
				print '    @ProcedureSpecialist          = ' + @ProcedureSpecialist
				print '    @QualityOfBowelPrep           = ' + @QualityOfBowelPrep
				print '    @ProximalScore                = ' + @ProximalScore
				print '    @TransverseScore              = ' + @TransverseScore
				print '    @DistalScore                  = ' + @DistalScore
				print '    @OverallScore                 = ' + @OverallScore
				print '    @IntubationDistance           = ' + @IntubationDistance
				print '    @AllSections                  = ' + @AllSections
				print '    @DestAnswersetId              = ' + convert(varchar,@DestAnswersetId)
				print '    @DestAnswerSetIDQuestionID    = ' + convert(varchar,@DestAnswerSetIDQuestionID)
				print '    @DefaultUserId (@UserID)      = ' + convert(varchar,@DefaultUserId)
				print '    @DLGroupId (@GroupID)         = ' + convert(varchar,@DLGroupId)
				print '    @DestProcedureSetID (@SetID)  = ' + convert(varchar,@DestProcedureSetID)
				end
			
			declare @ThisAnswerSetID int = 0
			declare @TAS table (thisAnswerSetID varchar(100))
			insert @TAS (thisAnswerSetID)
			exec dbo.uspWorkListRecord_Insert	@UserID = @DefaultUserId,
												@GroupID = @DestGroupId,
												@SetID = @DestProcedureSetID,
												@SPASID = @DestAnswersetId,
												@PASID = @DestAnswersetId,
												@QueAns = @QueAns,
												@QueAns1 = @QueAns
			select @ThisAnswerSetID=thisAnswerSetID from @TAS

			if (@ThisAnswerSetID <> 0)
				BEGIN
				-- Once the procedure details have been created need to set the status flag to 'Processed'

				print 'New procedure created for : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth + '. ' + 'New AnswerSetID = ' + Convert (varchar, @ThisAnswerSetID) + 
						', @DateProcedureDone = ' + @DateProcedureDone + ', @TypeOfProcedure = ' + @TypeOfProcedureStr + ', @ProcedureLocation = ' + @ProcedureLocationStr  + ', ' +
						'@ProcedureSpecialist = ' + @ProcedureSpecialist
				print 'New procedure set AnswerSetID = ' + Convert (Varchar, @ThisAnswerSetID) + ', @DestAnswersetId = ' + Convert (Varchar, @DestAnswersetId)

					-- Update the Audit trail
					DECLARE DL_Audit_Cursor CURSOR FOR
					select  QueID, [Value] from @QueAns

					OPEN DL_Audit_Cursor  
					FETCH NEXT FROM DL_Audit_Cursor INTO @AuditQueID, @AuditValue
					WHILE @@FETCH_STATUS = 0  
						BEGIN
						print '        Update audit: QueID = ' + convert(varchar,@AuditQueID) + ', Value = ' + @AuditValue
						exec dbo.usp_InsertAnswerAudit	@AnswerSetID=@ThisAnswerSetID, 
														@QuestionID=@AuditQueID,
														@AnswerValue=@AuditValue,
														@ModifiedBy=@DefaultUserId
						FETCH NEXT FROM DL_Audit_Cursor INTO @AuditQueID, @AuditValue
						END  
					CLOSE DL_Audit_Cursor  
					DEALLOCATE DL_Audit_Cursor  

				delete from @QueAnsUpdate

				select @TempRecordStatus=AnswersOptionsID from tblAnswersOptions where AnswerText = 'Processed' and QuestionID = @StatusQuestionID
				select @StatusAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @StatusQuestionID

				INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@StatusQuestionID,@TempRecordStatus,0,@StatusAnswerId)

				set @QueryAnswer = 'Update tblAnswer set AnswerText = ''' + @TempRecordStatus + ''' ' +
										'where AnswerSetID = ''' + convert(varchar,@DLAnswerSetID) + ''' ' +
										' and QuestionID = ''' + convert(varchar,@StatusQuestionID) + ''''
			if (@Debug = 1)
				begin
				print '    Update Status to Processed'
				print '        @DefaultUserId (@UserID)             = ' + convert(varchar,@DefaultUserId)
				print '        @DLGroupId (@NewGroupID)             = ' + convert(varchar,@DLGroupId)
				print '        @SourceSetID (@SetID)                = ' + convert(varchar,@SourceSetID)
				print '        @SourceCollectionID (@CollectionID)  = ' + convert(varchar,@SourceCollectionID)
				print '        @DLAnswerSetID (@AnswerSetID)        = ' + convert(varchar,@DLAnswerSetID)
				print ''
				print '        @SourceAnswerId                      = ' + convert(varchar,@StatusAnswerId)
				print '        @SourceAnswersetId                   = ' + convert(varchar,@SourceAnswersetId)
				print '        @StatusQuestionID                    = ' + convert(varchar,@StatusQuestionID)
				print '        @QueAnsUpdate.QueID                  = ' + convert(varchar,@StatusQuestionID)
				print '        @QueAnsUpdate.Value                  = ' + convert(varchar,@TempRecordStatus)
				print '        @QueAnsUpdate.Other                  = ' + convert(varchar,0)
				print '        @QueAnsUpdate.AnswerID               = ' + convert(varchar,@StatusAnswerId)
				print '        @QueryAnswer                         = ' + @QueryAnswer
				end

				declare @ReturnAnswerSetIDMatched int = 0
				declare @RASMatched table (ReturnAnswerSetID varchar(100))
				insert @RASMatched (ReturnAnswerSetID)
				exec dbo.uspWorkListRecord_Update	@UserID = @DefaultUserId,
													@NewGroupID = @DLGroupId,
													@SetID = @SourceSetID,
													@CollectionID = @SourceCollectionID,
													@AnswerSetID = @DLAnswerSetID,
													@QueAns1 = @QueAnsUpdate,
													@QueryAnswer = @QueryAnswer,
													@QuerySet = ''
				select @ReturnAnswerSetIDMatched=ReturnAnswerSetID from @RASMatched

				if (@ReturnAnswerSetIDMatched <> 0)
					BEGIN
					print '    Status correctly updated for : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth + '. ' + 
						'@DateProcedureDone = ' + @DateProcedureDone + ', @TypeOfProcedure = ' + @TypeOfProcedureStr + ', @ProcedureLocation = ' + @ProcedureLocationStr  + ', ' +
						'@ProcedureSpecialist = ' + @ProcedureSpecialist
					END
				ELSE
					BEGIN
					print '    **** Error in updating Status (Procedure correctly updated) : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth + '. ' + 
						'@DateProcedureDone = ' + @DateProcedureDone + ', @TypeOfProcedure = ' + @TypeOfProcedureStr + ', @ProcedureLocation = ' + @ProcedureLocationStr  + ', ' +
						'@ProcedureSpecialist = ' + @ProcedureSpecialist
					END

				END
			ELSE
				BEGIN
				print '**** Error in updating procedure set : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth + '. ' + 
						'@DateProcedureDone = ' + @DateProcedureDone + ', @TypeOfProcedure = ' + @TypeOfProcedureStr + ', @ProcedureLocation = ' + @ProcedureLocationStr  + ', ' +
						'@ProcedureSpecialist = ' + @ProcedureSpecialist
				END

			END		-- End of the 'Match' records


		if (@MatchFlag = 'No Match')										-- If we DO NOT have a match then we need to create a new Patient Registration record AND a new IDs record
			BEGIN
			set @recordsNoMatchprocessed = @recordsNoMatchprocessed + 1

			set @CurrentSCOOPFolder = ''
			select @CurrentSCOOPFolder=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = 'Not for SCOOP' and QuestionID = @CurrentSCOOPFolderQuestionID

			select @GivenName=FirstName from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@GivenName is null)
				set @GivenName = ''

			select @Surname=Lastname from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@Surname is null)
				set @Surname = ''

			select @DateOfBirth=convert (varchar, BirthDate, 105) from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@DateOfBirth is null)
				set @DateOfBirth = ''

			select @AddressLine1=AddressLine1 from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@AddressLine1 is null)
				set @AddressLine1 = ''

			select @AddressLine2=AddressLine2 from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@AddressLine2 is null)
				set @AddressLine2 = ''

			select @State=State from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@State is null)
				set @State = ''

			select @Suburb=[Suburb] from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@Suburb is null)
				set @Suburb = ''

			select @Postcode=Postcode from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@Postcode is null)
				set @Postcode = ''

			set @TempVariable = @Suburb + ' ' + @State + ' ' + @Postcode
			set @SuburbStatePostcode = ''
			select @SuburbStatePostcode=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @SuburbStatePostcodeQuestionID

			select @HomePhone=HomePhone from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@HomePhone is null)
				set @HomePhone = ''
			if (LEN(@HomePhone) < 10 and @HomePhone <> '')
				BEGIN
				if (SUBSTRING(@HomePhone,1,1) <> '0' and SUBSTRING(@HomePhone,1,1) <> '8')
					set @HomePhone = '0' + @HomePhone
				END

			select @WorkPhone=WorkPhone from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			if (@WorkPhone is null)
				set @WorkPhone = ''
			if (LEN(@WorkPhone) < 10 and @WorkPhone <> '')
				BEGIN
				if (SUBSTRING(@WorkPhone,1,1) <> '0' and SUBSTRING(@WorkPhone,1,1) <> '8')
					set @WorkPhone = '0' + @WorkPhone
				END

			set @TempVariable = ''
			select @TempVariable=CASE	WHEN LTRIM(rtrim(Gender)) in ('Male','M') then 'Male'
										WHEN LTRIM(rtrim(Gender))in ('Female','F') then 'Female'
								End
					from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
			set @Gender = ''
			select @Gender=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @GenderQuestionID

			delete from @QueAns
			delete from @QueAns1

			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@FamilynamekeyQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@TitleQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GivenNameQuestionID,@GivenName,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@PreferredNameQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@MiddleNameQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@MaidenNameQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GenderQuestionID,@Gender,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateOfBirthQuestionID,@DateOfBirth,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@AgeQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DeceasedQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateOfDeathQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@HighRiskPatientQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateOfOptoutQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@AddressUnknownQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@AddressLine1QuestionID,@AddressLine1,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@AddressLine2QuestionID,@AddressLine2,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@AddressLine3QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SuburbStatePostcodeQuestionID,@SuburbStatePostcode,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ResidentialAddressDifferentFromPostalQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@PostalAddressLine1QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@PostalAddressLine2QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@PostalAddressLine3QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@PostalSuburbStatePostcodeQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@HomePhoneQuestionID,@HomePhone,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@MobilePhoneQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@WorkPhoneQuestionID,@WorkPhone,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@EmailAddressQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GpTitleQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GpFullNameQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GpMedicalCentreNameQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GpAddressLine1QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GpAddressLine2QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GpSuburbStatePostcodeQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GpFaxNumberQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GpPhoneQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@TypeOfDoctorQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@CurrentFilingLocationQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateOfFilingLocationQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@CurrentSCOOPFolderQuestionID,@CurrentSCOOPFolder,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@Comments1QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ReasonForReferralOrReferralByQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@Comments2QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ReasonForScoopEnrolmentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateOfEnrollmentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@WithdrawnByQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ReasonForWithdrawalQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@DateOfWithdrawalQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SurnameQuestionID,@Surname,0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@AddressCommentQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SpecialistTitleQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SpecialistFullNameQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SpecialistMedicalCentreNameQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SpecialistAddressLine1QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SpecialistAddressLine2QuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SpecialistSuburbStatePostcodeQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SpecialistFaxNumberQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@SpecialistPhoneQuestionID,'',0)
			INSERT INTO @QueAns(QueID, Value, Other) VALUES(@GlobalidQuestionID,'',0)

			insert into @QueAns1 select * from @QueAns

			if (@Debug = 1)
				begin
				print 'No Match found - create new patient details record: ' + convert (varchar,@DLAnswerSetID) + ', ' + @SourceKey + 
					  ', SourceAnswerSetID (envido_dlR2.dbo.tblLinkStagingProvation) = ' + convert (varchar,@SourceAnswersetId)
				print '    @DefaultUserId          = ' + convert(varchar,@DefaultUserId)
				print '    SetID                   = ' + convert(varchar,@DestPatientRegistrationSetID)
				print '    @DestGroupId            = ' + convert(varchar,@DestGroupId)
				print '    SuperParentAnswerSetID  = null'
				print '    ParentAnswerSetID       = null'
				print '    @GivenName              = ' + @GivenName
				print '    @Surname                = ' + @Surname
				print '    @DateOfBirth            = ' + @DateOfBirth
				print '    @AddressLine1           = ' + @AddressLine1
				print '    @AddressLine2           = ' + @AddressLine2
				print '    @HomePhone              = ' + @HomePhone
				print '    @WorkPhone              = ' + @WorkPhone
				print '    @Gender                 = ' + @Gender
				print '    @State                  = ' + @State
				print '    @Suburb                 = ' + @Suburb
				print '    @Postcode               = ' + @Postcode
				print '    @SuburbStatePostcode    = ' + @SuburbStatePostcode
				end

			declare @SuperParentAnswerSetID int = 0
			declare @t table (SuperParentAnswerSetID varchar(100))
			insert @t (SuperParentAnswerSetID)
			exec dbo.uspWorkListRecord_Insert	@UserID=@DefaultUserId, 
												@GroupID=@DestGroupId,
												@SetID=@DestPatientRegistrationSetID,
												@SPASID=null,
												@PASID=null,
												@QueAns=@QueAns,
												@QueAns1=@QueAns
			select @SuperParentAnswerSetID=SuperParentAnswerSetID from @t

			if (@SuperParentAnswerSetID != 0)
				BEGIN
				print 'New Patient registration record created for : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth + ', @SuperParentAnswerSetID = ' + convert (varchar, @SuperParentAnswerSetID)

				-- Update the Audit trail
				DECLARE DL_Audit_Cursor CURSOR FOR
				select  QueID, [Value] from @QueAns

				OPEN DL_Audit_Cursor  
				FETCH NEXT FROM DL_Audit_Cursor INTO @AuditQueID, @AuditValue
				WHILE @@FETCH_STATUS = 0  
					BEGIN
					print '        Update audit: QueID = ' + convert(varchar,@AuditQueID) + ', Value = ' + @AuditValue
					exec dbo.usp_InsertAnswerAudit	@AnswerSetID=@SuperParentAnswerSetID, 
													@QuestionID=@AuditQueID,
													@AnswerValue=@AuditValue,
													@ModifiedBy=@DefaultUserId
					FETCH NEXT FROM DL_Audit_Cursor INTO @AuditQueID, @AuditValue
					END  
				CLOSE DL_Audit_Cursor  
				DEALLOCATE DL_Audit_Cursor  	
				
				set @IDType = ''
				select @IDType=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = 'MRN' and QuestionID = @IDTypeQuestionID

				set @LocationStr = ''
				select @LocationStr=IDLocation from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
				if (@LocationStr is null)
					BEGIN
					set @LocationStr = ''
					set @TempVariable = ''
					END
				ELSE
					BEGIN
					set @TempVariable = @LocationStr
					END

				if (@LocationStr = 'Noarlunga Health Services')
					set @TempVariable = 'NHS'
				if (@LocationStr = 'Flinders Medical Centre')
					set @TempVariable = 'FMC'
				set @Location = ''
				select @Location=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @LocationQuestionID
				if (@Debug = 1)
					begin
					print '    No Match found - create new IDs record: ' + convert (varchar,@DLAnswerSetID) + ', ' + @SourceKey + 
						  ', SourceAnswerSetID (envido_dlR2.dbo.tblLinkStagingProvation) = ' + convert (varchar,@SourceAnswersetId)
					print '        @LocationStr        = ' + @LocationStr
					print '        @Location           = ' + @Location
					print '        @LocationQuestionID = ' + convert (varchar,@LocationQuestionID)
					print '        @TempVariable       = ' + @TempVariable
					end

				select @Value=MRN from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
				set @CurrentID = ''
				select @CurrentID=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = 'Yes' and QuestionID = @CurrentIDQuestionID

				delete from @QueAns
				delete from @QueAns1

				INSERT INTO @QueAns(QueID, Value, Other) VALUES(@IDTypeQuestionID,@IDType,0)
				INSERT INTO @QueAns(QueID, Value, Other) VALUES(@LocationQuestionID,@Location,0)
				INSERT INTO @QueAns(QueID, Value, Other) VALUES(@ValueQuestionID,@Value,0)
				INSERT INTO @QueAns(QueID, Value, Other) VALUES(@CurrentIDQuestionID,@CurrentID,0)
		
				insert into @QueAns1 select * from @QueAns

				if (@Debug = 1)
					begin
					print '        @IDType             = ' + @IDType
					print '        @Location           = ' + @Location
					print '        @Value              = ' + @Value
					print '        @CurrentID          = ' + @CurrentID
					end

				declare @IDAnswerSetID int = 0
				declare @IDAS table (IDAnswerSetID varchar(100))
				insert @IDAS (IDAnswerSetID)
				exec dbo.uspWorkListRecord_Insert	@UserID = @DefaultUserId,
													@GroupID = @DestGroupId,
													@SetID = @DestIDsSetID,
													@SPASID = @SuperParentAnswerSetID,
													@PASID = @SuperParentAnswerSetID,
													@QueAns = @QueAns,
													@QueAns1 = @QueAns
				select @IDAnswerSetID=IDAnswerSetID from @IDAS

				if (@IDAnswerSetID != 0)
					BEGIN
					print '    New IDs record created for : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth + ', @SuperParentAnswerSetID = ' + convert (varchar, @SuperParentAnswerSetID) + 
						  ', ID Type = MRN, Location = ' + @LocationStr + ', Value = ' + @Value
					print '    @SuperParentAnswerSetID = ' + convert (varchar, @SuperParentAnswerSetID) + ', @IDAnswerSetID = ' + convert (varchar, @IDAnswerSetID)

					-- Update the Audit trail
					DECLARE DL_Audit_Cursor CURSOR FOR
					select  QueID, [Value] from @QueAns

					OPEN DL_Audit_Cursor  
					FETCH NEXT FROM DL_Audit_Cursor INTO @AuditQueID, @AuditValue
					WHILE @@FETCH_STATUS = 0  
						BEGIN
						print '        Update audit: QueID = ' + convert(varchar,@AuditQueID) + ', Value = ' + @AuditValue
						exec dbo.usp_InsertAnswerAudit	@AnswerSetID=@IDAnswerSetID, 
														@QuestionID=@AuditQueID,
														@AnswerValue=@AuditValue,
														@ModifiedBy=@DefaultUserId
						FETCH NEXT FROM DL_Audit_Cursor INTO @AuditQueID, @AuditValue
						END  
					CLOSE DL_Audit_Cursor  
					DEALLOCATE DL_Audit_Cursor  

					-- Once the patient details have been updated need to set the MatchFlag to 'Match' so that the next day it will process the proceure details correctly
					-- NOTE: The status flag must NOT be changed as it still needs to go through stage 2 of the processing

					delete from @QueAnsUpdate
					
					select @TempMatchFlag=AnswersOptionsID from tblAnswersOptions where AnswerText = 'Match'
					select @SourceDestMatchFlagAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @SourceDestMatchFlagQuestionID
					select @SourceDestAnswerSetIDAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @DestAnswerSetIDQuestionID
					select @SourceDestFirstNameAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @SourceDestFirstNameQuestionID
					--select @SourceDestMiddleNameAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @SourceDestMiddleNameQuestionID			At time of writing no middle name is passed in - Left in for possible future use
					select @SourceDestLastNameAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @SourceDestLastNameQuestionID
					select @SourceDestGenderAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @SourceDestGenderQuestionID
					select @SourceDestDOBAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @SourceDestDOBQuestionID
					--select @SourceDestMedicareAnswerId=AnswerID from tblAnswer where AnswerSetID = @DLAnswerSetID and QuestionID = @SourceDestMedicareQuestionID				At time of writing no medicare number is passed in - Left in for possible future use

					INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@SourceDestMatchFlagQuestionID,@TempMatchFlag,0,@SourceDestMatchFlagAnswerId)
					INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@DestAnswerSetIDQuestionID,convert(varchar,@SuperParentAnswerSetID),0,@SourceDestAnswerSetIDAnswerId)
					INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@SourceDestFirstNameQuestionID,@GivenName,0,@SourceDestFirstNameAnswerId)
					--INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@SourceDestMiddleNameQuestionID,@TempMatchFlag,0,@SourceDestMiddleNameAnswerId)							AT time of writing no middle name is passed in - Left in for possible future use
					INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@SourceDestLastNameQuestionID,@Surname,0,@SourceDestLastNameAnswerId)
					INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@SourceDestGenderQuestionID,@Gender,0,@SourceDestGenderAnswerId)
					INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@SourceDestDOBQuestionID,@DateOfBirth,0,@SourceDestDOBAnswerId)
					--INSERT INTO @QueAnsUpdate(QueID, Value, Other, AnswerID) VALUES(@SourceDestMedicareQuestionID,@Gender,0,@SourceDestMedicareAnswerId)									AT time of writing no medicare number is passed in - Left in for possible future use

					set @QueryAnswer = 'Update tblAnswer set AnswerText = ''' + convert(varchar,@SuperParentAnswerSetID) + ''' ' +
											'where AnswerSetID = ''' + convert(varchar,@DLAnswerSetID) + ''' ' +
											' and QuestionID = ''' + convert(varchar,@DestAnswerSetIDQuestionID) + ''''

					set @QueryAnswer = @QueryAnswer + 'Update tblAnswer set AnswerText = ''' + @TempMatchFlag + ''' ' +
											'where AnswerSetID = ''' + convert(varchar,@DLAnswerSetID) + ''' ' +
											' and QuestionID = ''' + convert(varchar,@SourceDestMatchFlagQuestionID) + ''''

					set @QueryAnswer = @QueryAnswer + 'Update tblAnswer set AnswerText = ''' + REPLACE (@GivenName,'''','''''') + ''' ' +
											'where AnswerSetID = ''' + convert(varchar,@DLAnswerSetID) + ''' ' +
											' and QuestionID = ''' + convert(varchar,@SourceDestFirstNameQuestionID) + ''''

					set @QueryAnswer = @QueryAnswer + 'Update tblAnswer set AnswerText = ''' + REPLACE (@Surname,'''','''''') + ''' ' +
											'where AnswerSetID = ''' + convert(varchar,@DLAnswerSetID) + ''' ' +
											' and QuestionID = ''' + convert(varchar,@SourceDestLastNameQuestionID) + ''''

					set @TempVariable = ''
					select @TempVariable=CASE	WHEN LTRIM(rtrim(Gender)) in ('Male','M') then 'Male'
												WHEN LTRIM(rtrim(Gender))in ('Female','F') then 'Female'
										End
							from envido_dlR2.dbo.tblLinkStagingProvation where SourceKey = @SourceKey
					set @Gender = ''
					select @Gender=convert(varchar,AnswersOptionsID) from tblAnswersOptions TAO where AnswerText = @TempVariable and QuestionID = @SourceDestGenderQuestionID

					set @QueryAnswer = @QueryAnswer + 'Update tblAnswer set AnswerText = ''' + @Gender + ''' ' +
											'where AnswerSetID = ''' + convert(varchar,@DLAnswerSetID) + ''' ' +
											' and QuestionID = ''' + convert(varchar,@SourceDestGenderQuestionID) + ''''

					set @QueryAnswer = @QueryAnswer + 'Update tblAnswer set AnswerText = ''' + @DateOfBirth + ''' ' +
											'where AnswerSetID = ''' + convert(varchar,@DLAnswerSetID) + ''' ' +
											' and QuestionID = ''' + convert(varchar,@SourceDestDOBQuestionID) + ''''

				if (@Debug = 1)
					begin
					print '    Update MatchFlag to Match'
					print '        @DefaultUserId (@UserID)             = ' + convert(varchar,@DefaultUserId)
					print '        @DLGroupId (@NewGroupID)             = ' + convert(varchar,@DLGroupId)
					print '        @SourceSetID (@SetID)                = ' + convert(varchar,@SourceSetID)
					print '        @SourceCollectionID (@CollectionID)  = ' + convert(varchar,@SourceCollectionID)
					print '        @DLAnswerSetID (@AnswerSetID)        = ' + convert(varchar,@DLAnswerSetID)
					print ''
					print '        @SourceDestMatchFlagAnswerId         = ' + convert(varchar,@SourceDestMatchFlagAnswerId)
					print '        @SourceAnswersetId                   = ' + convert(varchar,@SourceAnswersetId)
					print '        @SourceDestMatchFlagQuestionID       = ' + convert(varchar,@SourceDestMatchFlagQuestionID)
					--print '        @QueAnsUpdate.QueID                  = ' + convert(varchar,@SourceDestMatchFlagQuestionID)
					--print '        @QueAnsUpdate.Value                  = ' + convert(varchar,@TempMatchFlag)
					--print '        @QueAnsUpdate.Other                  = ' + convert(varchar,0)
					--print '        @QueAnsUpdate.AnswerID               = ' + convert(varchar,@SourceDestMatchFlagAnswerId)
					print '        @QueryAnswer                         = ' + @QueryAnswer
					end
		

					declare @ReturnAnswerSetID int = 0
					declare @RAS table (ReturnAnswerSetID varchar(100))
					insert @RAS (ReturnAnswerSetID)
					exec dbo.uspWorkListRecord_Update	@UserID = @DefaultUserId,
														@NewGroupID = @DLGroupId,
														@SetID = @SourceSetID,
														@CollectionID = @SourceCollectionID,
														@AnswerSetID = @DLAnswerSetID,
														@QueAns1 = @QueAnsUpdate,
														@QueryAnswer = @QueryAnswer,
														@QuerySet = ''
					select @ReturnAnswerSetID=ReturnAnswerSetID from @RAS
					if (@ReturnAnswerSetID != 0)
						BEGIN
						print '    Match flag correctly updated to Match for : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth + '. ' + 
							  ', ID Type = MRN, Location = ' + @LocationStr + ', Value = ' + @Value
						END
					ELSE
						BEGIN
						print '    **** Error in updating Match flag (Patient registration & IDs record successfully created) : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth +
							  ', ID Type = MRN, Location = ' + @LocationStr + ', Value = ' + @Value
						END

					END		-- if (@IDAnswerSetID != 0)
				ELSE
					BEGIN
					print '    **** Error in updating IDs set (Patient registration record successfully created) : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth +
						  ', ID Type = MRN, Location = ' + @LocationStr + ', Value = ' + @Value
					END

				END		-- if (@SuperParentAnswerSetID != 0)
			ELSE
				BEGIN
				print '**** Error in updating Patient registration set : ' + @Surname + ', ' + @GivenName + ', DOB: ' + @DateOfBirth
				END

			END		-- End of the 'No Match' records
	
		if (@MatchFlag = 'Possible match')												-- No further processing is required
			BEGIN
			set @PossibleMatchNotProcessed = @PossibleMatchNotProcessed + 1
			print 'Records not processed: ' + convert (varchar,@DLAnswerSetID) + ', ' + @SourceKey + ', ' + @MatchFlag
			END

		if (@MatchFlag = 'Pending')														-- No further processing is required
			BEGIN
			set @PendingNotProcessed = @PendingNotProcessed + 1
			print 'Records not processed: ' + convert (varchar,@DLAnswerSetID) + ', ' + @SourceKey + ', ' + @MatchFlag
			END

		END		-- if (@RecordStatus <> 'Processed')
	ELSE
		BEGIN
		set @RecordsPreviouslyProcessed = @RecordsPreviouslyProcessed + 1
		END

	FETCH NEXT FROM DL_Set INTO @DLAnswerSetID
	END  
CLOSE DL_Set  
DEALLOCATE DL_Set  	
  
select	@RecordsProcessed as 'RecordsProcessed', @RecordsPreviouslyProcessed as 'RecordsPreviouslyProcessed', @recordsMatchprocessed as 'RecordsMatched',
		@recordsNoMatchprocessed as 'RecordsNotMatched', @PossibleMatchNotProcessed as 'PossibleMatchNotProcessed', @PendingNotProcessed as 'PendingNotProcessed'
END