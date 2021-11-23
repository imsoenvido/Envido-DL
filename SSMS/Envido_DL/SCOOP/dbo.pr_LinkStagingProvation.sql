USE [envido_dl]
GO
/****** Object:  StoredProcedure [dbo].[pr_LinkStagingProvation]    Script Date: 13/06/2021 7:57:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=========================================================================================
    DESCRIPTION:     Process raw Provation data into a consumable data for SCOOP

	USE:			EXEC pr_LinkStagingProvation
    
	PARAMETERS:		 

    REVISIONS:		01/10/2020	S.Walsh		Created 
					30/10/2020	S.Walsh		Add block to insert the ObservationValue
					04/11/2020	S.Walsh		Remove block that generates the observation value. This is now done though dbo.pr_LinkObservationValue as a separate event
					17/11/2020	S.WAlsh		Trim the Gender to M or F 
					13/06/2021	S.Walsh		Add filters for Name, Gender and phone in the archive folder
					08/07/2021	DJF			Add in City
					23/07/2021	DJF			Change Distal to look for left (previously it was looking for right) and proximal to look for right (previously it was looking for left)
					29/07/2021	DJF			Add in IDLocation

-- ========================================================================================*/


ALTER PROCEDURE [dbo].[pr_LinkStagingProvation]  
	   	
AS
BEGIN

	--STEP-1: Compile the source data for importing

	IF OBJECT_ID('tempdb..#tblLinkSourceProvation') IS NOT NULL DROP TABLE #tblLinkSourceProvation	
	
	select convert(bigint,ltrim(rtrim(MRN))+ convert(varchar,Exam_Date,112)+left (convert(varchar,Exam_Date,114),2)) as SourceKey
			,Difficulty
			,Attribute_Value
			--,Given_Name as FirstName
			--,Surname as LastName
			,ltrim(rtrim(substring(Patient_Name,CHARINDEX(',',Patient_Name)+1,len(Patient_Name)))) as FirstName
			,ltrim(rtrim(substring(Patient_Name,0,CHARINDEX(',',Patient_Name)))) as LastName
			,LTRIM(rtrim(MRN)) as MRN
			,CASE WHEN LTRIM(rtrim(Gender)) in ('Male','M') then 'M'
				WHEN LTRIM(rtrim(Gender))in ('Female','F') then 'F'
			End as Gender
			,convert(smalldatetime,Date_of_Birth) as BirthDate		-- converted to varchar ready for import
			,LTRIM(rtrim(Address_Line_1)) as AddressLine1
			,LTRIM(rtrim(Address_Line_2)) as AddressLine2
			,LTRIM(rtrim(State)) as [State]
			,LTRIM(rtrim(Zip_Code)) as PostCode
			,LTRIM(rtrim(City)) as City
			,LTRIM(rtrim(Phone_Type)) as PhoneType
			,LTRIM(rtrim(Phone_Number)) as PhoneNumber
			,Exam_Date as ExamDate
			--,CONVERT(varchar, Exam_Date,105)	as ExamDateOnly											-- Convert to DateTime
			,LTRIM(rtrim([Procedure])) as [Procedure]
			,[Location] as ProcedureLocation								-- Spec refers to Location but this is not in the file
			,LTRIM(rtrim(Advanced_To)) as AdvancedTo
			,LTRIM(rtrim(Withdrawal_Time)) as WihdrawalTime
			,convert(varchar,datepart(minute,Withdrawal_time)) + ' m '  + convert(varchar,datepart(second,Withdrawal_time)) + ' s' as WihdrawalTimeConverted
			,LTRIM(rtrim(Indication)) as ReasonForProcedure
			,[Provider_Name] as ProviderName									-- Spec refers to role but this is not in the data
			,[Role] as ProviderRole									
			,[Symptoms]
			,LTRIM(rtrim(IDLocation)) as IDLocation
	Into	#tblLinkSourceProvation	
	from	dbo.tblLinkLandProvation

	Update #tblLinkSourceProvation	 
	set Attribute_Value = 9 where Difficulty = 'Total BBPS Score 9'

	IF OBJECT_ID('tempdb..#ProvationPatientRecords') IS NOT NULL DROP TABLE #ProvationPatientRecords	
	select	Distinct L.MRN											
			,L.SourceKey										
			,L.FirstName,L.LastName,L.Gender,L.BirthDate		
			,L.AddressLine1,L.AddressLine2,L.[State],L.PostCode, L.City
			,ExamDate											
			,L.[Procedure]										
			,L.ProcedureLocation								
			,L.AdvancedTo										
			,L.WihdrawalTimeConverted
			,L.IDLocation
	into	#ProvationPatientRecords
	from	#tblLinkSourceProvation L							
	where AdvancedTo is not null
			
	IF OBJECT_ID('tempdb..#Indication') IS NOT NULL DROP TABLE #Indication
	select	*
			,ROW_NUMBER() over (partition by SourceKey order by RFPSequence) as RowID
	into	#Indication
			
	from	( 
			select	distinct 
					SourceKey
					, ReasonForProcedure -- indication 
					,case when ReasonForProcedure like '%FOBT%' then 1
							when ReasonForProcedure like '%Symptom%' then 2
							when ReasonForProcedure like '%Abnormal%' then 3
							else  4
					end as RFPSequence
			 
			FROM	#tblLinkSourceProvation	
			where ReasonForProcedure is not null 
			--and SourceKey = '10122861-20200928'
		) as X

	IF OBJECT_ID('tempdb..#Symptoms') IS NOT NULL DROP TABLE #Symptoms
	select	* 
			,ROW_NUMBER() over (partition by SourceKey order by Symptoms) as RowID
	into	#Symptoms
	from	(		
			select	distinct SourceKey
					,Symptoms-- indication 
					
			FROM	#tblLinkSourceProvation	
			where	ReasonForProcedure = 'Symptoms'
			and		Symptoms is not null 
		) as X

	IF OBJECT_ID('tempdb..#HP') IS NOT NULL DROP TABLE #HP
	select	distinct SourceKey,PhoneNumber  as HomePhone 
	into	#HP
	from	#tblLinkSourceProvation  where PhoneType = 'Home'

	IF OBJECT_ID('tempdb..#WP') IS NOT NULL DROP TABLE #WP
	select	distinct SourceKey,PhoneNumber  as WorkPhone 
	into	#WP
	from	#tblLinkSourceProvation  where PhoneType = 'Work'
	
	IF OBJECT_ID('tempdb..#DR') IS NOT NULL DROP TABLE #DR
	select *
	into	#DR
	from	( 
			select X.* ,ROW_NUMBER() over (partition by SourceKey order by ProviderRole,ProviderName ) as Rowid 
			from (select distinct SourceKey,ProviderRole,ProviderName from	#tblLinkSourceProvation  where ProviderRole= 'Doctor') as X
			) X1
	where X1.Rowid = 1

	IF OBJECT_ID('tempdb..#BP') IS NOT NULL DROP TABLE #BP	
	select *
	into	#BP
	from	( 
			select X.* ,ROW_NUMBER() over (partition by SourceKey order by QualityOfBowelPrep) as Rowid 
			from ( select distinct SourceKey,Attribute_Value as QualityOfBowelPrep from	#tblLinkSourceProvation where Difficulty = 'Quality of Bowel Prep') as X 
			) X1
	where X1.Rowid = 1

	IF OBJECT_ID('tempdb..#Proximal') IS NOT NULL DROP TABLE #Proximal
	select *
	into	#Proximal
	from	( 
			select X.* ,ROW_NUMBER() over (partition by SourceKey order by ProximalScore) as Rowid 
			from (
				select	distinct SourceKey,substring(Attribute_Value,CHARINDEX('= ',Attribute_Value)+2,Len(Attribute_Value)) as ProximalScore 
				from #tblLinkSourceProvation where Difficulty like 'BBPS%' and Attribute_Value like '%right =%'
				and isnumeric(substring(Attribute_Value,CHARINDEX('= ',Attribute_Value)+2,Len(Attribute_Value)) ) = 1
				) as X
			) X1
	where X1.Rowid = 1
	
	IF OBJECT_ID('tempdb..#Transverse') IS NOT NULL DROP TABLE #Transverse
	select *
	into	#Transverse
	from	( 
			select X.* ,ROW_NUMBER() over (partition by SourceKey order by TransverseScore) as Rowid 
			from (
				select	distinct SourceKey,substring(Attribute_Value,CHARINDEX('= ',Attribute_Value)+2,Len(Attribute_Value)) as TransverseScore 
				from #tblLinkSourceProvation where Difficulty like 'BBPS%' and Attribute_Value like '%transverse =%'
				and isnumeric(substring(Attribute_Value,CHARINDEX('= ',Attribute_Value)+2,Len(Attribute_Value)) ) = 1
				) as X
				
			) X1
	where X1.Rowid = 1

	IF OBJECT_ID('tempdb..#Distal') IS NOT NULL DROP TABLE #Distal
	select *
	into	#Distal
	from	( 
			select X.* ,ROW_NUMBER() over (partition by SourceKey order by DistalScore ) as Rowid 
			from (
					select	distinct SourceKey,substring(Attribute_Value,CHARINDEX('= ',Attribute_Value)+2,Len(Attribute_Value)) as DistalScore 
					from	#tblLinkSourceProvation where Difficulty like 'BBPS%' and Attribute_Value like '%left =%'
					and isnumeric(substring(Attribute_Value,CHARINDEX('= ',Attribute_Value)+2,Len(Attribute_Value)) ) = 1
				) as X
			) X1
	where X1.Rowid = 1

	IF OBJECT_ID('tempdb..#Total') IS NOT NULL DROP TABLE #Total
	select *
	into	#Total
	from	( 
			select X.* ,ROW_NUMBER() over (partition by SourceKey order by OverallScore ) as Rowid 
			from (
				select	distinct SourceKey,Attribute_Value as OverallScore 
				from	#tblLinkSourceProvation where Difficulty like '%BBPS%' and isnumeric(Attribute_Value) = 1
				) as X
			) X1
	where X1.Rowid = 1

	create nonclustered index idx on #tblLinkSourceProvation (SourceKey)	-- select * from #tblLinkSourceProvation
	create nonclustered index idx on #ProvationPatientRecords (SourceKey)	-- select * from #ProvationPatientRecords
	create nonclustered index idx on #Indication (SourceKey)				-- select * from #Indication
	create nonclustered index idx on #Symptoms (SourceKey)					-- select * from #Symptoms
	create nonclustered index idx on #HP (SourceKey)						-- select * from #HP
	create nonclustered index idx on #WP (SourceKey)						-- select * from #WP
	create nonclustered index idx on #DR (SourceKey)						-- select * from #DR
	create nonclustered index idx on #BP (SourceKey)						-- select * from #BP
	create nonclustered index idx on #Proximal (SourceKey)					-- select * from #Proximal where isnumeric(proximalScore) = 0
	create nonclustered index idx on #Transverse (SourceKey)				-- select * from #Transverse where isnumeric(TransverseScore) = 0
	create nonclustered index idx on #Distal (SourceKey)					-- select *  from #Distal where isnumeric(DistalScore) = 0
	
	--STEP-3: Convert the data into a single record for each procedure. This is stored in the staging table for import to the envido_dl collection

	Insert into tblLinkStagingProvation (
				SourceKey,FirstName,Lastname,MRN,Gender,BirthDate
				,AddressLine1,AddressLine2,[State],Postcode,Suburb, HomePhone,WorkPhone
				,ExamDate
				,[Procedure],ProcedureLocation
				,AdvancedTo
				,WithdrawalTime
				,ReasonForProcedure,ReasonForProcedure2,ReasonForProcedure3
				,Symptom,Symptom2,Symptom3,ProviderRole,ProviderName,QualityOfBowelPrep,ProximalScore,TransverseScore,DistalScore,OverallScore,ProcedureAllSections
				,IDLocation)
			
	select	 X.SourceKey,FirstName,LastName,MRN,Gender,BirthDate
			,AddressLine1,AddressLine2,[State],PostCode,City, HomePhone,WorkPhone
			,ExamDate
			,[Procedure]
			,ProcedureLocation
			,AdvancedTo
			,WihdrawalTimeConverted
			,ReasonForProcedure
			,ReasonForProcedure2
			,ReasonForProcedure3
			,Symptom,Symptom2,Symptom3,ProviderRole,ProviderName,QualityOfBowelPrep,ProximalScore,TransverseScore,DistalScore,OverallScore,ProcedureAllSections 
			,IDLocation
	from	(
			select	ROW_NUMBER () Over (Partition by L.SourceKey order by ExamDate) as RowID
					,L.SourceKey,L.FirstName,L.LastName,L.MRN,L.Gender
					,L.BirthDate
					--,convert(varchar, L.BirthDate,105) as BirthDate
					,L.AddressLine1,L.AddressLine2,L.[State],L.PostCode,L.City, hp.HomePhone, WP.WorkPhone 
					--,convert(varchar,L.ExamDate,105) + ' ' +replace(RIGHT(CONVERT(VARCHAR, CONVERT(DATETIME, L.ExamDate), 131), 14),':00:000',' ') AS ExamDate -- ExamDateDMY for tblAnswer
					--,convert(varchar,L.ExamDate,110) + ' ' +replace(RIGHT(CONVERT(VARCHAR, CONVERT(DATETIME, L.ExamDate), 131), 14),':00:000',' ') AS ExamDate -- ExamDateMDY for Numbered
					,ExamDate
					,L.[Procedure]
					,L.ProcedureLocation
					,L.AdvancedTo
					,L.WihdrawalTimeConverted
					,I1.ReasonForProcedure as ReasonForProcedure
					,I2.ReasonForProcedure as ReasonForProcedure2
					,I3.ReasonForProcedure as ReasonForProcedure3
					,S1.Symptoms as Symptom
					,S2.Symptoms as Symptom2
					,S3.Symptoms as Symptom3
					,DR.ProviderRole as ProviderRole
					,DR.ProviderName as ProviderName
					,BP.QualityOfBowelPrep
					,PS.ProximalScore				-- 9265 up from 8849
					,TS.TransverseScore
					,DS.DistalScore
					,OS.OverallScore
					,Case when PS.ProximalScore <= 1 OR TS.TransverseScore <= 1 OR DS.DistalScore  <=1  then 'No'
						when PS.ProximalScore > 1 AND TS.TransverseScore > 1 AND DS.DistalScore  >1  then 'Yes'
						Else NULL 
					End [ProcedureAllSections]
					,L.IDLocation
			from	#ProvationPatientRecords L 
			left join #HP as HP on L.SourceKey = HP.SourceKey
			left join #WP as WP on L.SourceKey = WP.SourceKey
			left join #DR as DR on L.SourceKey = DR.SourceKey
			left join #BP as BP on L.SourceKey = BP.SourceKey
			left join #Proximal as PS on L.SourceKey = PS.SourceKey	--: select * from tblAnswersOptions where questionID = 4502, 0,1,2,3
			left join #Transverse as TS on L.SourceKey = TS.SourceKey
			left join #Distal as DS on L.SourceKey = DS.SourceKey
			left join #Total as OS on L.SourceKey = OS.SourceKey
			-- Indications 
			left join( select SourceKey,ReasonForProcedure from #Indication where RowID = 1) as I1 on L.SourceKey = I1.SourceKey
			left join( select SourceKey,ReasonForProcedure from #Indication where RowID = 2) as I2 on L.SourceKey = I2.SourceKey
			left join( select SourceKey,ReasonForProcedure from #Indication where RowID = 3) as I3 on L.SourceKey = I3.SourceKey
			----Symptoms
			left join( select SourceKey,Symptoms from #Symptoms where RowID = 1) as S1 on L.SourceKey = S1.SourceKey
			left join(select SourceKey,Symptoms from #Symptoms where RowID = 2) as S2 on L.SourceKey = S2.SourceKey
			left join(select SourceKey,Symptoms from #Symptoms where  RowID = 3) as S3 on L.SourceKey = S3.SourceKey
			) as X

		where X.RowID = 1
		and SourceKey not in (select SourceKey from tblLinkStagingProvation) 
		

	--STEP-5: Save any new data to the archive table
	--truncate table tblLinkArchiveProvation

	Insert into dbo.tblLinkArchiveProvation (
			SourceKey,Difficulty,Attribute_Value
			,FirstName,Lastname
			 ,MRN,Gender,Date_of_Birth
			,Address_Line_1,Address_Line_2,State_Territory,Postcode,Suburb
			,Phone_Type,Phone_Number
			,Exam_Date,[Procedure],ProcedureLocation
			,Advanced_To,Withdrawal_Time,Indication,ProviderRole,ProviderName
			,IDLocation
	)
		
	selecT	SourceKey
			,Difficulty,Attribute_Value
			,FirstName,LastName
			,MRN,Gender,convert(smalldatetime,BirthDate)
			,AddressLine1,AddressLine2,[State],PostCode, City
			,PhoneType,replace(replace(replace(PhoneNumber,'(',''),')',''),' ','') as PhoneNumber
			,convert(datetime,ExamDate),[Procedure],ProcedureLocation
			,AdvancedTo,WihdrawalTime,ReasonForProcedure,ProviderRole,ProviderName
			,IDLocation
	FROM	#tblLinkSourceProvation
	where	SourceKey not in (select SourceKey from dbo.tblLinkArchiveProvation)		
	and FirstName is not null 
	and LastName is not null 
	and Gender is not null 
	
	-- We might need to remove this depending on response from erin about data cleaning 
	and ISNUMERIC(PhoneNumber) = 1

	
END
