USE [envido_dl]
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'tblLinkArchiveProvation')
DROP TABLE [tblLinkArchiveProvation]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblLinkArchiveProvation](
	[SourceKey] [nvarchar] (30) NOT NULL, 
	[Difficulty] [nvarchar](50)  NULL,
	[Attribute_Value] [nvarchar](100) NULL,
	[FirstName] [nvarchar] (50) NULL,
	[Lastname] [nvarchar] (50) NOT NULL,
	[MRN] [nvarchar] (10) NOT NULL,
	[Gender] [nvarchar](50) NOT NULL,
	[Date_of_Birth] [datetime]NOT NULL,
	[Address_Line_1] [nvarchar](50)  NULL,
	[Address_Line_2] [nvarchar](50) NULL,
	[State_Territory] [nvarchar](50)  NULL,
	[Postcode] [nvarchar](4)  NULL,
	[Phone_Type] [nvarchar](50)  NULL,
	[Phone_Number] [nvarchar] (12)  NULL,
	[Exam_Date] [datetime]  NULL,
	[Procedure] [nvarchar](50)  NULL,
	[ProcedureLocation] [nvarchar](50)  NULL,
	[Advanced_To] [nvarchar](100) NULL,
	[Withdrawal_Time] [time](7) NULL,
	[Indication] [nvarchar](100) NULL,
	[ProviderRole] [nvarchar] (50) NULL,
	[ProviderName] [nvarchar] (100) NULL
) ON [PRIMARY]
GO