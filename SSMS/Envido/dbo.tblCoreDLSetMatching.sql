USE [envido]

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'tblCoreDLSetMatching')
DROP TABLE [tblCoreDLSetMatching]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblCoreDLSetMatching](
	[ID] [int] NOT NULL,
	[MatchDescription] [nvarchar](50) NOT NULL,
	[DefaultUserID] int NOT NULL,

	[SourceDatabase] [nvarchar] (20) NOT NULL,
	[SourceAccountID] [nvarchar](50) NOT NULL,
	[SourceCollectionID] [int] NOT NULL,
	[SourceSetID] [int] NOT NULL,
	[SourceFirstNameQuestionID] [int] NOT NULL,
	[SourceMiddleNameQuestionID] [int]  NULL,
	[SourceLastNameQuestionID] [int] NOT NULL,
	[SourceDefaultGender] char (1) NULL,
	[SourceGenderQuestionID] [int] NOT NULL,
	[SourceDOBQuestionID] [int] NOT NULL,
	[SourceMedicareQuestionID] [int] NULL,
	
	[SourceDestFirstNameQuestionID] [int] NOT NULL,
	[SourceDestMiddleNameQuestionID] [int]  NULL,
	[SourceDestLastNameQuestionID] [int] NOT NULL,
	[SourceDestDefaultGender] char (1) NULL,
	[SourceDestGenderQuestionID] [int] NOT NULL,
	[SourceDestDOBQuestionID] [int] NOT NULL,
	[SourceDestMedicareQuestionID] [int] NULL,
	[SourceDestMatchScoreQuestionID] [int] NULL,
	[SourceDestMatchFlagQuestionID] [int] NULL,
	
	[DestDatabase] [nvarchar] (20) NOT NULL,
	[DestAccountID] [nvarchar](50) NOT NULL,
	[DestGroupID] [int] NOT NULL,
	[DestCollectionID] [int] NOT NULL,
	[DestSetID] [int] NOT NULL,
	[DestAnswerSetIDQuestionID] [int] NOT NULL,
	[DestFirstNameQuestionID] [int] NOT NULL,
	[DestMiddleNameQuestionID] [int] NULL,
	[DestLastNameQuestionID] [int] NOT NULL,
	[DestDefaultGender] char (1) NULL,
	[DestGenderQuestionID] [int] NOT NULL,
	[DestDOBQuestionID] [int] NOT NULL,
	[DestMedicareQuestionID] [int] NULL,
	
	[StatusQuestionID] int NULL,
	[ActionSP] [nvarchar](50)  NULL
) ON [PRIMARY]
GO





