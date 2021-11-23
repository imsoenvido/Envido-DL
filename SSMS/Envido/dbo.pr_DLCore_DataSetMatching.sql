USE [envido]
GO

IF EXISTS (Select * From sys.objects Where type = 'P' AND name = 'pr_DLCore_DataSetMatching')
DROP PROCEDURE [pr_DLCore_DataSetMatching]


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*=========================================================================================
    DESCRIPTION:    This procedure merges two files AND Select the best matches for the records
                    using social security number (SSN), Last name, First name, date of birth, sex, 
                    AND first, middle AND last initials.  
    
    NOTES:          Blocking and weightings are performed between all records in the two files
                    begin tran 
    USE:            EXEC dbo.pr_DLCore_DataSetMatching @ID = 1

	PARAMETERS:		@ID = THE ID From  tblCoreDLSetMatching

    REVISIONS:		12/08/2020	S.Walsh	Created based on Data linkage dbo.pr_DataSetMatching
                    09/08/2021  DJF     Use temporary tables so that multiple systems can run this at the same time

-- ========================================================================================*/

CREATE PROCEDURE [dbo].[pr_DLCore_DataSetMatching]  
	@ID int ,
	@Debug int = 0
AS
BEGIN

	Set dateformat DMY
	--Declare @ID int; Set @ID  = 1	
	
	
	Declare @Description nvarchar (50)
	Declare @DefaultUserId int
	Declare @SourceDB nvarchar (50)
	Declare @SourceAccountID nvarchar (50)
	Declare @SourceCollectionID int
	Declare @SourceSetID int
	Declare @SourceFirstNameQuestionID int
	Declare @SourceMiddleNameQuestionID int
	Declare @SourceLastQuestionID int
	Declare @SourceDefaultGender char(1)
	Declare @SourceGenderQuestionID int
	Declare @SourceDOBQuestionID int
	Declare @SourceMedicareQuestionID int

	Declare @SourceDestFirstNameQuestionID int
	Declare @SourceDestMiddleNameQuestionID int
	Declare @SourceDestLastQuestionID int
	Declare @SourceDestGenderQuestionID int
	Declare @SourceDestDOBQuestionID int
	Declare @SourceDestMedicareQuestionID int
	Declare @SourceDestDestMatchScoreQuestionID int
	Declare @SourceDestDestMatchFlagQuestionID int
	
	Declare @DestDB nvarchar (50)
	Declare @DestAccountID nvarchar (50)
	Declare @DestCollectionID int
	Declare @DestSetID int
	Declare @DestAnswerSetIDQuestionID int
	Declare @DestFirstNameQuestionID int
	Declare @DestMiddleNameQuestionID int
	Declare @DestLastQuestionID int
	Declare @DestDefaultGender char(1)
	Declare @DestGenderQuestionID int
	Declare @DestDOBQuestionID int
	Declare @DestMedicareQuestionID int
	Declare @StatusQuestionId int
	Declare @ActionSP nvarchar (50)
	
	Declare @SQL varchar(max)

	Select @Description = MatchDescription  From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DefaultUserId = DefaultUserId From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestAnswerSetIDQuestionID = DestAnswerSetIDQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	
	Select @SourceDB = SourceDatabase  From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceAccountID  = SourceAccountID From dbo.tblCoreDLSetMatching  where ID = @ID
	Select @SourceCollectionID = SourceCollectionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceSetID = SourceSetID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceFirstNameQuestionID = SourceFirstNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceMiddleNameQuestionID = SourceMiddleNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceLastQuestionID = SourceLastNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDefaultGender =  SourceDefaultGender From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceGenderQuestionID = SourceGenderQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDOBQuestionID = SourceDOBQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceMedicareQuestionID= SourceMedicareQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	
	Select @SourceDestFirstNameQuestionID = SourceDestFirstNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDestMiddleNameQuestionID = SourceDestMiddleNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDestLastQuestionID = SourceDestLastNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDestGenderQuestionID = SourceDestGenderQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDestDOBQuestionID = SourceDestDOBQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDestMedicareQuestionID = SourceDestMedicareQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDestDestMatchScoreQuestionID= SourceDestMatchScoreQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @SourceDestDestMatchFlagQuestionID= SourceDestMatchFlagQuestionID From dbo.tblCoreDLSetMatching where ID = @ID

	Select @DestDB = DestDatabase  From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestAccountID = DestAccountID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestCollectionID = DestCollectionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestSetID = DestSetID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestAnswerSetIDQuestionID = DestAnswerSetIDQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestFirstNameQuestionID = DestFirstNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestMiddleNameQuestionID = DestMiddleNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestLastQuestionID = DestLastNameQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestDefaultGender = DestDefaultGender  From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestGenderQuestionID = DestGenderQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestDOBQuestionID = DestDOBQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @DestMedicareQuestionID = DestMedicareQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @StatusQuestionId = StatusQuestionID From dbo.tblCoreDLSetMatching where ID = @ID
	Select @ActionSP = ActionSP From dbo.tblCoreDLSetMatching where ID = @ID

	/*
	If @Debug = 1
	begin 
		Print '@SourceSetID: ' + cast(@SourceSetID as varchar)
		Print '@SourceGenderQuestionID: ' + cast(@SourceGenderQuestionID as varchar)
		Print '@SourceFirstNameQuestionID: ' + cast(@SourceFirstNameQuestionID as varchar)
		Print '@SourceMiddleNameQuestionID: ' + cast(@SourceMiddleNameQuestionID as varchar)
		Print '@SourceLastQuestionID : ' + cast(@SourceLastQuestionID  as varchar)
		Print '@SourceDefaultGender: ' + cast(@SourceDefaultGender as varchar)
		Print '@SourceGenderQuestionID: ' + cast(@SourceGenderQuestionID as varchar)
		Print '@SourceDOBQuestionID: ' + cast(@SourceDOBQuestionID as varchar)
		Print '@SourceGenderQuestionID: ' + cast(@SourceGenderQuestionID as varchar)
		Print '@SourceMedicareQuestionID : ' + cast(@SourceMedicareQuestionID  as varchar)
		Print '@DestFirstNameQuestionID: ' + cast(@DestFirstNameQuestionID as varchar)
	End 
	*/
	 
    SET ROWCOUNT 0
    IF OBJECT_ID('tempdb..#Table1') IS NOT NULL DROP TABLE #Table1
    
    Create table #Table1 (
            aID  int IDENTITY (1,1) NOT NULL,
            aSourceRecordID int NOT NULL,
            aFirstName nvarchar(50) NULL,
            aFnInit nchar (1) NULL,
            aMiddleName nvarchar(50) NULL,
            aMnInit nchar (1) NULL,
	        aLastName nvarchar(50) NULL,
	        aLnINit nchar(1) NULL,
            aSexCode char(1)NULL,
            aDOB datetime NULL,		  
            aMedicareNo nvarchar(12)NULL,		
            aSexDayYear nvarchar(7) NULL,
            aSexMoDay nvarchar(7) NULL,
            aSexMoYear nvarchar(7) NULL,
	)
          
    Insert into #Table1 
	Select	SourceAnswerSetID
			,UPPER(SourceFirstName) as SourceFirstName
			,UPPER(SUBSTRING(SourceFirstName,1,1)) as FnInit
			,UPPER(LTRIM(RTRIM(SourceMiddleName))) as SourceMiddleName
			,UPPER(SUBSTRING(SourceMiddleName,1,1))as MnInit
			,UPPER(REPLACE(REPLACE(REPLACE(SourceLastName,'''',''),' ',''),'-',''))  as SourceLastName
			,UPPER(SUBSTRING(REPLACE(REPLACE(REPLACE(SourceLastName,'''',''),' ',''),'-','') ,1,1)) as LnInit
			,SourceGender
			,SourceDOB
			,SourceMedicare 
			,SourceGender + SUBSTRING(REPLACE(CONVERT(varchar,SourceDOB,103),'/',''),1,2) + + SUBSTRING(REPLACE(CONVERT(varchar,SourceDOB,103),'/',''),5,4)as SexDayYear
			,SourceGender + SUBSTRING(REPLACE(CONVERT(varchar,SourceDOB,103),'/',''),3,2)  + SUBSTRING(REPLACE(CONVERT(varchar,SourceDOB,103),'/',''),1,2)as SexMoDay
			,SourceGender + SUBSTRING(REPLACE(CONVERT(varchar,SourceDOB,103),'/',''),3,2)  + SUBSTRING(REPLACE(CONVERT(varchar,SourceDOB,103),'/',''),5,4)as SexMoYear
	From	(
			Select	S.AnswerSetID SourceAnswerSetID
					,(Select [dbo].[GetAnswerValue] (@SourceFirstNameQuestionID, S.AnswerSetID)) SourceFirstName
					,(Select [dbo].[GetAnswerValue] (@SourceMiddleNameQuestionID, S.AnswerSetID)) SourceMiddleName
					,(Select [dbo].[GetAnswerValue] (@SourceLastQuestionID, S.AnswerSetID)) SourceLastName
					,Case when @SourceDefaultGender IS NULL 
						then left((Select [dbo].[GetAnswerValue] (@SourceGenderQuestionID, S.AnswerSetID)),1)  
						ELSE @SourceDefaultGender 
					End as SourceGender
					,cast((Select [dbo].[GetAnswerValue] (@SourceDOBQuestionID, S.AnswerSetID)) as smalldatetime) as SourceDOB
					,(Select [dbo].[GetAnswerValue] (@SourceMedicareQuestionID, S.AnswerSetID)) SourceMedicare
					
			From	tblAnswerSet S
			where	S.SetID =  @SourceSetID
			) X
    
	IF OBJECT_ID('tempdb..#Table2') IS NOT NULL DROP TABLE #Table2
    Create table #Table2 (
            bID  int IDENTITY (1,1) NOT NULL,
            bSourceRecordID int  NULL,
            bFirstName nvarchar(50) NULL,
            bFnInit nchar (1) NULL,
            bMiddleName nvarchar(50) NULL,
            bMnInit nchar (1) NULL,
            bLastName nvarchar(50) NULL,
            bLnINit nchar(1) NULL,
            bSexCode nvarchar(1)NULL,
            bDOB datetime NULL,		  
            bMedicareNo nvarchar(12)NULL,		
            bSexDayYear nvarchar(7) NULL,
            bSexMoDay nvarchar(7) NULL,
            bSexMoYear nvarchar(7) NULL,
    )
	
    Insert into #Table2
	Select	DestAnswerSetID
			,UPPER(DestFirstName) as DestFirstName
			,UPPER(SUBSTRING(DestFirstName,1,1)) as FnInit
			,UPPER(LTRIM(RTRIM(DestMiddleName))) as DestMiddleName
			,UPPER(SUBSTRING(DestMiddleName,1,1))as MnInit
			,UPPER(REPLACE(REPLACE(REPLACE(DestLastName,'''',''),' ',''),'-',''))  as DestLastName
			,UPPER(SUBSTRING(REPLACE(REPLACE(REPLACE(DestLastName,'''',''),' ',''),'-','') ,1,1)) as LnInit
			,DestGender
			,DestDOB
			,DestMedicare
			,DestGender + SUBSTRING(REPLACE(CONVERT(varchar,DestDOB,103),'/',''),1,2) + + SUBSTRING(REPLACE(CONVERT(varchar,DestDOB,103),'/',''),5,4)as SexDayYear
			,DestGender + SUBSTRING(REPLACE(CONVERT(varchar,DestDOB,103),'/',''),3,2)  + SUBSTRING(REPLACE(CONVERT(varchar,DestDOB,103),'/',''),1,2)as SexMoDay
			,DestGender + SUBSTRING(REPLACE(CONVERT(varchar,DestDOB,103),'/',''),3,2)  + SUBSTRING(REPLACE(CONVERT(varchar,DestDOB,103),'/',''),5,4)as SexMoYear

	From	(
			Select	S.AnswerSetID as DestAnswerSetID
					,(Select [dbo].[GetAnswerValue] (@DestFirstNameQuestionID, S.AnswerSetID)) DestFirstName
					,(Select [dbo].[GetAnswerValue] (@DestMiddleNameQuestionID, S.AnswerSetID)) DestMiddleName
					,(Select [dbo].[GetAnswerValue] (@DestLastQuestionID, S.AnswerSetID)) DestLastName
					,Case when @DestDefaultGender IS NULL 
							then left((Select [dbo].[GetAnswerValue] (@DestGenderQuestionID, S.AnswerSetID)),1)  
							else @DestDefaultGender 
					End DestGender
					,cast((Select [dbo].[GetAnswerValue] (@DestDOBQuestionID, S.AnswerSetID)) as smalldatetime) as DestDOB
					,(Select [dbo].[GetAnswerValue] (@DestMedicareQuestionID, S.AnswerSetID)) DestMedicare
					
			From	tblAnswerSet S
			where	S.SetID =  @DestSetID
			) X

    IF OBJECT_ID('tempdb..#MatchingTemp') IS NOT NULL DROP TABLE #MatchingTemp

    Select  bID
            ,bSourceRecordID  
            ,bFirstName
            ,bFnInit
            ,bMiddleName
            ,bMnInit
            ,bLastName
            ,bLnINit
            ,bSexCode
            ,bDOB
            ,bMedicareNo
            ,bSexDayYear
            ,bSexMoDay
            ,bSexMoYear
    Into    #MatchingTemp
    From    #Table2

    --Creates table (MatchingResults) To insert matches 
    ------------------------------------------------------------------------------------------------
    -- PART 1 OF 3 -sex-day-year-
    ------------------------------------------------------------------------------------------------
    
    Print 'Creating MatchingResults began on ' + rtrim(convert(varchar(30), getdate())) + '.'
  
    IF OBJECT_ID('tempdb..#MatchingResults') IS NOT NULL DROP TABLE #MatchingResults

    Create table #MatchingResults (
            aSourceRecordID int NOT NULL,   bSourceRecordID int NULL,
            aFirstName nvarchar(50) NULL,   aMiddleName nvarchar(50) NULL,  
            aLastName nvarchar(50) NULL,	
	        aMedicareNo nvarchar(12)NULL,	aSexCode nvarchar(1)NULL,
	        aMnInit nvarchar(1) NULL,		aLnInit nvarchar(9)NULL,
	        aFnInit nvarchar(9) NULL,		personid float (8)NULL,
	        
            aID nvarchar(16) NULL,	        bID nvarchar(16) NULL,	        
	        bSexCode nvarchar(3) NULL,
	        bMedicareNo nvarchar (12) NULL,	bFirstName nvarchar(50) NULL,
	        bMiddleName nvarchar(50) NULL,  bLastName nvarchar(50) NULL,
	        bMnInit nvarchar (1) NULL,		
	        bLnInit nvarchar(1) NULL,		bFnInit nvarchar(1) NULL,	
	        aDob datetime NULL,		        bDOB datetime NULL,
	       
	        Total decimal(9,2) NULL, 	    MedicareNoTotal decimal(9,2) NULL, 
	        InitChk decimal(9,2) NULL, 	    LNameTot decimal(9,2) NULL,
	        FNameTot decimal(9,2) NULL, 	MinitTot decimal(9,2) NULL,
	        DobTot decimal(9,2) NULL,       MatchingFlag int NULL
	)
   
    -- PART 1 OF 3 -sdayyear- -
    IF OBJECT_ID('tempdb..#MatchingWork1') IS NOT NULL DROP TABLE #MatchingWork1
    
    Print 'PART 1 OF 3 (sex-day-year) began on ' + rtrim(convert(varchar(30), getdate())) + '.'
 
    Select  a.aSourceRecordID 
            ,b.bSourceRecordID 
            ,a.afirstname
            ,a.aMiddleName
            ,a.aLastName
            ,a.aMedicareNo
            ,a.aSexCode
            ,SUBSTRING(a.aMiddleName,1,1)as aMnInit
            ,SUBSTRING(a.aLastName,1,1) as aLnInit
            ,SUBSTRING(a.aFirstName,1,1) as aFnInit
            --PersonID
            ,a.aDOB
            ,a.aID
            ,b.bID
            ,b.bSexCode
            ,b.bMedicareNo
            ,b.bFirstName
            ,b.bMiddleName
            ,b.bLastName
            ,b.bMnInit
            ,b.bLnINit
            ,b.bFnInit
            ,b.bDOB
            ,CAST (00.00 as decimal(5,2)) as total
            ,CAST (00.00 as decimal(5,2))  as MedicareNototal
            ,CAST (00.00 as decimal(5,2))  as initchk
            ,CAST (00.00 as decimal(5,2))  as MedicareNot
            ,lnametot  =  
            CASE
                WHEN (b.bLastName  =  a.aLastName) AND a.aLastName IS NOT NULL AND a.aLastName  < >' '
                    THEN  9.58
                WHEN b.bLastName IS NULL OR a.aLastName IS NULL OR b.bLastName = ' ' OR a.aLastName = ' '
                    THEN  0.00
                WHEN (SUBSTRING(b.bLastName,1,3) = SUBSTRING(a.aLastName,1,3)) 
                    THEN  5.18
                ELSE -3.62
            END,
            MedicareNo1t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,1,1) = SUBSTRING(b.bMedicareNo,1,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo2t  = 				 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,2,1) = SUBSTRING(b.bMedicareNo,2,1) 
                     THEN 1
                ELSE 0
            END,		 	
            MedicareNo3t  = 
            CASE										
                WHEN SUBSTRING(a.aMedicareNo,3,1) = SUBSTRING(b.bMedicareNo,3,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo4t  = 
            CASE			 								
                WHEN SUBSTRING(a.aMedicareNo,4,1) = SUBSTRING(b.bMedicareNo,4,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo5t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,5,1)  = SUBSTRING(b.bMedicareNo,5,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo6t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,6,1)  = SUBSTRING(b.bMedicareNo,6,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo7t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,7,1)  = SUBSTRING(b.bMedicareNo,7,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo8t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,8,1) = SUBSTRING(b.bMedicareNo,8,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo9t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,9,1) = SUBSTRING(b.bMedicareNo,9,1) 
                    THEN 1
                ELSE 0
            END,
            Fnametot  = 
            CASE
                WHEN (SUBSTRING(b.bFirstName,1,15) =  SUBSTRING(a.aFirstName,1,15) AND LEN(RTRIM(b.bFirstName))>1) AND a.aFirstName IS NOT NULL AND a.aFirstName < >' ' 
	                THEN 6.69
                WHEN b.bFirstName IS NULL OR b.bFirstName = ' ' OR a.aFirstName IS NULL  OR a.aFirstName = ' ' 
	                THEN 0.00 
                ELSE - 3.27
            END,
    	    minittot  = 
            CASE
                WHEN a.aMnInit  =  b.bMnInit AND  b.bMnInit  IS NOT NULL AND b.bMnInit  < >' ' 
                    THEN 3.65
                WHEN a.aMnInit IS NULL OR a.aMnInit  = ' ' 
                    THEN 0.00 
                ELSE 0.00
            END,
            dobtot  = 
            CASE 		
                WHEN a.aDOB  =  b.bDOB AND b.bDOB IS NOT NULL AND a.aDOB  < >' ' 
	                THEN 6.22
                WHEN a.aDOB IS NULL OR a.aDOB = ' ' OR b.bDOB IS NULL OR b.bDOB = ' ' 
                    THEN 0.00
	            ELSE 0.00
            END
    Into    #MatchingWork1
    From    #Table1 a
    LEFT JOIN #MatchingTemp b
    ON    a.aSexDayYear  =  b.bSexDayYear
    AND (
          (
            (a.aMedicareNo IS NOT NULL AND a.aMedicareNo < >' ')
            AND 
            (SUBSTRING(a.aMedicareNo,1,3) = SUBSTRING(b.bMedicareNo,1,3)
                OR SUBSTRING(a.aMedicareNo,4,3) = SUBSTRING(b.bMedicareNo,4,3)
                OR SUBSTRING(a.aMedicareNo,7,3) = SUBSTRING(b.bMedicareNo,7,3)
            )
          )
        OR	
          (
            (a.aMedicareNo IS NULL OR b.bMedicareNo IS NULL OR a.aMedicareNo = ' ' OR b.bMedicareNo = ' ')
                AND (SUBSTRING(a.aLastName,1,3) =  SUBSTRING(b.bLastName,1,3))	
                AND (a.aLastName is not NULL AND a.aLastName  < >' ')
           )
        )
        
    Print 'Updating MedicareNo-Total began on ' + rtrim(convert(varchar(30), getdate())) + '.'
  
    UPDATE  #MatchingWork1
    SET     #MatchingWork1.MedicareNototal  =  
	        CASE 
                WHEN bMedicareNo IS NULL OR aMedicareNo IS NULL OR bMedicareNo = ' ' OR aMedicareNo = ' ' 
                    THEN  0.00
                WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 9 
                    THEN  22.95
                WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 8 
                    THEN  16.89
	            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 7 
                    THEN  8.44
                WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t < 7 
                    THEN  -2.38
	        END

    Print 'Updating initchk began on ' + rtrim(convert(varchar(30), getdate())) + '.'
    
    UPDATE #MatchingWork1
	    SET #MatchingWork1.initchk  = 
	        CASE 
	        WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t> = 7 
		        AND bSexCode  = 'M' 
		        AND (((aFirstName IS NULL OR aFirstName = ' ')
		        AND (aLastName IS NULL OR aLastName = ' ')
		        AND (bFirstName IS NOT NULL AND bFirstName < >' ')
		        AND (bLastName IS NOT NULL AND bLastName < >' ')) 
		        OR ((aFirstName IS NOT NULL AND aFirstName < >' ')
		        AND (aLastName IS NOT NULL AND aLastName < >' ')
		        AND (bFirstName IS NULL OR bFirstName = ' ')
		        AND (bLastName IS NULL OR bLastName = ' '))) 
		        AND rtrim(bLnInit) + rtrim(bFnInit) < >rtrim(aLnInit) + rtrim(aFnInit) 
	        THEN  -8
	        WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t> = 7 
		        AND bSexCode = 'F' 
		        AND (((aFirstName IS NULL OR aFirstName = ' ')
		        AND (bFirstName IS NOT NULL AND bFirstName < >' '))
		        OR ((aFirstName IS NOT NULL AND aFirstName < >' ')
		        AND (bFirstName IS NULL OR bFirstName = ' ')))
		        AND rtrim (bFnInit) < >rtrim(aFnInit)
	        THEN  -8
	        ELSE 0
	        END	
    
    Print 'Updating total began on ' + rtrim(convert(varchar(30), getdate())) + '.'
    
	UPDATE  #MatchingWork1
	SET     #MatchingWork1.total  =  lnametot + Fnametot + MedicareNototal + minittot + dobtot + initchk

    Print 'Inserting MatchingResults began on ' + rtrim(convert(varchar(30), getdate())) + '.'
     
      ------------------COPY MATCHED RECORDS TO PERMANENT TABLE ------------------
    
    Insert  #MatchingResults
    Select  aSourceRecordID ,bSourceRecordID 
            ,aFirstName,aMiddleName,aLastName,aMedicareNo,aSexCode,aMnInit,aLnInit,aFnInit
            , NULL personid -- NEED TO CHECK WHAT WE WILL Insert HERE
            ,aID,bID,bSexCode,bMedicareNo,bFirstName,bMiddleName,bLastName,bMnInit,bLnInit,bFnInit
            ,aDOB,bDOB
            ,Total,MedicareNototal,InitChk,LnameTot,Fnametot,Minittot,Dobtot, -1 as MatchingFlag 
    From    #MatchingWork1
    Where   Total >= 0 and Total NOT IN (0.69,18.8)
    
    IF OBJECT_ID('tempdb..#MatchingWork1') IS NOT NULL DROP TABLE #MatchingWork1      
  
    ------------------------------------------------------------------------------------------------
    -- PART 2 OF 3 -sex-month-day
    ------------------------------------------------------------------------------------------------
    
    Print 'Creating indexes for (smoday) began on ' + rtrim(convert(varchar(30), getdate())) + '.'
    Print 'PART 2 OF 3 (smoday) began on ' + rtrim(convert(varchar(30), getdate())) + '.'
  
	Select  a.aSourceRecordID 
            ,b.bSourceRecordID 
            ,a.afirstname
            ,a.aMiddleName
            ,a.aLastName
            ,a.aMedicareNo
            ,a.aSexCode
            ,SUBSTRING(a.aMiddleName,1,1)as aMnInit
            ,SUBSTRING(a.aLastName,1,1) as aLnInit
            ,SUBSTRING(a.aFirstName,1,1) as aFnInit
            --PersonID
            ,a.aDOB
            ,a.aID
            ,b.bID
            ,b.bSexCode
            ,b.bMedicareNo
            ,b.bFirstName
            ,b.bMiddleName
            ,b.bLastName
            ,b.bMnInit
            ,b.bLnINit
            ,b.bFnInit
            ,b.bDOB
            ,CAST (00.00 as decimal(5,2)) as total
            ,CAST (00.00 as decimal(5,2))  as MedicareNototal
            ,CAST (00.00 as decimal(5,2))  as initchk
            ,CAST (00.00 as decimal(5,2))  as MedicareNot
            ,lnametot  =  
            CASE
                WHEN (b.bLastName  =  a.aLastName) AND a.aLastName IS NOT NULL AND a.aLastName  < >' '
                    THEN  9.58
                WHEN b.bLastName IS NULL OR a.aLastName IS NULL OR b.bLastName = ' ' OR a.aLastName = ' '
                    THEN  0.00
                WHEN (SUBSTRING(b.bLastName,1,3) = SUBSTRING(a.aLastName,1,3)) 
                    THEN  5.18
                ELSE -3.62
            END,
            MedicareNo1t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,1,1) = SUBSTRING(b.bMedicareNo,1,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo2t  = 				 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,2,1) = SUBSTRING(b.bMedicareNo,2,1) 
                     THEN 1
                ELSE 0
            END,		 	
            MedicareNo3t  = 
            CASE										
                WHEN SUBSTRING(a.aMedicareNo,3,1) = SUBSTRING(b.bMedicareNo,3,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo4t  = 
            CASE			 								
                WHEN SUBSTRING(a.aMedicareNo,4,1) = SUBSTRING(b.bMedicareNo,4,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo5t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,5,1)  = SUBSTRING(b.bMedicareNo,5,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo6t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,6,1)  = SUBSTRING(b.bMedicareNo,6,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo7t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,7,1)  = SUBSTRING(b.bMedicareNo,7,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo8t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,8,1) = SUBSTRING(b.bMedicareNo,8,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo9t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,9,1) = SUBSTRING(b.bMedicareNo,9,1) 
                    THEN 1
                ELSE 0
            END,
            Fnametot  = 
            CASE
                WHEN (SUBSTRING(b.bFirstName,1,15) =  SUBSTRING(a.aFirstName,1,15) AND LEN(RTRIM(b.bFirstName))>1) AND a.aFirstName IS NOT NULL AND a.aFirstName < >' ' 
	                THEN 6.69
                WHEN b.bFirstName IS NULL OR b.bFirstName = ' ' OR a.aFirstName IS NULL  OR a.aFirstName = ' ' 
	                THEN 0.00 
                ELSE - 3.27
            END,
    	    minittot  = 
            CASE
                WHEN a.aMnInit  =  b.bMnInit AND  b.bMnInit  IS NOT NULL AND b.bMnInit  < >' ' 
                    THEN 3.65
                WHEN a.aMnInit IS NULL OR a.aMnInit  = ' ' 
                    THEN 0.00 
                ELSE 0.00
            END,
            dobtot  = 
            CASE 		
                WHEN a.aDOB  =  b.bDOB AND b.bDOB IS NOT NULL AND a.aDOB  < >' ' 
	                THEN 6.22
                WHEN a.aDOB IS NULL OR a.aDOB = ' ' OR b.bDOB IS NULL OR b.bDOB = ' ' 
                    THEN 0.00
	            ELSE 0.00
            END
    Into    #MatchingWork2
    From    #Table1 a
    LEFT JOIN #MatchingTemp b
        ON a.aSexMoDay =  b.bSexMoDay
    AND (
          (
            (a.aMedicareNo IS NOT NULL AND a.aMedicareNo < >' ')
            AND 
            (SUBSTRING(a.aMedicareNo,1,3) = SUBSTRING(b.bMedicareNo,1,3)
                OR SUBSTRING(a.aMedicareNo,4,3) = SUBSTRING(b.bMedicareNo,4,3)
                OR SUBSTRING(a.aMedicareNo,7,3) = SUBSTRING(b.bMedicareNo,7,3)
            )
          )
        OR	
          (
            (a.aMedicareNo IS NULL OR b.bMedicareNo IS NULL OR a.aMedicareNo = ' ' OR b.bMedicareNo = ' ')
                AND (SUBSTRING(a.aLastName,1,3) =  SUBSTRING(b.bLastName,1,3))	
                AND (a.aLastName is not NULL AND a.aLastName  < >' ')
           )
        )

    Print 'Updating MedicareNototal began on ' + rtrim(convert(varchar(30), getdate())) + '.'

   	UPDATE  #MatchingWork2
     SET     #MatchingWork2.MedicareNototal  =  
        CASE 
            WHEN bMedicareNo IS NULL OR aMedicareNo IS NULL OR bMedicareNo = ' ' OR aMedicareNo = ' ' 
                THEN  0.00
            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 9 
                THEN  22.95
            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 8 
                THEN  16.89
            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 7 
                THEN  8.44
            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t < 7 
                THEN  -2.38
        END
        
    Print 'Updating initchk began on ' + rtrim(convert(varchar(30), getdate())) + '.'

    UPDATE #MatchingWork2
    SET #MatchingWork2.initchk  = 
        CASE 
        WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t> = 7 
	        AND bSexCode  = 'M' 
	        AND (((aFirstName IS NULL OR aFirstName = ' ')
	        AND (aLastName IS NULL OR aLastName = ' ')
	        AND (bFirstName IS NOT NULL AND bFirstName < >' ')
	        AND (bLastName IS NOT NULL AND bLastName < >' ')) 
	        OR ((aFirstName IS NOT NULL AND aFirstName < >' ')
	        AND (aLastName IS NOT NULL AND aLastName < >' ')
	        AND (bFirstName IS NULL OR bFirstName = ' ')
	        AND (bLastName IS NULL OR bLastName = ' '))) 
	        AND rtrim(bLnInit) + rtrim(bFnInit) < >rtrim(aLnInit) + rtrim(aFnInit) 
        THEN  -8
        WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t> = 7 
	        AND bSexCode = 'F' 
	        AND (((aFirstName IS NULL OR aFirstName = ' ')
	        AND (bFirstName IS NOT NULL AND bFirstName < >' '))
	        OR ((aFirstName IS NOT NULL AND aFirstName < >' ')
	        AND (bFirstName IS NULL OR bFirstName = ' ')))
	        AND rtrim (bFnInit) < >rtrim(aFnInit)
        THEN  -8
        ELSE 0
        END	
        
	Print 'Updating total began on ' + rtrim(convert(varchar(30), getdate())) + '.'
   
    UPDATE  #MatchingWork2
	SET     #MatchingWork2.total  =  lnametot + Fnametot + MedicareNototal + minittot + dobtot + initchk

    Print 'Inserting MatchingResults began on ' + rtrim(convert(varchar(30), getdate())) + '.'
	       
      ------------------COPY MATCHED RECORDS TO PERMANENT TABLE ------------------
    
    Insert   #MatchingResults
    Select  aSourceRecordID ,bSourceRecordID 
            ,aFirstName,aMiddleName,aLastName,aMedicareNo,aSexCode,aMnInit,aLnInit,aFnInit
            , NULL personid -- NEED TO CHECK WHAT WE WILL Insert HERE
            ,aID,bID,bSexCode,bMedicareNo,bFirstName,bMiddleName,bLastName,bMnInit,bLnInit,bFnInit
            ,aDOB,bDOB
            ,Total,MedicareNototal,InitChk,LnameTot,Fnametot,Minittot,Dobtot, -1 as MatchingFlag 
    From    #MatchingWork2
    Where   Total >= 0 and Total NOT IN (0.69,18.8)
    
    IF OBJECT_ID('tempdb..#MatchingWork2') IS NOT NULL DROP TABLE #MatchingWork2
        
    ------------------------------------------------------------------------------------------------
    -- PART 3 OF 3 -sex-month-year
    ------------------------------------------------------------------------------------------------
    
    Select  a.aSourceRecordID 
            ,b.bSourceRecordID 
            ,a.afirstname
            ,a.aMiddleName
            ,a.aLastName
            ,a.aMedicareNo
            ,a.aSexCode
            ,SUBSTRING(a.aMiddleName,1,1)as aMnInit
            ,SUBSTRING(a.aLastName,1,1) as aLnInit
            ,SUBSTRING(a.aFirstName,1,1) as aFnInit
            --PersonID
            ,a.aDOB
            ,a.aID
            ,b.bID
            ,b.bSexCode
            ,b.bMedicareNo
            ,b.bFirstName
            ,b.bMiddleName
            ,b.bLastName
            ,b.bMnInit
            ,b.bLnINit
            ,b.bFnInit
            ,b.bDOB
            ,CAST (00.00 as decimal(5,2)) as total
            ,CAST (00.00 as decimal(5,2))  as MedicareNototal
            ,CAST (00.00 as decimal(5,2))  as initchk
            ,CAST (00.00 as decimal(5,2))  as MedicareNot
            ,lnametot  =  
            CASE
                WHEN (b.bLastName  =  a.aLastName) AND a.aLastName IS NOT NULL AND a.aLastName  < >' '
                    THEN  9.58
                WHEN b.bLastName IS NULL OR a.aLastName IS NULL OR b.bLastName = ' ' OR a.aLastName = ' '
                    THEN  0.00
                WHEN (SUBSTRING(b.bLastName,1,3) = SUBSTRING(a.aLastName,1,3)) 
                    THEN  5.18
                ELSE -3.62
            END,
            MedicareNo1t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,1,1) = SUBSTRING(b.bMedicareNo,1,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo2t  = 				 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,2,1) = SUBSTRING(b.bMedicareNo,2,1) 
                     THEN 1
                ELSE 0
            END,		 	
            MedicareNo3t  = 
            CASE										
                WHEN SUBSTRING(a.aMedicareNo,3,1) = SUBSTRING(b.bMedicareNo,3,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo4t  = 
            CASE			 								
                WHEN SUBSTRING(a.aMedicareNo,4,1) = SUBSTRING(b.bMedicareNo,4,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo5t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,5,1)  = SUBSTRING(b.bMedicareNo,5,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo6t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,6,1)  = SUBSTRING(b.bMedicareNo,6,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo7t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,7,1)  = SUBSTRING(b.bMedicareNo,7,1)
                    THEN 1
                ELSE 0
            END,
            MedicareNo8t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,8,1) = SUBSTRING(b.bMedicareNo,8,1) 
                    THEN 1
                ELSE 0
            END,
            MedicareNo9t  = 
            CASE
                WHEN SUBSTRING(a.aMedicareNo,9,1) = SUBSTRING(b.bMedicareNo,9,1) 
                    THEN 1
                ELSE 0
            END,
            Fnametot  = 
            CASE
                WHEN (SUBSTRING(b.bFirstName,1,15) =  SUBSTRING(a.aFirstName,1,15) AND LEN(RTRIM(b.bFirstName))>1) AND a.aFirstName IS NOT NULL AND a.aFirstName < >' ' 
	                THEN 6.69
                WHEN b.bFirstName IS NULL OR b.bFirstName = ' ' OR a.aFirstName IS NULL  OR a.aFirstName = ' ' 
	                THEN 0.00 
                ELSE - 3.27
            END,
    	    minittot  = 
            CASE
                WHEN a.aMnInit  =  b.bMnInit AND  b.bMnInit  IS NOT NULL AND b.bMnInit  < >' ' 
                    THEN 3.65
                WHEN a.aMnInit IS NULL OR a.aMnInit  = ' ' 
                    THEN 0.00 
                ELSE 0.00
            END,
            dobtot  = 
            CASE 		
                WHEN a.aDOB  =  b.bDOB AND b.bDOB IS NOT NULL AND a.aDOB  < >' ' 
	                THEN 6.22
                WHEN a.aDOB IS NULL OR a.aDOB = ' ' OR b.bDOB IS NULL OR b.bDOB = ' ' 
                    THEN 0.00
	            ELSE 0.00
            END
    Into    #MatchingWork3
    From    #Table1 a
    LEFT JOIN #MatchingTemp b
        ON a.aSexMoYear =  b.bSexMoYear
    AND (
          (
            (a.aMedicareNo IS NOT NULL AND a.aMedicareNo < >' ')
            AND 
            (SUBSTRING(a.aMedicareNo,1,3) = SUBSTRING(b.bMedicareNo,1,3)
                OR SUBSTRING(a.aMedicareNo,4,3) = SUBSTRING(b.bMedicareNo,4,3)
                OR SUBSTRING(a.aMedicareNo,7,3) = SUBSTRING(b.bMedicareNo,7,3)
            )
          )
        OR	
          (
            (a.aMedicareNo IS NULL OR b.bMedicareNo IS NULL OR a.aMedicareNo = ' ' OR b.bMedicareNo = ' ')
                AND (SUBSTRING(a.aLastName,1,3) =  SUBSTRING(b.bLastName,1,3))	
                AND (a.aLastName is not NULL AND a.aLastName  < >' ')
           )
        )

    Print 'Updating MedicareNototal began on ' + rtrim(convert(varchar(30), getdate())) + '.'

   	UPDATE  #MatchingWork3
     SET     #MatchingWork3.MedicareNototal  =  
        CASE 
            WHEN bMedicareNo IS NULL OR aMedicareNo IS NULL OR bMedicareNo = ' ' OR aMedicareNo = ' ' 
                THEN  0.00
            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 9 
                THEN  22.95
            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 8 
                THEN  16.89
            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t = 7 
                THEN  8.44
            WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t < 7 
                THEN  -2.38
        END
        
    Print 'Updating initchk began on ' + rtrim(convert(varchar(30), getdate())) + '.'

    UPDATE #MatchingWork3
     SET    #MatchingWork3.initchk  = 
        CASE 
        WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t> = 7 
	        AND bSexCode  = 'M' 
	        AND (((aFirstName IS NULL OR aFirstName = ' ')
	        AND (aLastName IS NULL OR aLastName = ' ')
	        AND (bFirstName IS NOT NULL AND bFirstName < >' ')
	        AND (bLastName IS NOT NULL AND bLastName < >' ')) 
	        OR ((aFirstName IS NOT NULL AND aFirstName < >' ')
	        AND (aLastName IS NOT NULL AND aLastName < >' ')
	        AND (bFirstName IS NULL OR bFirstName = ' ')
	        AND (bLastName IS NULL OR bLastName = ' '))) 
	        AND rtrim(bLnInit) + rtrim(bFnInit) < >rtrim(aLnInit) + rtrim(aFnInit) 
        THEN  -8
        WHEN MedicareNo1t + MedicareNo2t + MedicareNo3t + MedicareNo4t + MedicareNo5t + MedicareNo6t + MedicareNo7t + MedicareNo8t + MedicareNo9t> = 7 
	        AND bSexCode = 'F' 
	        AND (((aFirstName IS NULL OR aFirstName = ' ')
	        AND (bFirstName IS NOT NULL AND bFirstName < >' '))
	        OR ((aFirstName IS NOT NULL AND aFirstName < >' ')
	        AND (bFirstName IS NULL OR bFirstName = ' ')))
	        AND rtrim (bFnInit) < >rtrim(aFnInit)
        THEN  -8
        ELSE 0
        END	
        
    Print 'Updating total began on ' + rtrim(convert(varchar(30), getdate())) + '.'
    
    UPDATE  #MatchingWork3
	 SET     #MatchingWork3.total  =  lnametot + Fnametot + MedicareNototal + minittot + dobtot + initchk

    Print 'Inserting MatchingResults began on ' + rtrim(convert(varchar(30), getdate())) + '.'
	       
      ------------------COPY MATCHED RECORDS TO PERMANENT TABLE ------------------
    
    Insert  #MatchingResults
    Select  aSourceRecordID ,bSourceRecordID 
            ,aFirstName,aMiddleName,aLastName,aMedicareNo,aSexCode,aMnInit,aLnInit,aFnInit
            , NULL personid -- NEED TO CHECK WHAT WE WILL Insert HERE
            ,aID,bID,bSexCode,bMedicareNo,bFirstName,bMiddleName,bLastName,bMnInit,bLnInit,bFnInit
            ,aDOB,bDOB
            ,Total,MedicareNototal,InitChk,LnameTot,Fnametot,Minittot,Dobtot, -1 as MatchingFlag 
    From    #MatchingWork3
    Where   Total >= 0 and Total NOT IN (0.69,18.8)
    
    IF OBJECT_ID('tempdb..#MatchingWork3') IS NOT NULL DROP TABLE #MatchingWork3

    ------------------------------------------------------------------------------------------------
    --  Wrap it all up
    ------------------------------------------------------------------------------------------------

    Print 'Selecting distinct IDs began on ' + rtrim(convert(varchar(30), getdate())) + '.'
    
    Select  *
    Into    #MatchingResults2
    From    #MatchingResults
    ORDER BY bID,Total

	IF EXISTS (Select * From Tempdb.dbo.sysobjects Where type  =  'U' AND Name  =  '#MatchingResults3')
		DROP TABLE #MatchingResults3
    
	Select  *
            ,ROW_NUMBER () OVER (PARTITION BY aSourceRecordID ORDER BY Total DESC) as id_num 
    Into	#MatchingResults3
    From    #MatchingResults2

    IF EXISTS (Select * From Tempdb.dbo.sysobjects Where type  =  'U' AND Name  =  '#MatchingResults2')
        DROP TABLE #MatchingResults2
        
    IF OBJECT_ID('tempdb..#MatchingResults') IS NOT NULL DROP TABLE #MatchingResults    
    
    Select  *
    Into    #MatchingResults4
    From    #MatchingResults3
    Where id_num = 1
    
   Print 'Job completed on ' + rtrim(convert(varchar(30), getdate())) + '.'

   UPDATE #MatchingResults4
   SET  MatchingFlag = CASE WHEN Total <12.53 THEN 0
                                WHEN Total BETWEEN 12.53 AND 17.74 THEN 99 
                                WHEN Total >=17.75  THEN 1
                        END 
   From    #MatchingResults4

   /****************************************************************************
   Update the fields from the destination to allow side-by-side viewing of the matching field values 
   ****************************************************************************/

	Declare @AnswerSetID int 
	Declare @DestAnswerSetID int 
	Declare @DestFirstNameValue varchar (max)
	Declare @DestMiddleNameValue varchar (max) 
	Declare @DestLastValue varchar (max)
	Declare @DestGenderValue varchar (max)		
	Declare @DestDOBValue varchar (max)
	Declare @DestMedicareValue varchar (max)
	Declare @DestMatchScoreValue varchar (max)
	Declare @DestMatchFlagValue varchar (max)

	IF OBJECT_ID('tempdb..#Process') IS NOT NULL DROP TABLE #Process 

	 Create table #Process (
			aSourceRecordID int NOT NULL
			,bSourceRecordID int NULL
			,bFirstName nvarchar(50) NULL
			,bMiddleName nvarchar(50) NULL
			,bLastName nvarchar(50) NULL
			,bSexCode nvarchar(max) NULL
			,bDOB varchar (max) NULL
			,bMedicareNo nvarchar (12) NULL
			,DestMatchScore varchar (max) NULL
			,MatchingFlag varchar(max) NULL
		)

	Select @SQL  = '
	Select aSourceRecordID,bSourceRecordID,bFirstName,bMiddleName,bLastName
			,(Select AnswersOptionsID From tblAnswersOptions where QuestionID = '+Cast(@SourceDestGenderQuestionID as varchar)+' and AnsCode = M.bSexCode) as bSexCode
			,convert(varchar(max),bDOB,105) As bDOB
			,bMedicareNo
			,Total as DestMatchScore 
			,(Select AnswersOptionsID From tblAnswersOptions where QuestionID = '+ Cast (@SourceDestDestMatchFlagQuestionID as varchar)+' and AnsCode = M.MatchingFlag) as MatchFlag 
	From #MatchingResults4 M'

	Insert into #Process 
	EXEC (@SQL)

	Declare InsertDestIdentifiers CURSOR
	FOR Select * From #Process

	OPEN InsertDestIdentifiers

		FETCH NEXT From InsertDestIdentifiers 
		Into @AnswerSetID, @DestAnswerSetID,@DestFirstNameValue,@DestMiddleNameValue, @DestLastValue, @DestGenderValue,@DestDOBValue,@DestMedicareValue,@DestMatchScoreValue, @DestMatchFlagValue

	--Select * From tblAnswerSet where AnswerSetID = @AnswerSetID
	--Select * From tblAnswer where AnswerSetID = 4463263

		WHILE @@FETCH_STATUS = 0  
			BEGIN

			-- Update the Date and userId
			Update dbo.tblAnswerSet Set LastModifiedDate = Getdate() , LastModifiedBy = @DefaultUserId where AnswerSetID = @AnswerSetID
			Update dbo.tblAnswer Set AnswerText = ISNULL(cast(@DestAnswerSetID as varchar),'') where AnswerSetID = @AnswerSetID and QuestionID = @DestAnswerSetIDQuestionID
			
			Update dbo.tblAnswer Set AnswerText = ISNULL(@DestFirstNameValue,'') where AnswerSetID = @AnswerSetID and QuestionID = @SourceDestFirstNameQuestionID
			Update dbo.tblAnswer Set AnswerText = ISNULL(@DestMiddleNameValue,'') where AnswerSetID = @AnswerSetID and QuestionID = @SourceDestMiddleNameQuestionID
			Update dbo.tblAnswer Set AnswerText = ISNULL(@DestLastValue,'') where AnswerSetID = @AnswerSetID and QuestionID = @SourceDestLastQuestionID
			Update dbo.tblAnswer Set AnswerText = ISNULL(@DestGenderValue,'') where AnswerSetID = @AnswerSetID and QuestionID = @SourceDestGenderQuestionID
			Update dbo.tblAnswer Set AnswerText = ISNULL(@DestDOBValue,'') where AnswerSetID = @AnswerSetID and QuestionID = @SourceDestDOBQuestionID
			Update dbo.tblAnswer Set AnswerText = ISNULL(@DestMedicareValue,'') where AnswerSetID = @AnswerSetID and QuestionID = @SourceDestMedicareQuestionID
		
			-- Update the matching properties
			Update dbo.tblAnswer Set AnswerText = ISNULL(@DestMatchScoreValue,'') where AnswerSetID = @AnswerSetID and QuestionID = @SourceDestDestMatchScoreQuestionID
			Update dbo.tblAnswer Set AnswerText = ISNULL(@DestMatchFlagValue,'') where AnswerSetID = @AnswerSetID and QuestionID = @SourceDestDestMatchFlagQuestionID
		
			/*
			Print 'Update dbo.tblAnswer Set AnswerText = '+@DestFirstNameValue +' where AnswerSetID = '+CAst(@AnswerSetID as varchar)+' and QuestionID = '+Cast(@SourceDestFirstNameQuestionID as varchar)
			Print 'Update dbo.tblAnswer Set AnswerText = '+@DestMiddleNameValue +' where AnswerSetID = '+CAst(@AnswerSetID as varchar)+' and QuestionID = '+Cast(@SourceDestMiddleNameQuestionID as varchar)
			Print 'Update dbo.tblAnswer Set AnswerText = '+@DestLastValue +' where AnswerSetID = '+CAst(@AnswerSetID as varchar)+' and QuestionID = '+Cast(@SourceDestLastQuestionID as varchar)
			Print 'Update dbo.tblAnswer Set AnswerText = '+@DestGenderValue +' where AnswerSetID = '+CAst(@AnswerSetID as varchar)+' and QuestionID = '+Cast(@SourceDestGenderQuestionID as varchar)
			Print 'Update dbo.tblAnswer Set AnswerText = '+@DestDOBValue +' where AnswerSetID = '+CAst(@AnswerSetID as varchar)+' and QuestionID = '+Cast(@SourceDestDOBQuestionID as varchar)
			Print 'Update dbo.tblAnswer Set AnswerText = '+@DestMedicareValue +' where AnswerSetID = '+CAst(@AnswerSetID as varchar)+' and QuestionID = '+Cast(@SourceDestMedicareQuestionID as varchar)

			Select * From tblAnswerSet where AnswerSetID = @AnswerSetID
			Select * From tblAnswer where AnswerSetID = @AnswerSetID
			*/

		FETCH NEXT From InsertDestIdentifiers
		Into @AnswerSetID, @DestAnswerSetID,@DestFirstNameValue,@DestMiddleNameValue, @DestLastValue, @DestGenderValue,@DestDOBValue,@DestMedicareValue,@DestMatchScoreValue, @DestMatchFlagValue
	END
	CLOSE InsertDestIdentifiers

	DEALLOCATE InsertDestIdentifiers

	If @debug = 1
	Begin 
		
		SELECT '#Table1', count(*) from #Table1 UNION 
		SELECT '#Table2', count(*) from #Table2 UNION 
		SELECT '#MatchingResults2',count(*) from #MatchingResults4
		SELECT '#Process ',count(*) from #Process 
		select 'AnswerSet-Changed',count (*) from tblAnswerSet where setID = 318 and LastModifiedBy = 28
	End


   --CLEAN UP
    DROP TABLE #Table1
    DROP TABLE #Table2
    DROP TABLE #MatchingResults3
    DROP TABLE #MatchingResults4
    
    --If EXISTS (Select * From INFORMATION_SCHEMA.TABLES where TABLE_NAME =  'MatchingWork1') 
    --DROP TABLE  dbo.[MatchingWork1]
   
END 

/*
	Begin tran 
	EXEC dbo.pr_DLCore_DataSetMatching @ID = 1, @Debug = 1
	Rollback
*/



