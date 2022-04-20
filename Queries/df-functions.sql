use PHMS;


----------------View to get all the details of Patient (Demographic Details, Vaccination, EPOC, InsuranceProvider)-------

drop view PatientDetails 

CREATE VIEW PatientDetails AS SELECT 
pat.PatID, pat.FirstName, pat.LastName, pat.DoB, pat.Street, 
pat.City, pat.State, pat.ZipCode, pat.PhoneNo, pat.EmailAddress,
patdemo.Gender, patdemo.Ethnicity, patdemo.MaritalStatus, patdemo.EmploymentStatus,
ins.InsuranceProviderName, epoc.EPOCFirstName, epoc.EPOCLastName, epoc.EPOCPhoneNo 
FROM PHMS.dbo.Patient pat 
JOIN PHMS.dbo.PatientDemographics patdemo
    ON pat.PatID = patdemo.PatID
JOIN PHMS.dbo.EPOC epoc
	on pat.PatID = epoc.PatID
Join PHMS.dbo.InsuranceProvider ins
	on pat.PatID = ins.PatID
      	
SELECT * FROM PatientDetails;



---------------- View to get all the PatientEncounter level details (Symptoms, Diagnosis, LabResults, Vitals) -----------------------------
drop view PatientEncounterDetails 

CREATE VIEW PatientEncounterDetails AS SELECT 
patenc.PatEncID,
patenc.PatID,
patenc.HealthCareProviderID,
patenc.PatEncAdmitDate,
patenc.AdmitType,
patenc.AdmitLocation,
patenc.PatEncDiscDate,
patenc.DiscLocation,




FROM PHMS.dbo.PatientEncounter patenc 
JOIN PHMS.dbo.PatientDemographics patdemo
    ON pat.PatID = patdemo.PatID
JOIN PHMS.dbo.EPOC epoc
	on pat.PatID = epoc.PatID
Join PHMS.dbo.InsuranceProvider ins
	on pat.PatID = ins.PatID



select 'patenc.'+COLUMN_NAME+',' from information_schema.columns where table_name = 'PatientEncounter'



-------------------Computed Column Age based on function to Calculate Patient Age --------------------
drop function fn_CalculateAge;

CREATE FUNCTION fn_CalculateAge(@PatID int) 
RETURNS int AS 
begin
	Declare @age int = 
		(
			SELECT 
            DATEDIFF(hour, pat.DOB, GETDATE())/8766 AS Age       
			from PHMS.dbo.Patient pat		
			WHERE pat.PatID = @PatID
        );
    RETURN @age;
end

alter table dbo.Patient
Add Age as (dbo.fn_CalculateAge(PatID));

select * from Patient

-----------Computed column LengthOfStay based on function to Calculate LengthOfStay of a Patient Encounter-------------

drop function fn_CalculateLengthOfStay

CREATE FUNCTION fn_CalculateLengthOfStay(@PatEncID INT)
RETURNS INT
AS
   BEGIN
      DECLARE @los int =
         (SELECT isnull(DATEDIFF(day, PatEncAdmitDate, PatEncDiscDate), DATEDIFF(day, PatEncAdmitDate, GETDATE())) as LengthOfStay
          FROM PHMS.dbo.PatientEncounter patenc
          WHERE PatEncID = @PatEncID);
      RETURN @los;
END

ALTER TABLE dbo.PatientEncounter
ADD LengthOfStay AS (dbo.fn_CalculateLengthOfStay(PatEncID));

select * from dbo.PatientEncounter

-----------------Computed Column OrderAmt based on function to consolidate Labs and Prescription amounts--------------------
	
drop function fn_CalculateOrderAmt

create function fn_CalculateOrderAmt(@PatEncID int)
returns double precision
as
	begin
		Declare @OrderAmt double precision = 
			(
			Select 
			Price from
			(
			Select 
			patenc.PatEncID,
			sum(lrd.Price)+ sum(meds.MedPrice) as Price 
			from PatientEncounter patenc
			left join LabResults lr 
				on  patenc.PatEncID = lr.PatEncID
			left join LabResultDetails lrd 
				on lr.TestID = lrd.TestID
			left join Prescription ps 
				on patenc.PatEncID = ps.PatEncID
			left join MedicationDetails meds 
				on ps.MedID = meds.MedID
			group by patenc.PatEncID
			)a
			where a.PatEncID = @PatEncID
			); 
		SET @OrderAmt = ISNULL(@OrderAmt, 0);
		return @OrderAmt;
	end

alter table dbo.Billing
Add OrderTotal as (dbo.fn_CalculateOrderAmt(PatEncID));

Select * from Billing


----------------

USE PHMS;

create function checkAdmitPhysc (@HealthcareProviderID int)
returns BIT
begin
   declare @flag BIT;
   declare @des varchar(40);
   if exists (select Designation from HealthCareProvider where HealthCareProviderID=@HealthcareProviderID AND Designation in ('Attending physician','Emergency physician','Surgeon','Resident Doctor'))
   begin
   set @flag = 1
   end
   else 
   begin
   set @flag = 0
   end
return @flag
end


drop function checkAdmitPhysc

alter table PatientEncounter
drop constraint ckAdmit

alter table PatientEncounter add CONSTRAINT ckAdmit CHECK (dbo.checkAdmitPhysc (HealthCareProviderID) =1);
