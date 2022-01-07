USE [envido_dl]
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'tblLinkStagingProvation')
DROP TABLE [tblLinkStagingProvation]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblLinkStagingProvation](
	AnswerSetID [int] NULL,
	[SourceKey] [nvarchar](30) NOT NULL,
	[FirstName] [nvarchar] (50) NOT NULL,
	[Lastname] [nvarchar] (50) NOT NULL,
	[MRN] [nvarchar] (10)  NOT NULL,
	[Gender] [nvarchar](50) NOT NULL,
	[BirthDate] [datetime] NOT NULL,
	--[BirthDate] [nvarchar] (10)  NOT NULL,
	[AddressLine1] [nvarchar](100)  NULL,
	[AddressLine2] [nvarchar](100) NULL,
	[State] [nvarchar](50)  NULL,
	[Postcode] [nvarchar](4)  NULL,
	[HomePhone] [nvarchar](15)  NULL,
	[WorkPhone] [nvarchar](15) NULL,
	[ExamDate] [datetime] NULL,
	--[ExamDate] [nvarchar] (20) NULL,
	[Procedure] [nvarchar](50) NULL,
	[ProcedureLocation] [nvarchar](50) NULL,
	[AdvancedTo] [nvarchar](100) NULL,
	[WithdrawalTime] [nvarchar](20) NULL,
	[ReasonForProcedure] [nvarchar](100) NULL,
	[ReasonForProcedure2] [nvarchar](100) NULL,
	[ReasonForProcedure3] [nvarchar](100) NULL,
	[Symptom] [nvarchar](50) NULL,
	[Symptom2] [nvarchar](50) NULL,
	[Symptom3] [nvarchar](50) NULL,
	[ProviderRole] [nvarchar](50) NULL,
	[ProviderName] [nvarchar](50) NULL,
	[QualityOfBowelPrep] [nvarchar](10) NULL,
	[ProximalScore] [nvarchar](1) NULL,
	[TransverseScore] [nvarchar](1) NULL,
	[DistalScore] [nvarchar](1) NULL,
	[OverallScore] [nvarchar](1) NULL,
	[ProcedureAllSections] [nvarchar](50) NULL,	
	[ObservationValue] [nvarchar](max) NULL,	
) ON [PRIMARY]
GO
