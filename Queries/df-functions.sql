use PHMS;


----------------View for details of Patient(Demographic Details, EPOC, InsuranceProvider)-------

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



---------------- View to get all the PatientEncounter level Symptom and Diagnosis details -----------------------------

drop view PatientEncounterSymDiagDetails 

CREATE VIEW PatientEncounterSymDiagDetails AS SELECT 
patenc.PatEncID,
patenc.PatID,
patenc.HealthCareProviderID,
patenc.PatEncAdmitDate,
patenc.AdmitType,
patenc.AdmitLocation,
patenc.PatEncDiscDate
, patenc.DiscLocation
, symp.SymCode
, sympd.SymName
, diag.DxCode
, diagd.DxName
FROM PHMS.dbo.PatientEncounter patenc 
left JOIN PHMS.dbo.Symptoms symp
    ON patenc.PatEncID = symp.PatEncID
left JOIN PHMS.dbo.SymptomDetails sympd
	on symp.SymCode = sympd.SymCode
left JOIN PHMS.dbo.Diagnosis diag
    ON patenc.PatEncID = diag.PatEncID
left JOIN PHMS.dbo.DiagnosisDetails diagd
	on diag.DxCode = diagd.DxCode

Select * from PatientEncounterSymDiagDetails

--------------------View to get all the PatientEncounter 
----------------level LabResults and VitalSigns details----------------

drop view PatientEncounterLabVitals 

CREATE VIEW PatientEncounterLabVitals AS SELECT 
patenc.PatEncID,
patenc.AdmitType,
patenc.AdmitLocation
, isnull(lrd.TestName, 'N/A') as TestName
, isnull(lr.val, 0) as LabValue
, vsd.VitalName
, ( cast(vs.VitalVal as varchar) + ' ' + vsd.VitalUnit) as VitalValue
FROM PHMS.dbo.PatientEncounter patenc 
left JOIN PHMS.dbo.LabResults lr
    ON patenc.PatEncID = lr.PatEncID
left JOIN PHMS.dbo.LabResultDetails lrd
	on lr.TestID = lrd.TestID
left JOIN PHMS.dbo.VitalSigns vs
    ON patenc.PatEncID = vs.PatEncID
left JOIN PHMS.dbo.VitalSignDetails vsd
	on vs.VitalID = vsd.VitalID

Select * from PatientEncounterLabVitals


---------------- View to get all the PatientEncounter level Billing details -----------------------------

drop view PatientEncounterBilling 

CREATE VIEW PatientEncounterBilling AS SELECT 
patenc.PatEncID,
isnull(sum(lrd.Price), 0) as LabOrderAmt,
isnull(sum(meds.MedPrice), 0) as MedOrderAmt,
isnull(sum(lrd.Price), 0)+sum(meds.MedPrice) as OrderAmt
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


Select * from PatientEncounterBilling




----Computed Column Age based on function to Calculate Patient Age ------------

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

---Computed column LengthOfStay based on 
---function to Calculate LengthOfStay of a Patient Encounter-------------

drop function fn_CalculateLengthOfStay

CREATE FUNCTION fn_CalculateLengthOfStay(@PatEncID INT)
RETURNS INT
AS
   BEGIN
      DECLARE @los int =
         (
		  SELECT isnull(DATEDIFF(day, PatEncAdmitDate, PatEncDiscDate), 
		  DATEDIFF(day, PatEncAdmitDate, GETDATE())) as LengthOfStay
          FROM PHMS.dbo.PatientEncounter patenc
          WHERE PatEncID = @PatEncID
		 );
      RETURN @los;
END

ALTER TABLE dbo.PatientEncounter
ADD LengthOfStay AS (dbo.fn_CalculateLengthOfStay(PatEncID));

select * from dbo.PatientEncounter

---Computed Column OrderTotal based on 
---function to consolidate Labs and Prescription amounts--------------------
	
drop function fn_CalculateOrderTotal

create function fn_CalculateOrderTotal(@PatEncID int)
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
			isnull(sum(lrd.Price), 0)+ sum(meds.MedPrice) as Price 
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
		return @OrderAmt;
	end

alter table dbo.Billing
Add OrderTotal as (dbo.fn_CalculateOrderTotal(PatEncID));

Select * from Billing

-----Test for OrderTotal

--insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20001, 3247, 179, '2020-01-11', 14);


----------------Table level CHECK constraint on Admitting Physician----------
drop function checkAdmitPhysc

create function checkAdmitPhysc (@HealthcareProviderID int)
returns BIT
begin
   declare @flag BIT;
   declare @des varchar(40);
   if exists (select Designation from HealthCareProvider 
			where HealthCareProviderID=@HealthcareProviderID AND 
			Designation in ('Attending physician','Emergency physician',
							'Surgeon','Resident Doctor'))
   begin
       set @flag = 1
   end
   else 
	   begin
		   set @flag = 0
	   end
return @flag
end


alter table PatientEncounter
drop constraint ckAdmit

alter table PatientEncounter add CONSTRAINT ckAdmit CHECK (dbo.checkAdmitPhysc (HealthCareProviderID) =1);

-----------Testing for Admit Physician constraint----

-------- 3215 Hospital pharmacist (Cannot Admit a Patient)----------

insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20111, 130, 3215, '2022-04-07', 'Emergency', 'Intensive Care Unit (ICU)', NULL, NULL);



----------------Table level CHECK constraint on Diagnosing Physician----------
drop function checkDiagnosingPhysc

create function checkDiagnosingPhysc(@HealthcareProviderID int)
returns BIT
begin
   declare @flag BIT;
   declare @des varchar(40);
   if exists (select Designation from HealthCareProvider 
   where HealthCareProviderID=@HealthcareProviderID AND Designation in 
   (
		'Hospital pharmacist',
		'Chief Medical Officer',
		'Social worker',
		'Physical therapist',
		'Clinical Assitant',
		'Anesthesiologist',
		'Pathologist',
		'Chief executive officer'
   ))
   begin
       set @flag = 0
   end
   else 
	   begin
		   set @flag = 1
	   end
return @flag
end


alter table Diagnosis
drop constraint ckDiagnosis

alter table Diagnosis add CONSTRAINT ckDiagnosis CHECK (dbo.checkDiagnosingPhysc (HealthCareProviderID) =1);

insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20099, 3215, 46);


--------Trigger to check and Update PaymentStatus based on OrderTotal and ClaimSanctionAmt---------------------------

drop trigger tr_UpdatePaymentStatus

Create trigger tr_UpdatePaymentStatus
on Billing
after INSERT, UPDATE, DELETE
As begin
declare @OrderAmt money = 0;
declare @PatEncID varchar(20);
declare @ClaimAmt money = 0;
declare @status varchar(40);
select @PatEncID = isnull (i.PatEncID, d.PatEncID)
   from inserted i full join deleted d 
   on i.PatEncID = d.PatEncID;
select @OrderAmt = OrderTotal,
		@ClaimAmt=ClaimSanctionAmt
   from Billing
       where PatEncID = @PatEncID;
if @ClaimAmt <= (@OrderAmt*0.7)
set @status = 'Follow up required'
else if @ClaimAmt > (@OrderAmt*0.7) AND @ClaimAmt <= (@OrderAmt)
set @status = 'Partial Payment Received'
else 
set @status = 'Complete Payment Received'
update Billing
set PaymentStatus = @status
where PatEncID = @PatEncID
end


--insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7212, 20002, NULL, 60);


--insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (700451, 20001, 'Yes', 60);

Select * from Billing