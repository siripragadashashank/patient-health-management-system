use PHMS;


-------------------Function to Calculate Age and Name of a Patient--------------------

CREATE FUNCTION function_FullNameAge
(@PatID int) 
	RETURNS TABLE 
	AS 
	RETURN (
			SELECT  
                CONCAT(pat.FirstName, ' ', pat.LastName) as Name,
                DATEDIFF(hour, pat.DOB, GETDATE())/8766 AS Age       
				from PHMS.dbo.Patient pat		
				WHERE pat.PatID = @PatID
        );
       
select * from function_FullNameAge(107)



----------------View to get all the details of Patient (Demographic Details, Vaccination, EPOC, InsuranceProvider) -----------------------------
drop view PatientDetails 

CREATE VIEW PatientDetails AS SELECT 
pat.PatID, pat.FirstName, pat.LastName, pat.DoB, pat.Street, pat.City, pat.State, pat.ZipCode, pat.PhoneNo, pat.EmailAddress,
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