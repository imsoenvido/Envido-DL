USE [envido_dl]
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'tblLinkLandProvation')
DROP TABLE [tblLinkLandProvation]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblLinkLandProvation](
	[MRN] [varchar](max) NOT NULL,
	[Date_of_Birth] [datetime] NOT NULL,
	[Patient_Name] [varchar](max) NOT NULL,
	[Gender] [varchar](max) NULL,
	[Address_Line_1] [varchar](max) NULL,
	[Address_Line_2] [varchar](max) NULL,
	[State] [varchar](max) NULL,
	[Zip_Code] [varchar](max) NULL,
	[City] [varchar](max) NULL,
	[Phone_Type] [varchar](max) NULL,
	[Phone_Number] [varchar](max) NULL,
	[Exam_Date] [datetime] NULL,
	[Procedure] [varchar](max) NULL,
	[Advanced_To] [varchar](max) NULL,
	[Withdrawal_Time] [datetime] NULL,
	[Difficulty] [varchar](max) NULL,
	[Attribute_Value] [varchar](max) NULL,
	[Indication] [varchar](max) NULL,
	[Provider_Name] [varchar](max) NULL,
	[Role] [varchar](max) NULL,
	[location] [varchar](max) NULL,
	[Symptoms] [varchar](max) NULL
) ON [PRIMARY]
GO
