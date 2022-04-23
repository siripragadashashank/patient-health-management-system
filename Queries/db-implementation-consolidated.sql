use PHMS;

---------------------------DROP--------------------------

Drop table if exists  dbo.PatientDemographics;
drop table if exists dbo.Vaccination;
drop table if exists dbo.InsuranceProvider;
drop table if exists dbo.EPOC;

Drop table if exists dbo.Diagnosis;
Drop table if exists dbo.DiagnosisDetails;

Drop table if exists dbo.LabResults;
Drop table if exists dbo.LabResultDetails;

Drop table if exists dbo.VitalSigns;
Drop table if exists dbo.VitalSignDetails;

Drop table if exists dbo.Symptoms;
Drop table if exists dbo.SymptomDetails;

Drop table if exists dbo.Billing;
Drop table if exists dbo.Prescription;

Drop table if exists dbo.MedicationDetails;
drop table if exists dbo.PatientEncounter;

drop table if exists dbo.Patient;
Drop table if exists dbo.HealthcareProvider;

drop function if exists fn_CalculateAge;
drop function if exists fn_CalculateLengthOfStay	
drop function if exists fn_CalculateOrderTotal

drop function if exists checkAdmitPhysc
drop function if exists checkDiagnosingPhysc

drop trigger if exists tr_UpdatePaymentStatus

drop view if exists PatientDetails 
drop view if exists PatientEncounterSymDiagDetails 
drop view if exists PatientEncounterLabVitals
drop view if exists PatientEncounterBilling


-----------------------CREATE----------------------------

 CREATE TABLE Patient
(
PatID INT PRIMARY KEY, 
FirstName VARCHAR(45),
LastName VARCHAR(45),
DoB DateTime,
Street VARCHAR(45),
City VARCHAR(45),
State VARCHAR(45),
ZipCode INT,
PhoneNo BIGINT, 
EmailAddress VARCHAR(45)
);


CREATE TABLE HealthCareProvider
(
HealthCareProviderID INT PRIMARY KEY, 
Designation VARCHAR(45),
EmpFirstName VARCHAR(45),
EmpLastName VARCHAR(45),
EmpContactNo BIGINT
);

 CREATE TABLE PatientEncounter
(
PatEncID INT PRIMARY KEY, 
PatID INT NOT NULL REFERENCES Patient(PatID),
HealthCareProviderID INT NOT NULL 
REFERENCES HealthCareProvider(HealthCareProviderID),
PatEncAdmitDate DateTime,
AdmitType VARCHAR(45),
AdmitLocation VARCHAR(45),
PatEncDiscDate DATETIME,
DiscLocation VARCHAR(45)
);


CREATE TABLE SymptomDetails
(
SymCode INT PRIMARY KEY, 
SymName VARCHAR(45)
);

CREATE TABLE Symptoms
(
PatEncID INT NOT NULL REFERENCES PatientEncounter(PatEncID),
SymCode INT NOT NULL REFERENCES SymptomDetails(SymCode),
Duration INT
);


create table DiagnosisDetails
(
DxCode int primary key,
DxName varchar(45)
);

create table Diagnosis
(
PatEncID int not null references PatientEncounter(PatEncID),
HealthCareProviderID int not null 
references HealthCareProvider(HealthCareProviderID),
DxCode int not null references DiagnosisDetails(DxCode)
);


CREATE TABLE LabResultDetails
(
TestID INT PRIMARY KEY ,
TestName VARCHAR(45),
Price DOUBLE PRECISION
);

CREATE TABLE LabResults
(
PatEncID INT NOT NULL REFERENCES PatientEncounter(PatEncID), 
HealthCareProviderID INT NOT NULL 
REFERENCES HealthCareProvider(HealthCareProviderID),
TestID INT NOT NULL REFERENCES LabResultDetails(TestID),
StoreTime Date,
Val double precision
);


CREATE TABLE VitalSignDetails
(
VitalID INT PRIMARY KEY ,
VitalName VARCHAR(45),
VitalUnit VARCHAR(45)
);

CREATE TABLE VitalSigns
(
PatEncID INT  NOT NULL REFERENCES PatientEncounter(PatEncID),
VitalID INT NOT NULL REFERENCES VitalSignDetails(VitalID),
StoreTime DATETIME,
VitalVal DOUBLE PRECISION
);


CREATE TABLE MedicationDetails
(
MedID INT PRIMARY KEY, 
MedName VARCHAR(45),
MedPrice DOUBLE PRECISION
);

 CREATE TABLE Prescription
(
PrescriptionID INT PRIMARY KEY, 
MedID INT NOT NULL REFERENCES MedicationDetails(MedID),
PatEncID INT NOT NULL REFERENCES PatientEncounter(PatEncID),
HealthCareProviderID INT NOT NULL 
REFERENCES HealthCareProvider(HealthCareProviderID),
PrescStartDate DATETIME,
PrescEndDate DATETIME,
PrescDose FLOAT,
PrescQty FLOAT
);

CREATE TABLE Billing
(
BillingID INT PRIMARY KEY, 
PatEncID INT NOT NULL
REFERENCES PatientEncounter(PatEncID),
PaymentStatus VARCHAR(45),
ClaimSanctionAmt DOUBLE PRECISION
);

CREATE TABLE PatientDemographics
(
PatID INT NOT NULL REFERENCES Patient(PatID),
Gender VARCHAR(45),
Race VARCHAR(45),
Ethnicity VARCHAR(45),
MaritalStatus VARCHAR(45),
EmploymentStatus VARCHAR(45)
);

Create table Vaccination
(
LotNo int Primary key,
PatID INT NOT NULL REFERENCES Patient(PatID),
VaccinationStatus VARCHAR(45),
NoOfDoses int,
VaccineName  VARCHAR(45),
BoosterStatus VARCHAR(45)
);


CREATE TABLE EPOC
(
EPOCID int Primary key,
PatID INT NOT NULL REFERENCES Patient(PatID),
EPOCFirstName VARCHAR(45),
EPOCLastName VARCHAR(45),
EPOCPhoneNo BIGINT
);

create table InsuranceProvider
(
InsuranceID int primary key,
PatID INT NOT NULL REFERENCES Patient(PatID),
InsuranceProviderName VARCHAR(45)
);

------------Computed Columns, Table level check constraints, Trigger-------------------------------------

-------------Computed Column Age based on function to Calculate Patient Age ------------

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

alter table dbo.Patient Add Age as (dbo.fn_CalculateAge(PatID));


--------------Computed column LengthOfStay based on----------
--------------function to Calculate LengthOfStay of a Patient Encounter-------------

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


---Computed Column OrderTotal based on 
---function to consolidate Labs and Prescription amounts--------------------

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


----------------Table level CHECK constraint on Admitting Physician----------


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
drop constraint if exists ckAdmit

alter table PatientEncounter add CONSTRAINT ckAdmit CHECK (dbo.checkAdmitPhysc (HealthCareProviderID) =1);



----------------Table level CHECK constraint on Diagnosing Physician----------


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
drop constraint if exists ckDiagnosis

alter table Diagnosis add CONSTRAINT ckDiagnosis CHECK (dbo.checkDiagnosingPhysc (HealthCareProviderID) =1);




--------Trigger to check and Update PaymentStatus based on OrderTotal and ClaimSanctionAmt---------------------------


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
		begin 
			set @status = 'Follow up required'
			PRINT 'PaymentStatus set as - Follow up required'
		end

	else if @ClaimAmt > (@OrderAmt*0.7) AND @ClaimAmt < (@OrderAmt)
		begin
			set @status = 'Partial Payment Received'
			PRINT 'PaymentStatus set as - Partial Payment Received'
		end
	else 
		begin
			set @status = 'Complete Payment Received'
			PRINT 'PaymentStatus set as - Complete Payment Received'
		end 
	update Billing
	set PaymentStatus = @status
	where PatEncID = @PatEncID
end


--------------------------------------DDL DATA INSERT Scripts----------------------------------------------------


---------------------------Patient--------------------------------


insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (101, 'Oscar' ,'Yang','1962-06-10', '2210 Elmwood Avenue', 'Mesa', 'Arizona',85201,4809625179, 'oscar.yang@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (102, 'Richard' ,'Rice','1962-10-14', '4013 Southern Avenue', 'Eureka', 'Missouri',63025,6369382484, 'richard.rice@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (103, 'Joshua' ,'Dean','1963-04-13', '4877 Lynch Street', 'Oakland', 'California',94612,9252096032, 'joshua.dean@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (104, 'William' ,'Ruiz','1963-12-22', '1356 Worthington Drive', 'Red Oak', 'Texas',75154,9725767414, 'william.ruiz@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (105, 'Joseph' ,'Kent','1964-06-16', '157 Lynn Ogden Lane', 'Beaumont', 'Texas',77705,4098407436, 'joseph.kent@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (106, 'Joshua' ,'Alexander','1967-07-16', '2132 Haul Road', 'Lansing', 'Ohio',43934,6509955757, 'joshua.alexander@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (107, 'Robert' ,'Richards','1968-12-29', '3600 Holt Street', 'West Palm Beach', 'Florida',33410,5612612075, 'robert.richards@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (108, 'David' ,'Mejia','1970-05-14', '3444 Libby Street', 'Beverly Hills', 'California',90210,3102767127, 'david.mejia@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (109, 'Jeffrey' ,'Sutton','1973-12-03', '1468 Midway Road', 'Ratcliff', 'Arkansas',72951,4796353319, 'jeffrey.sutton@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (110, 'Ronald' ,'Mitchell','1974-02-06', '1962 Oakwood Circle', 'Riverside', 'California',92501,9493181359, 'ronald.mitchell@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (111, 'Micheal' ,'Hall','1974-06-10', '13 Desert Broom Court', 'Jersey City', 'New Jersey',73040,2017183614, 'micheal.hall@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (112, 'Joshua' ,'Noble','1976-02-20', '2688 Pritchard Court', 'Owatonna', 'Minnesota',55060,5074087953, 'joshua.noble@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (113, 'Brett' ,'Walker','1978-01-29', '3881 Heron Way', 'Portland', 'Oregon',97205,5038304159, 'brett.walker@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (114, 'Mark' ,'Swanson','1979-10-18', '2166 Tibbs Avenue', 'Helena', 'Montana',59601,4067818712, 'mark.swanson@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (115, 'John' ,'Thompson','1981-09-27', '4962 Pearl Street', 'Sacramento', 'California',95814,9163164566, 'john.thompson@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (116, 'Lauren' ,'Kim','1983-07-05', '1905 Simpson Avenue', 'Akron', 'Pennsylvania',17501,7178590339, 'lauren.kim@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (117, 'Alisha' ,'Smith','1984-06-19', '2899 Buffalo Creek Road', 'Franklin', 'Tennessee',37064,6157940426, 'alisha.smith@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (118, 'Laura' ,'Rodgers','1986-10-16', '4305 Godfrey Street', 'Hillsboro', 'Oregon',97123,5036286733, 'laura.rodgers@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (119, 'Margaret' ,'Powers','1991-01-02', '4935 Catherine Drive', 'East Grand Forks', 'North Dakota',56721,7013179341, 'margaret.powers@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (120, 'Amy' ,'Phelps','1991-01-15', '364 Bingamon Branch Road', 'Sullivan', 'Wisconsin',53178,8472445848, 'amy.phelps@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (121, 'Veronica' ,'Dawson','1991-12-10', '921 Marie Street', 'Annapolis', 'Maryland',21401,4108587688, 'veronica.dawson@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (122, 'Amanda' ,'Lucero','1992-12-06', '2951 Olen Thomas Drive', 'Wichita Falls', 'Texas',76301,9405576186, 'amanda.lucero@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (123, 'Tonya' ,'Miller','1994-07-03', '1311 Rafe Lane', 'Greenwood', 'Mississippi',38930,6627142782, 'tonya.miller@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (124, 'Karen' ,'Maynard','1999-02-18', '599 Lilac Lane', 'Darien', 'Georgia',31305,9124377159, 'karen.maynard@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (125, 'Alyssa' ,'Miranda','1999-04-01', '3128 Tori Lane', 'Greenview', 'Illinois',62642,8016455363, 'alyssa.miranda@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (126, 'Jennifer' ,'Harrington','1964-03-08', '41 Spadafore Drive', 'State College', 'Pennsylvania',16801,8147150156, 'jennifer.harrington@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (127, 'Stacy' ,'White','1968-10-26', '3915 Rhapsody Street', 'Inverness', 'Florida',32650,3523446389, 'stacy.white@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (128, 'Amanda' ,'Le','1984-06-17', '1271 Summit Park Avenue', 'Southfield', 'Michigan',48034,2489482017, 'amanda.le@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (129, 'Tracy' ,'Peterson','1988-02-08', '4976 McKinley Avenue', 'Denver', 'Colorado',80202,3038072071, 'tracy.peterson@gmail.com');
insert into Patient(PatID, FirstName, LastName, DoB, Street, City, State, ZipCode, PhoneNo, EmailAddress) values (130, 'Amy' ,'Martin','1992-11-16', '2078 Red Dog Road', 'Charlotte', 'North Carolina',28202,7043395859, 'amy.martin@gmail.com');



-----------------------------PatientDemographics-----------------


insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (101, 'M','Other', 'Non Hispanic', 'Unavailable', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (102, 'M','Other', 'Unavailable', 'Married', 'Retired');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (103, 'M','Black', 'Hispanic', 'Single', 'Unavailable');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (104, 'M','Black', 'Hispanic', 'Single', 'Unavailable');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (105, 'M','Asian', 'Unavailable', 'Married', 'Employed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (106, 'M','White', 'Non Hispanic', 'Single', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (107, 'M','Black', 'Hispanic', 'Unavailable', 'Retired');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (108, 'M','Unavailable', 'Hispanic', 'Unavailable', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (109, 'M','White', 'Non Hispanic', 'Divorced', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (110, 'M','Unavailable', 'Non Hispanic', 'Unavailable', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (111, 'M','White', 'Hispanic', 'Single', 'Employed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (112, 'M','Unavailable', 'Hispanic', 'Married', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (113, 'M','Asian', 'Hispanic', 'Married', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (114, 'M','Asian', 'Non Hispanic', 'Single', 'Unavailable');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (115, 'M','Unavailable', 'Unavailable', 'Single', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (116, 'F','Asian', 'Non Hispanic', 'Single', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (117, 'F','Unavailable', 'Unavailable', 'Single', 'Employed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (118, 'F','White', 'Hispanic', 'Single', 'Unavailable');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (119, 'F','Asian', 'Unavailable', 'Single', 'Retired');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (120, 'F','White', 'Non Hispanic', 'Unavailable', 'Employed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (121, 'F','Asian', 'Hispanic', 'Divorced', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (122, 'F','Black', 'Unavailable', 'Single', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (123, 'F','Asian', 'Non Hispanic', 'Single', 'Retired');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (124, 'F','Other', 'Non Hispanic', 'Unavailable', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (125, 'F','Black', 'Non Hispanic', 'Unavailable', 'Retired');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (126, 'F','Asian', 'Unavailable', 'Divorced', 'Employed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (127, 'F','Unavailable', 'Non Hispanic', 'Divorced', 'Employed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (128, 'F','White', 'Hispanic', 'Married', 'Retired');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (129, 'F','Asian', 'Unavailable', 'Married', 'Unemployed');
insert into PatientDemographics(PatID, Gender, Race, Ethnicity, MaritalStatus, EmploymentStatus) values (130, 'F','Unavailable', 'Non Hispanic', 'Divorced', 'Unemployed');


-------------------------EPOC-------------------------

insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (1,101, 'Anthony' ,'Mendoza',3607027103);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (2,102, 'Colleen' ,'Reed',3346093248);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (3,103, 'Bobbie' ,'Harper',6463538347);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (4,104, 'Bernard' ,'Mccormick',4127741666);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (5,105, 'Alonzo' ,'Allen',4805511804);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (6,106, 'Emilio' ,'Klein',2675371407);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (7,107, 'Toni' ,'Collins',5592178932);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (8,108, 'Arlene' ,'Bridges',7725386959);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (9,109, 'Rufus' ,'Russell',3473391104);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (10,110, 'Salvador' ,'Barnett',3402205144);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (11,111, 'Tracy' ,'Mullins',2814701730);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (12,112, 'Glen' ,'Ruiz',7753539431);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (13,113, 'Conrad' ,'Patrick',6083474141);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (14,114, 'Georgia' ,'Hunter',4195306136);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (15,115, 'Brendan' ,'Daniel',2139638469);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (16,116, 'Tricia' ,'Vaughn',2066024801);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (17,117, 'Christian' ,'Armstrong',4432104071);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (18,118, 'Casey' ,'Huff',5673514078);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (19,119, 'Luz' ,'Moss',2603571958);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (20,120, 'Alexis' ,'Rivera',4082447244);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (21,121, 'June' ,'Herrera',4108587688);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (22,122, 'Marilyn' ,'Reyes',9405576186);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (23,123, 'Penny' ,'Harrison',6627142782);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (24,124, 'Kyle' ,'Sims',9124377159);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (25,125, 'Elvira' ,'Howard',8016455363);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (26,126, 'Jeannie' ,'Morrison',8147150156);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (27,127, 'Jo' ,'Boyd',3523446389);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (28,128, 'Barbara' ,'Walsh',2489482017);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (29,129, 'Tony' ,'Silva',3038072071);
insert into EPOC (EPOCID,PatID, EPOCFirstName, EPOCLastName, EPOCPhoneNo) values (30,130, 'Jose' ,'Richards',7043395859);

------------------------------------Vaccination--------------------------



insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1001, 101, 'Vaccinated', 3, 'Covid-19', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1002, 101, 'Vaccinated', 1, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1003, 101, 'Unvaccinated', 0, 'Pneumonia', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1004, 102, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1005, 102, 'Vaccinated', 2, 'Influenza', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1006, 103, 'Unvaccinated', 0, 'Covid-19', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1007, 103, 'Vaccinated', 1, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1008, 103, 'Vaccinated', 1, 'Pneumonia', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1009, 104, 'Vaccinated', 2, 'Covid-19', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1010, 104, 'Vaccinated', 3, 'HepB', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1011, 106, 'Vaccinated', 2, 'Influenza', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1012, 106, 'Vaccinated', 1, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1013, 107, 'Unvaccinated', 0, 'Covid-19', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1014, 107, 'Vaccinated', 3, 'HepB', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1015, 107, 'Vaccinated', 2, 'Pneumonia', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1016, 108, 'Vaccinated', 3, 'Meningococcal', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1017, 109, 'Unvaccinated', 0, 'Covid-19', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1018, 110, 'Unvaccinated', 0, 'Meningococcal', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1019, 110, 'Vaccinated', 2, 'Pneumonia', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1020, 110, 'Unvaccinated', 0, 'Covid-19', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1021, 111, 'Unvaccinated', 0, 'Covid-19', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1022, 112, 'Vaccinated', 2, 'Covid-19', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1023, 112, 'Vaccinated', 2, 'Pneumonia', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1024, 112, 'Vaccinated', 3, 'HepB', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1025, 113, 'Unvaccinated', 0, 'HepB', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1026, 114, 'Vaccinated', 1, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1027, 115, 'Vaccinated', 1, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1028, 116, 'Unvaccinated', 0, 'HepB', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1029, 116, 'Unvaccinated', 0, 'Covid-19', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1030, 117, 'Vaccinated', 2, 'Pneumonia', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1031, 117, 'Vaccinated', 1, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1032, 118, 'Vaccinated', 2, 'Covid-19', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1033, 118, 'Vaccinated', 0, 'HepB', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1034, 119, 'Unvaccinated', 0, 'Covid-19', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1035, 120, 'Vaccinated', 3, 'Covid-19', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1036, 120, 'Vaccinated', 1, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1037, 120, 'Vaccinated', 1, 'Meningococcal', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1038, 121, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1039, 121, 'Unvaccinated', 0, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1040, 122, 'Vaccinated', 3, 'Covid-19', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1041, 122, 'Vaccinated', 1, 'Meningococcal', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1042, 122, 'Vaccinated', 1, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1043, 122, 'Vaccinated', 2, 'Pneumonia', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1044, 122, 'Vaccinated', 3, 'HepB', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1045, 123, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1046, 123, 'Unvaccinated', 0, 'Meningococcal', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1047, 123, 'Vaccinated', 1, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1048, 124, 'Vaccinated', 1, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1049, 124, 'Vaccinated', 1, 'Pneumonia', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1050, 124, 'Vaccinated', 3, 'HepB', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1051, 125, 'Vaccinated', 2, 'Pneumonia', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1052, 125, 'Vaccinated', 3, 'HepB', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1053, 125, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1054, 126, 'Vaccinated', 1, 'Meningococcal', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1055, 126, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1056, 126, 'Unvaccinated', 0, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1057, 127, 'Vaccinated', 1, 'Meningococcal', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1058, 127, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1059, 127, 'Vaccinated', 0, 'Influenza', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1060, 128, 'Vaccinated', 2, 'Pneumonia', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1061, 128, 'Vaccinated', 3, 'HepB', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1062, 128, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1063, 129, 'Unvaccinated', 0, 'Meningococcal', 'NULL');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1064, 129, 'Vaccinated', 2, 'Pneumonia', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1065, 129, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1066, 130, 'Vaccinated', 2, 'Influenza', 'Y');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1067, 130, 'Vaccinated', 2, 'Covid-19', 'N');
insert into Vaccination(LotNo, PatID, VaccinationStatus, NoOfDoses, VaccineName, BoosterStatus) values (1068, 130, 'Vaccinated', 2, 'Pneumonia', 'Y');


--------------------------InsuranceProvider-------------------------


insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10001,101, 'Blue Cross Blue Shield');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10002,102, 'CIGNA');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10003,103, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10004,104, 'Blue Cross Blue Shield');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10005,105, 'United Health');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10006,106, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10007,107, 'United Health');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10008,108, 'Blue Cross Blue Shield');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10009,109, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10010,110, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10011,111, 'CIGNA');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10012,112, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10013,113, 'Blue Cross Blue Shield');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10014,114, 'Blue Cross Blue Shield');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10015,115, 'Blue Cross Blue Shield');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10016,116, 'Blue Cross Blue Shield');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10017,117, 'CIGNA');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10018,118, 'United Health');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10019,119, 'CIGNA');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10020,120, 'CIGNA');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10021,121, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10022,122, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10023,123, 'United Health');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10024,124, 'United Health');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10025,125, 'CIGNA');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10026,126, 'United Health');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10027,127, 'Blue Cross Blue Shield');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10028,128, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10029,129, 'CVS');
insert into InsuranceProvider (InsuranceID,PatID, InsuranceProviderName) values (10030,130, 'CVS');




--------------------------HealthcareProvider----------------------


insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3215, 'Hospital pharmacist', 'Beatrice', 'Reid', 6464997392);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3216, 'Attending physician', 'Ora', 'Walters', 6615071463);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3217, 'Radiologist', 'Sonja', 'Reeves', 7622186962);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3218, 'Chief Medical Officer', 'Olive', 'Briggs', 5635783510);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3219, 'Social worker', 'Jacob', 'Warren', 5304923382);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3220, 'Surgeon', 'Miriam', 'Carson', 6463937961);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3221, 'Internal Medicine', 'Steven', 'Murphy', 2512336069);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3222, 'Oncologist', 'Loren', 'Carter', 2159693239);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3223, 'Social worker', 'Alonzo', 'Chambers', 5166337818);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3224, 'Pathologist', 'Tiffany', 'Jimenez', 5177433142);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3225, 'Cardiologist', 'Cheryl', 'Barber', 3094655777);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3226, 'Hospital pharmacist', 'Sally', 'Jones', 5128129786);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3227, 'Physical therapist', 'Norma', 'Holmes', 4145907344);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3228, 'Emergency physician', 'Freda', 'Shaw', 4056339180);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3229, 'Neurologist', 'Charles', 'Dean', 5169928384);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3230, 'Internal Medicine', 'Travis', 'Powers', 5615754961);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3231, 'Surgeon', 'Robyn', 'Mcgee', 4782185613);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3232, 'Internal Medicine', 'Barry', 'Bates', 4356365213);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3233, 'Pulmonologist', 'Stephen', 'Marshall', 2696862425);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3234, 'Neurologist', 'Cora', 'James', 6083778239);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3235, 'Attending physician', 'Ricky', 'Williams', 4099166239);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3236, 'Cardiologist', 'Katrina', 'Payne', 5087166020);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3237, 'Resident Doctor', 'Mandy', 'Ford', 2538916760);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3238, 'Clinical Assitant', 'Saul', 'Mckenzie', 6262027774);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3239, 'Attending physician', 'Henry', 'Wilson', 4046504772);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3240, 'Anesthesiologist', 'Marilyn', 'Walker', 8436486753);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3241, 'Physical therapist', 'Olivia', 'Gibbs', 7757536245);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3242, 'Clinical Assitant', 'Herman', 'Rice', 5176174509);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3243, 'Oncologist', 'Lynda', 'Turner', 3196351163);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3244, 'Cardiologist', 'Cary', 'Thornton', 3235289071);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3245, 'Hospital pharmacist', 'Glen', 'Miles', 6502379573);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3246, 'Pathologist', 'Jimmie', 'Davidson', 3392004325);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3247, 'Oncologist', 'Eunice', 'Santiago', 4242718458);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3248, 'Cardiologist', 'Penny', 'Johnson', 3084142562);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3249, 'Psychiatrist', 'Isabel', 'Peters', 6037804371);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3250, 'Internal Medicine', 'Adrian', 'Dunn', 5027172040);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3251, 'Resident Doctor', 'Annette', 'Blair', 6672134553);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3252, 'Neurologist', 'Joseph', 'Ellis', 2097048736);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3253, 'Resident Doctor', 'Janis', 'Alvarado', 6143088930);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3254, 'Chief executive officer', 'Marty', 'Freeman', 7572162112);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3255, 'Social worker', 'Leon', 'Hopkins', 2145385925);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3256, 'Pathologist', 'Ken', 'Rodriquez', 3312622458);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3257, 'Surgeon', 'Jill', 'Anderson', 2133092734);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3258, 'Physical therapist', 'Mercedes', 'Doyle', 2314977093);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3259, 'Ophthalmologist', 'Carolyn', 'Gonzales', 2085226456);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3260, 'Emergency physician', 'Benny', 'Lewis', 3128994232);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3261, 'Neurologist', 'Mario', 'Maxwell', 4235254938);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3262, 'Surgeon', 'Lydia', 'Greer', 5126143618);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3263, 'Emergency physician', 'Wanda', 'Lopez', 4702078477);
insert into HealthCareProvider(HealthCareProviderID, Designation, EmpFirstName, EmpLastName, EmpContactNo) values (3264, 'Cardiologist', 'Jimmy', 'Fields', 4235963194);

------------------ PatientEncounter--------------


insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20001, 115, 3253, '2020-01-05', 'Emergency', 'Neurology', '2020-01-12', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20002, 121, 3251, '2020-01-20', 'Emergency', 'Oncology', '2020-01-30', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20003, 124, 3253, '2020-01-23', 'Elective', 'Haematology', '2020-02-02', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20004, 101, 3216, '2020-02-05', 'Emergency', 'Urology', '2020-02-19', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20005, 113, 3251, '2020-02-08', 'Urgent', 'Urology', '2020-02-23', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20006, 109, 3216, '2020-02-11', 'Emergency', 'Coronary Care Unit (CCU)', '2020-02-25', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20007, 130, 3237, '2020-02-23', 'Elective', 'Orthopaedics', '2020-03-05', 'Nephrology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20008, 101, 3239, '2020-02-23', 'Emergency', 'General Surgery', '2020-02-27', 'Haematology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20009, 127, 3228, '2020-02-26', 'Emergency', 'Critical Care', '2020-03-02', 'Radiology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20010, 109, 3257, '2020-03-10', 'Emergency', 'General Surgery', '2020-03-19', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20011, 105, 3260, '2020-03-11', 'Urgent', 'General Surgery', '2020-03-12', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20012, 120, 3257, '2020-03-11', 'Emergency', 'Nephrology', '2020-03-15', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20013, 129, 3263, '2020-03-13', 'Emergency', 'Intensive Care Unit (ICU)', '2020-03-28', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20014, 114, 3262, '2020-03-17', 'Elective', 'Coronary Care Unit (CCU)', '2020-03-30', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20015, 116, 3237, '2020-04-07', 'Urgent', 'Radiology', '2020-04-10', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20016, 128, 3239, '2020-04-10', 'Emergency', 'Nephrology', '2020-04-24', 'Discharge Lounge');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20017, 115, 3253, '2020-04-20', 'Emergency', 'Oncology', '2020-04-21', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20018, 115, 3228, '2020-04-20', 'Elective', 'Intensive Care Unit (ICU)', '2020-04-25', 'Discharge Lounge');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20019, 130, 3237, '2020-04-21', 'Emergency', 'Intensive Care Unit (ICU)', '2020-05-01', 'Nephrology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20020, 118, 3263, '2020-05-19', 'Elective', 'General Surgery', '2020-05-24', 'Intensive Care Unit (ICU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20021, 130, 3231, '2020-05-27', 'Emergency', 'General Surgery', '2020-06-11', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20022, 124, 3235, '2020-07-04', 'Urgent', 'Orthopaedics', '2020-07-05', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20023, 109, 3260, '2020-07-07', 'Elective', 'Orthopaedics', '2020-07-18', 'Coronary Care Unit (CCU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20024, 101, 3235, '2020-07-24', 'Elective', 'Haematology', '2020-07-28', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20025, 116, 3262, '2020-07-28', 'Emergency', 'Oncology', '2020-08-01', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20026, 127, 3220, '2020-07-31', 'Elective', 'Haematology', '2020-08-08', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20027, 120, 3260, '2020-08-06', 'Urgent', 'Urology', '2020-08-08', 'Coronary Care Unit (CCU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20028, 107, 3235, '2020-08-13', 'Elective', 'Oncology', '2020-08-22', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20029, 121, 3231, '2020-09-03', 'Emergency', 'General Surgery', '2020-09-04', 'Neurology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20030, 130, 3239, '2020-09-04', 'Elective', 'General Surgery', '2020-09-06', 'Neurology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20031, 127, 3231, '2020-09-23', 'Urgent', 'Coronary Care Unit (CCU)', '2020-10-06', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20032, 102, 3257, '2020-09-25', 'Urgent', 'Coronary Care Unit (CCU)', '2020-10-08', 'Radiology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20033, 127, 3260, '2020-10-24', 'Urgent', 'Oncology', '2020-11-08', 'Neurology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20034, 126, 3237, '2020-10-25', 'Emergency', 'Coronary Care Unit (CCU)', '2020-11-07', 'Nephrology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20035, 113, 3220, '2020-10-31', 'Elective', 'Intensive Care Unit (ICU)', '2020-11-04', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20036, 112, 3228, '2020-11-14', 'Elective', 'Intensive Care Unit (ICU)', '2020-11-23', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20037, 125, 3239, '2020-11-15', 'Elective', 'Critical Care', '2020-11-26', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20038, 129, 3235, '2020-11-16', 'Elective', 'Critical Care', '2020-11-22', 'Discharge Lounge');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20039, 103, 3228, '2020-11-19', 'Urgent', 'Haematology', '2020-11-29', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20040, 116, 3237, '2020-12-07', 'Emergency', 'Neurology', '2020-12-10', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20041, 130, 3228, '2020-12-07', 'Emergency', 'General Surgery', '2020-12-18', 'Discharge Lounge');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20042, 117, 3231, '2020-12-18', 'Urgent', 'Coronary Care Unit (CCU)', '2020-12-19', 'Haematology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20043, 118, 3263, '2020-12-19', 'Elective', 'Orthopaedics', '2020-12-28', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20044, 113, 3263, '2020-12-21', 'Urgent', 'General Surgery', '2021-01-01', 'Intensive Care Unit (ICU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20045, 130, 3257, '2020-12-26', 'Emergency', 'Intensive Care Unit (ICU)', '2021-01-03', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20046, 119, 3237, '2021-01-01', 'Urgent', 'Haematology', '2021-01-05', 'Haematology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20047, 119, 3257, '2021-01-03', 'Elective', 'Nephrology', '2021-01-18', 'Discharge Lounge');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20048, 108, 3231, '2021-01-04', 'Emergency', 'Radiology', '2021-01-08', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20049, 106, 3237, '2021-01-10', 'Urgent', 'Haematology', '2021-01-14', 'Haematology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20050, 122, 3237, '2021-01-22', 'Elective', 'General Surgery', '2021-01-28', 'Discharge Lounge');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20051, 102, 3257, '2021-01-23', 'Elective', 'Oncology', '2021-01-27', 'Intensive Care Unit (ICU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20052, 118, 3231, '2021-01-27', 'Elective', 'Oncology', '2021-02-07', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20053, 124, 3220, '2021-02-24', 'Elective', 'Oncology', '2021-02-27', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20054, 123, 3237, '2021-02-28', 'Elective', 'Orthopaedics', '2021-03-10', 'Haematology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20055, 108, 3228, '2021-03-29', 'Urgent', 'General Surgery', '2021-04-12', 'Nephrology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20056, 130, 3237, '2021-03-30', 'Emergency', 'Coronary Care Unit (CCU)', '2021-04-10', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20057, 117, 3251, '2021-04-07', 'Urgent', 'Intensive Care Unit (ICU)', '2021-04-14', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20058, 112, 3216, '2021-04-30', 'Urgent', 'Oncology', '2021-05-11', 'Nephrology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20059, 116, 3216, '2021-05-10', 'Emergency', 'Urology', '2021-05-24', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20060, 130, 3239, '2021-05-14', 'Emergency', 'Neurology', '2021-05-19', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20061, 113, 3251, '2021-05-17', 'Elective', 'Haematology', '2021-05-31', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20062, 116, 3251, '2021-05-23', 'Elective', 'Radiology', '2021-05-25', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20063, 115, 3216, '2021-05-26', 'Urgent', 'Urology', '2021-05-29', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20064, 106, 3228, '2021-06-02', 'Urgent', 'Nephrology', '2021-06-04', 'Intensive Care Unit (ICU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20065, 106, 3251, '2021-06-09', 'Elective', 'Radiology', '2021-06-20', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20066, 126, 3257, '2021-06-18', 'Urgent', 'Urology', '2021-06-30', 'Radiology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20067, 122, 3260, '2021-06-20', 'Elective', 'Intensive Care Unit (ICU)', '2021-06-25', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20068, 115, 3228, '2021-06-23', 'Urgent', 'Urology', '2021-07-04', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20069, 101, 3239, '2021-07-12', 'Urgent', 'Coronary Care Unit (CCU)', '2021-07-23', 'Radiology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20070, 129, 3253, '2021-07-25', 'Elective', 'Radiology', '2021-08-09', 'Haematology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20071, 113, 3235, '2021-08-01', 'Emergency', 'Orthopaedics', '2021-08-06', 'Coronary Care Unit (CCU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20072, 111, 3260, '2021-08-06', 'Urgent', 'Radiology', '2021-08-20', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20073, 129, 3220, '2021-08-12', 'Emergency', 'Intensive Care Unit (ICU)', '2021-08-20', 'Haematology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20074, 108, 3253, '2021-08-16', 'Elective', 'Radiology', '2021-08-26', 'Discharge Lounge');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20075, 101, 3251, '2021-09-09', 'Emergency', 'Nephrology', '2021-09-24', 'Intensive Care Unit (ICU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20076, 102, 3263, '2021-09-19', 'Urgent', 'Coronary Care Unit (CCU)', '2021-09-27', 'Coronary Care Unit (CCU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20077, 123, 3263, '2021-09-21', 'Elective', 'Orthopaedics', '2021-10-03', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20078, 122, 3239, '2021-10-15', 'Elective', 'Urology', '2021-10-16', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20079, 120, 3251, '2021-10-16', 'Urgent', 'Neurology', '2021-10-27', 'Nephrology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20080, 120, 3263, '2021-10-16', 'Elective', 'Neurology', '2021-10-20', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20081, 118, 3260, '2021-10-28', 'Elective', 'Radiology', '2021-11-03', 'Radiology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20082, 128, 3239, '2021-10-29', 'Emergency', 'Intensive Care Unit (ICU)', '2021-11-13', 'Nephrology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20083, 121, 3260, '2021-11-06', 'Elective', 'Urology', '2021-11-07', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20084, 110, 3231, '2021-11-10', 'Elective', 'General Surgery', '2021-11-15', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20085, 118, 3216, '2021-11-14', 'Emergency', 'Oncology', '2021-11-28', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20086, 106, 3228, '2021-11-25', 'Emergency', 'Intensive Care Unit (ICU)', '2021-11-29', 'Haematology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20087, 127, 3239, '2021-12-27', 'Emergency', 'Radiology', '2022-01-02', 'Radiology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20088, 125, 3235, '2021-12-28', 'Elective', 'Oncology', '2021-12-30', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20089, 107, 3260, '2022-01-08', 'Emergency', 'Orthopaedics', '2022-01-22', 'Critical Care');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20090, 102, 3257, '2022-01-15', 'Emergency', 'Haematology', '2022-01-18', 'Urology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20091, 119, 3263, '2022-01-15', 'Elective', 'Radiology', '2022-01-25', 'Intensive Care Unit (ICU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20092, 109, 3262, '2022-01-18', 'Emergency', 'Oncology', '2022-01-24', 'Orthopaedics');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20093, 115, 3235, '2022-01-23', 'Urgent', 'Intensive Care Unit (ICU)', '2022-02-01', 'Oncology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20094, 123, 3228, '2022-01-25', 'Elective', 'Urology', '2022-02-03', 'Nephrology');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20095, 103, 3239, '2022-02-16', 'Emergency', 'Urology', '2022-02-21', 'Intensive Care Unit (ICU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20096, 105, 3235, '2022-02-20', 'Emergency', 'Nephrology', '2022-02-23', 'General Surgery');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20097, 123, 3260, '2022-02-21', 'Urgent', 'Oncology', '2022-02-24', 'Coronary Care Unit (CCU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20098, 109, 3239, '2022-02-25', 'Elective', 'Haematology', '2022-03-10', 'Coronary Care Unit (CCU)');
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20099, 124, 3216, '2022-03-17', 'Elective', 'Critical Care', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20100, 118, 3257, '2022-03-17', 'Elective', 'General Surgery', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20101, 102, 3257, '2022-03-17', 'Emergency', 'Haematology', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20102, 109, 3262, '2022-03-17', 'Emergency', 'Oncology', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20103, 101, 3251, '2022-03-18', 'Emergency', 'Nephrology', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20104, 120, 3257, '2022-03-19', 'Emergency', 'Nephrology', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20105, 129, 3263, '2022-03-25', 'Emergency', 'Intensive Care Unit (ICU)', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20106, 114, 3262, '2022-04-02', 'Elective', 'Coronary Care Unit (CCU)', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20107, 116, 3237, '2022-04-04', 'Urgent', 'Radiology', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20108, 128, 3239, '2022-04-05', 'Emergency', 'Nephrology', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20109, 115, 3253, '2022-04-06', 'Emergency', 'Oncology', NULL, NULL);
insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20110, 130, 3237, '2022-04-07', 'Emergency', 'Intensive Care Unit (ICU)', NULL, NULL);




----- SymptomDetails---


insert into SymptomDetails(SymCode, SymName) values (0, 'N/A');
insert into SymptomDetails(SymCode, SymName) values (10, 'Abdominal pain');
insert into SymptomDetails(SymCode, SymName) values (11, 'Chest Pain');
insert into SymptomDetails(SymCode, SymName) values (12, 'Stomach Flu');
insert into SymptomDetails(SymCode, SymName) values (13, 'Weight loss');
insert into SymptomDetails(SymCode, SymName) values (14, 'Fever');
insert into SymptomDetails(SymCode, SymName) values (15, 'Fatigue');
insert into SymptomDetails(SymCode, SymName) values (16, 'Nausea');
insert into SymptomDetails(SymCode, SymName) values (17, 'Jaundice');
insert into SymptomDetails(SymCode, SymName) values (18, 'Anxiety');
insert into SymptomDetails(SymCode, SymName) values (19, 'Bad cough');
insert into SymptomDetails(SymCode, SymName) values (20, 'Vomiting');
insert into SymptomDetails(SymCode, SymName) values (21, 'Internal Bleeding');
insert into SymptomDetails(SymCode, SymName) values (22, 'Skin Infection');
insert into SymptomDetails(SymCode, SymName) values (23, 'Anal Pain');
insert into SymptomDetails(SymCode, SymName) values (24, 'Back Pain');
insert into SymptomDetails(SymCode, SymName) values (25, 'Blood Clots');
insert into SymptomDetails(SymCode, SymName) values (26, 'Epiphora');
insert into SymptomDetails(SymCode, SymName) values (27, 'Painful Urination');
insert into SymptomDetails(SymCode, SymName) values (28, 'Hyperhidrosis');
insert into SymptomDetails(SymCode, SymName) values (29, 'Blurry Vision');
insert into SymptomDetails(SymCode, SymName) values (30, 'Joint Pain');
insert into SymptomDetails(SymCode, SymName) values (31, 'Shortness in breath');
insert into SymptomDetails(SymCode, SymName) values (32, 'Headache');
insert into SymptomDetails(SymCode, SymName) values (33, 'Disorientation');



---------------Symptoms-----------------

insert into Symptoms( PatEncID, SymCode, Duration) values (20001, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20002, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20003, 33, 25);
insert into Symptoms( PatEncID, SymCode, Duration) values (20003, 25, 42);
insert into Symptoms( PatEncID, SymCode, Duration) values (20004, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20005, 10, 15);
insert into Symptoms( PatEncID, SymCode, Duration) values (20005, 27, 47);
insert into Symptoms( PatEncID, SymCode, Duration) values (20006, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20007, 13, 23);
insert into Symptoms( PatEncID, SymCode, Duration) values (20007, 18, 38);
insert into Symptoms( PatEncID, SymCode, Duration) values (20007, 33, 28);
insert into Symptoms( PatEncID, SymCode, Duration) values (20008, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20009, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20010, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20011, 15, 30);
insert into Symptoms( PatEncID, SymCode, Duration) values (20012, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20013, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20014, 13, 4);
insert into Symptoms( PatEncID, SymCode, Duration) values (20014, 14, 39);
insert into Symptoms( PatEncID, SymCode, Duration) values (20015, 24, 14);
insert into Symptoms( PatEncID, SymCode, Duration) values (20016, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20017, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20018, 33, 19);
insert into Symptoms( PatEncID, SymCode, Duration) values (20019, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20020, 17, 15);
insert into Symptoms( PatEncID, SymCode, Duration) values (20021, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20022, 19, 27);
insert into Symptoms( PatEncID, SymCode, Duration) values (20023, 10, 18);
insert into Symptoms( PatEncID, SymCode, Duration) values (20023, 28, 29);
insert into Symptoms( PatEncID, SymCode, Duration) values (20023, 18, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20023, 16, 5);
insert into Symptoms( PatEncID, SymCode, Duration) values (20024, 29, 34);
insert into Symptoms( PatEncID, SymCode, Duration) values (20024, 17, 23);
insert into Symptoms( PatEncID, SymCode, Duration) values (20025, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20026, 18, 30);
insert into Symptoms( PatEncID, SymCode, Duration) values (20026, 20, 4);
insert into Symptoms( PatEncID, SymCode, Duration) values (20027, 29, 20);
insert into Symptoms( PatEncID, SymCode, Duration) values (20027, 14, 15);
insert into Symptoms( PatEncID, SymCode, Duration) values (20028, 23, 40);
insert into Symptoms( PatEncID, SymCode, Duration) values (20028, 12, 29);
insert into Symptoms( PatEncID, SymCode, Duration) values (20029, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20030, 27, 25);
insert into Symptoms( PatEncID, SymCode, Duration) values (20030, 23, 36);
insert into Symptoms( PatEncID, SymCode, Duration) values (20030, 11, 35);
insert into Symptoms( PatEncID, SymCode, Duration) values (20031, 25, 21);
insert into Symptoms( PatEncID, SymCode, Duration) values (20031, 33, 40);
insert into Symptoms( PatEncID, SymCode, Duration) values (20032, 18, 10);
insert into Symptoms( PatEncID, SymCode, Duration) values (20032, 13, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20033, 29, 24);
insert into Symptoms( PatEncID, SymCode, Duration) values (20034, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20035, 19, 12);
insert into Symptoms( PatEncID, SymCode, Duration) values (20035, 18, 4);
insert into Symptoms( PatEncID, SymCode, Duration) values (20035, 21, 37);
insert into Symptoms( PatEncID, SymCode, Duration) values (20036, 33, 13);
insert into Symptoms( PatEncID, SymCode, Duration) values (20037, 17, 24);
insert into Symptoms( PatEncID, SymCode, Duration) values (20038, 26, 41);
insert into Symptoms( PatEncID, SymCode, Duration) values (20039, 13, 18);
insert into Symptoms( PatEncID, SymCode, Duration) values (20039, 11, 24);
insert into Symptoms( PatEncID, SymCode, Duration) values (20040, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20041, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20042, 26, 19);
insert into Symptoms( PatEncID, SymCode, Duration) values (20043, 26, 23);
insert into Symptoms( PatEncID, SymCode, Duration) values (20043, 15, 18);
insert into Symptoms( PatEncID, SymCode, Duration) values (20044, 32, 17);
insert into Symptoms( PatEncID, SymCode, Duration) values (20045, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20046, 29, 37);
insert into Symptoms( PatEncID, SymCode, Duration) values (20046, 32, 4);
insert into Symptoms( PatEncID, SymCode, Duration) values (20046, 12, 45);
insert into Symptoms( PatEncID, SymCode, Duration) values (20047, 32, 36);
insert into Symptoms( PatEncID, SymCode, Duration) values (20047, 33, 41);
insert into Symptoms( PatEncID, SymCode, Duration) values (20047, 29, 47);
insert into Symptoms( PatEncID, SymCode, Duration) values (20048, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20049, 14, 43);
insert into Symptoms( PatEncID, SymCode, Duration) values (20049, 30, 38);
insert into Symptoms( PatEncID, SymCode, Duration) values (20049, 32, 43);
insert into Symptoms( PatEncID, SymCode, Duration) values (20050, 32, 46);
insert into Symptoms( PatEncID, SymCode, Duration) values (20050, 26, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20050, 17, 31);
insert into Symptoms( PatEncID, SymCode, Duration) values (20051, 14, 41);
insert into Symptoms( PatEncID, SymCode, Duration) values (20051, 12, 8);
insert into Symptoms( PatEncID, SymCode, Duration) values (20052, 15, 42);
insert into Symptoms( PatEncID, SymCode, Duration) values (20052, 21, 33);
insert into Symptoms( PatEncID, SymCode, Duration) values (20053, 25, 33);
insert into Symptoms( PatEncID, SymCode, Duration) values (20053, 26, 38);
insert into Symptoms( PatEncID, SymCode, Duration) values (20053, 24, 47);
insert into Symptoms( PatEncID, SymCode, Duration) values (20054, 13, 34);
insert into Symptoms( PatEncID, SymCode, Duration) values (20055, 13, 32);
insert into Symptoms( PatEncID, SymCode, Duration) values (20056, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20057, 29, 39);
insert into Symptoms( PatEncID, SymCode, Duration) values (20058, 12, 23);
insert into Symptoms( PatEncID, SymCode, Duration) values (20058, 21, 16);
insert into Symptoms( PatEncID, SymCode, Duration) values (20058, 32, 16);
insert into Symptoms( PatEncID, SymCode, Duration) values (20058, 24, 20);
insert into Symptoms( PatEncID, SymCode, Duration) values (20059, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20060, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20061, 14, 41);
insert into Symptoms( PatEncID, SymCode, Duration) values (20061, 12, 21);
insert into Symptoms( PatEncID, SymCode, Duration) values (20061, 29, 12);
insert into Symptoms( PatEncID, SymCode, Duration) values (20062, 33, 4);
insert into Symptoms( PatEncID, SymCode, Duration) values (20063, 19, 31);
insert into Symptoms( PatEncID, SymCode, Duration) values (20064, 30, 19);
insert into Symptoms( PatEncID, SymCode, Duration) values (20064, 31, 22);
insert into Symptoms( PatEncID, SymCode, Duration) values (20064, 32, 28);
insert into Symptoms( PatEncID, SymCode, Duration) values (20065, 17, 46);
insert into Symptoms( PatEncID, SymCode, Duration) values (20066, 22, 31);
insert into Symptoms( PatEncID, SymCode, Duration) values (20066, 14, 25);
insert into Symptoms( PatEncID, SymCode, Duration) values (20067, 16, 25);
insert into Symptoms( PatEncID, SymCode, Duration) values (20067, 15, 21);
insert into Symptoms( PatEncID, SymCode, Duration) values (20068, 32, 47);
insert into Symptoms( PatEncID, SymCode, Duration) values (20068, 26, 21);
insert into Symptoms( PatEncID, SymCode, Duration) values (20069, 29, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20069, 22, 47);
insert into Symptoms( PatEncID, SymCode, Duration) values (20069, 31, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20070, 22, 44);
insert into Symptoms( PatEncID, SymCode, Duration) values (20070, 10, 11);
insert into Symptoms( PatEncID, SymCode, Duration) values (20070, 19, 14);
insert into Symptoms( PatEncID, SymCode, Duration) values (20071, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20072, 26, 30);
insert into Symptoms( PatEncID, SymCode, Duration) values (20073, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20074, 22, 8);
insert into Symptoms( PatEncID, SymCode, Duration) values (20074, 18, 21);
insert into Symptoms( PatEncID, SymCode, Duration) values (20074, 30, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20075, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20076, 13, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20077, 33, 8);
insert into Symptoms( PatEncID, SymCode, Duration) values (20077, 16, 46);
insert into Symptoms( PatEncID, SymCode, Duration) values (20078, 27, 5);
insert into Symptoms( PatEncID, SymCode, Duration) values (20078, 31, 17);
insert into Symptoms( PatEncID, SymCode, Duration) values (20078, 10, 9);
insert into Symptoms( PatEncID, SymCode, Duration) values (20079, 32, 31);
insert into Symptoms( PatEncID, SymCode, Duration) values (20079, 12, 28);
insert into Symptoms( PatEncID, SymCode, Duration) values (20080, 14, 8);
insert into Symptoms( PatEncID, SymCode, Duration) values (20080, 30, 16);
insert into Symptoms( PatEncID, SymCode, Duration) values (20081, 29, 23);
insert into Symptoms( PatEncID, SymCode, Duration) values (20081, 27, 17);
insert into Symptoms( PatEncID, SymCode, Duration) values (20082, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20083, 19, 4);
insert into Symptoms( PatEncID, SymCode, Duration) values (20083, 20, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20083, 21, 26);
insert into Symptoms( PatEncID, SymCode, Duration) values (20084, 33, 29);
insert into Symptoms( PatEncID, SymCode, Duration) values (20085, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20086, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20087, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20088, 33, 28);
insert into Symptoms( PatEncID, SymCode, Duration) values (20089, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20090, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20091, 27, 34);
insert into Symptoms( PatEncID, SymCode, Duration) values (20091, 26, 31);
insert into Symptoms( PatEncID, SymCode, Duration) values (20091, 19, 14);
insert into Symptoms( PatEncID, SymCode, Duration) values (20091, 14, 22);
insert into Symptoms( PatEncID, SymCode, Duration) values (20092, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20093, 25, 5);
insert into Symptoms( PatEncID, SymCode, Duration) values (20094, 21, 41);
insert into Symptoms( PatEncID, SymCode, Duration) values (20095, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20096, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20097, 32, 6);
insert into Symptoms( PatEncID, SymCode, Duration) values (20098, 30, 12);
insert into Symptoms( PatEncID, SymCode, Duration) values (20098, 10, 38);
insert into Symptoms( PatEncID, SymCode, Duration) values (20099, 22, 16);
insert into Symptoms( PatEncID, SymCode, Duration) values (20100, 33, 44);
insert into Symptoms( PatEncID, SymCode, Duration) values (20100, 32, 42);
insert into Symptoms( PatEncID, SymCode, Duration) values (20101, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20102, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20103, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20104, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20105, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20106, 23, 15);
insert into Symptoms( PatEncID, SymCode, Duration) values (20107, 23, 33);
insert into Symptoms( PatEncID, SymCode, Duration) values (20107, 15, 40);
insert into Symptoms( PatEncID, SymCode, Duration) values (20108, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20109, 0, 0);
insert into Symptoms( PatEncID, SymCode, Duration) values (20110, 0, 0);


--------------------DiagnosisDetails------------------------------
insert into DiagnosisDetails(DxCode, DxName) values (45, 'Congestive heart failure (CHF)');
insert into DiagnosisDetails(DxCode, DxName) values (46, 'Acute myocardial infarction');
insert into DiagnosisDetails(DxCode, DxName) values (47, 'Cardiac dysrhythmia');
insert into DiagnosisDetails(DxCode, DxName) values (48, 'Lumbago');
insert into DiagnosisDetails(DxCode, DxName) values (49, 'Chronic obstructive pulmonary disease (COPD)');
insert into DiagnosisDetails(DxCode, DxName) values (50, 'Atrial fibrillation');
insert into DiagnosisDetails(DxCode, DxName) values (51, 'Diabetes Type I');
insert into DiagnosisDetails(DxCode, DxName) values (52, 'Diabetes Type II');
insert into DiagnosisDetails(DxCode, DxName) values (53, 'Urinary tract infection (UTI)');
insert into DiagnosisDetails(DxCode, DxName) values (54, 'Abdominal infection');
insert into DiagnosisDetails(DxCode, DxName) values (55, 'Osteoarthritis');
insert into DiagnosisDetails(DxCode, DxName) values (56, 'Jaundice');
insert into DiagnosisDetails(DxCode, DxName) values (57, 'Hypertension');
insert into DiagnosisDetails(DxCode, DxName) values (58, 'Surgical Complication');
insert into DiagnosisDetails(DxCode, DxName) values (59, 'Heart failure');
insert into DiagnosisDetails(DxCode, DxName) values (60, 'Acute bronchitis');
insert into DiagnosisDetails(DxCode, DxName) values (61, 'Pneumonia');
insert into DiagnosisDetails(DxCode, DxName) values (62, 'COVID-19');
insert into DiagnosisDetails(DxCode, DxName) values (63, 'Basal cell carcinoma of skin');
insert into DiagnosisDetails(DxCode, DxName) values (64, 'Carcinoma in stomach');
insert into DiagnosisDetails(DxCode, DxName) values (65, 'Carcinoma in eye');
insert into DiagnosisDetails(DxCode, DxName) values (66, 'Cerebral infraction');
insert into DiagnosisDetails(DxCode, DxName) values (67, 'Clostridium difficile (C.Diff)');
insert into DiagnosisDetails(DxCode, DxName) values (68, 'Sepsis');
insert into DiagnosisDetails(DxCode, DxName) values (69, 'Severe sepsis');



----------------Diagnosis------------------------

insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20001, 3222, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20002, 3230, 47);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20003, 3230, 65);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20003, 3222, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20004, 3236, 50);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20005, 3261, 66);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20005, 3253, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20006, 3244, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20007, 3239, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20007, 3231, 67);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20007, 3248, 58);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20008, 3250, 49);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20009, 3261, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20010, 3220, 57);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20011, 3250, 57);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20012, 3216, 58);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20013, 3237, 53);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20014, 3262, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20014, 3234, 47);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20015, 3251, 58);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20016, 3216, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20017, 3248, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20018, 3239, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20019, 3235, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20020, 3237, 54);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20021, 3243, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20022, 3216, 58);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20023, 3229, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20023, 3222, 67);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20023, 3225, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20023, 3228, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20024, 3220, 66);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20024, 3261, 56);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20025, 3225, 59);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20026, 3247, 67);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20026, 3264, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20027, 3233, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20027, 3221, 61);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20028, 3250, 47);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20028, 3250, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20029, 3232, 68);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20030, 3222, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20030, 3248, 51);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20030, 3244, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20031, 3260, 65);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20031, 3237, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20032, 3260, 67);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20032, 3252, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20033, 3237, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20034, 3250, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20035, 3243, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20035, 3244, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20035, 3230, 53);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20036, 3257, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20037, 3234, 47);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20038, 3234, 65);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20039, 3261, 65);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20039, 3260, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20040, 3263, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20041, 3250, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20042, 3252, 68);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20043, 3233, 51);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20043, 3220, 50);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20044, 3262, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20045, 3262, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20046, 3221, 67);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20046, 3228, 61);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20046, 3216, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20047, 3260, 59);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20047, 3236, 59);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20047, 3264, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20048, 3263, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20049, 3221, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20049, 3225, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20049, 3253, 56);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20050, 3216, 61);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20050, 3228, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20050, 3261, 50);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20051, 3233, 57);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20051, 3251, 49);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20052, 3260, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20052, 3236, 66);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20053, 3235, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20053, 3260, 61);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20053, 3232, 68);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20054, 3228, 51);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20055, 3260, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20056, 3228, 49);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20057, 3260, 58);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20058, 3221, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20058, 3264, 56);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20058, 3236, 53);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20058, 3264, 59);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20059, 3263, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20060, 3216, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20061, 3230, 67);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20061, 3244, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20061, 3243, 60);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20062, 3260, 57);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20063, 3263, 66);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20064, 3264, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20064, 3234, 49);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20064, 3225, 49);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20065, 3244, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20066, 3264, 51);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20066, 3232, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20067, 3263, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20067, 3233, 68);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20068, 3260, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20068, 3232, 54);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20069, 3229, 50);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20069, 3236, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20069, 3232, 63);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20070, 3229, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20070, 3262, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20070, 3260, 47);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20071, 3225, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20072, 3261, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20073, 3230, 50);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20074, 3247, 58);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20074, 3243, 68);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20074, 3230, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20075, 3264, 68);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20076, 3262, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20077, 3251, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20077, 3235, 50);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20078, 3262, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20078, 3228, 57);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20078, 3248, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20079, 3262, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20079, 3229, 53);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20080, 3263, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20080, 3232, 61);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20081, 3222, 54);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20081, 3237, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20082, 3234, 68);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20083, 3216, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20083, 3253, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20083, 3263, 53);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20084, 3252, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20085, 3264, 47);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20086, 3252, 55);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20087, 3230, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20088, 3263, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20089, 3252, 65);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20090, 3232, 58);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20091, 3263, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20091, 3264, 50);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20091, 3216, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20091, 3229, 68);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20092, 3220, 53);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20093, 3220, 62);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20094, 3229, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20095, 3237, 61);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20096, 3248, 49);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20097, 3260, 45);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20098, 3232, 52);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20098, 3264, 48);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20099, 3243, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20100, 3220, 67);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20100, 3251, 59);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20101, 3239, 63);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20102, 3253, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20103, 3225, 69);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20104, 3233, 46);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20105, 3252, 54);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20106, 3243, 49);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20107, 3262, 60);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20107, 3247, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20108, 3225, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20109, 3232, 64);
insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20110, 3251, 49);

-------------------------LabResultDetails---------------------------------------
insert into LabResultDetails(TestID, TestName, Price) values (106, 'Red Blood Cell (RBC) Count',175);
insert into LabResultDetails(TestID, TestName, Price) values (109, 'Complete Blood Count',151);
insert into LabResultDetails(TestID, TestName, Price) values (113, 'Hepatitis C',195);
insert into LabResultDetails(TestID, TestName, Price) values (114, 'Biopsy',150);
insert into LabResultDetails(TestID, TestName, Price) values (115, 'Serum Vitamin B12',159);
insert into LabResultDetails(TestID, TestName, Price) values (117, 'Chromosome Analysis',81);
insert into LabResultDetails(TestID, TestName, Price) values (120, 'Prothrombin Time',80);
insert into LabResultDetails(TestID, TestName, Price) values (121, 'MRI',500);
insert into LabResultDetails(TestID, TestName, Price) values (127, 'LDL Cholesterol',168);
insert into LabResultDetails(TestID, TestName, Price) values (128, 'CT Scan',220);
insert into LabResultDetails(TestID, TestName, Price) values (129, 'EKG / ECG',50);
insert into LabResultDetails(TestID, TestName, Price) values (132, 'Renal Function Panel',151);
insert into LabResultDetails(TestID, TestName, Price) values (135, 'D-Dimer',138);
insert into LabResultDetails(TestID, TestName, Price) values (136, 'Body Fluid Uric Acid',90);
insert into LabResultDetails(TestID, TestName, Price) values (138, 'X-Ray',182);
insert into LabResultDetails(TestID, TestName, Price) values (139, 'Urine Histamine ',52);
insert into LabResultDetails(TestID, TestName, Price) values (140, 'Hepatitis A',109);
insert into LabResultDetails(TestID, TestName, Price) values (141, 'Comprehensive Metabolic Panel',179);
insert into LabResultDetails(TestID, TestName, Price) values (143, 'Hepatitis B',73);
insert into LabResultDetails(TestID, TestName, Price) values (146, 'Bacterial Culture',138);
insert into LabResultDetails(TestID, TestName, Price) values (149, 'Kidney Transplant',150000);
insert into LabResultDetails(TestID, TestName, Price) values (153, 'T3',108);
insert into LabResultDetails(TestID, TestName, Price) values (155, 'HDL Cholesterol',163);
insert into LabResultDetails(TestID, TestName, Price) values (157, 'Serum Albumin ',179);
insert into LabResultDetails(TestID, TestName, Price) values (158, 'Lipid Profile',68);
insert into LabResultDetails(TestID, TestName, Price) values (161, 'Serum Electrolyte Panel ',91);
insert into LabResultDetails(TestID, TestName, Price) values (166, 'Urine Protein',83);
insert into LabResultDetails(TestID, TestName, Price) values (172, 'SARS-CoV-2',50);
insert into LabResultDetails(TestID, TestName, Price) values (174, 'Heart Transplant',50000);
insert into LabResultDetails(TestID, TestName, Price) values (175, 'Dengue Virus Antibody',143);
insert into LabResultDetails(TestID, TestName, Price) values (177, 'Hemoglobin Blood',177);
insert into LabResultDetails(TestID, TestName, Price) values (178, 'Urine D-Lactate',128);
insert into LabResultDetails(TestID, TestName, Price) values (179, 'Blood Urea Nitrogen (BUN)',190);
insert into LabResultDetails(TestID, TestName, Price) values (184, 'HIV',92);
insert into LabResultDetails(TestID, TestName, Price) values (185, 'Influenza Virus',162);
insert into LabResultDetails(TestID, TestName, Price) values (194, 'T4',108);
insert into LabResultDetails(TestID, TestName, Price) values (196, 'Liver Panel',170);
insert into LabResultDetails(TestID, TestName, Price) values (197, 'Bone Fracture Repair',20000);


-------------------------------

---------------------LabResults-------------------


insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20001, 3225, 120, '2020-01-11', 12);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20005, 3231, 127, '2020-02-23', 120);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20006, 3247, 157, '2020-02-14', 2.3);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20010, 3257, 179, '2020-03-18', 30);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20022, 3233, 166, '2020-07-05', 10);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20029, 3223, 115, '2020-09-04', 170);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20041, 3249, 155, '2020-12-16', 60);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20042, 3251, 140, '2020-12-19', 1);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20043, 3232, 172, '2020-12-27', 1);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20046, 3264, 135, '2021-01-05', 240);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20047, 3247, 135, '2021-01-13', 240);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20048, 3263, 155, '2021-01-08', 58);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20049, 3239, 139, '2021-01-10', 13);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20050, 3247, 135, '2021-01-27', 238);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20060, 3228, 139, '2021-05-19', 13);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20061, 3234, 177, '2021-05-27', 15);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20062, 3235, 153, '2021-05-25', 150);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20063, 3224, 179, '2021-05-26', 24);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20064, 3264, 136, '2021-06-03', 1);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20068, 3232, 185, '2021-07-01', 1);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20077, 3263, 166, '2021-09-30', 10);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20078, 3231, 157, '2021-10-15', 5.8);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20081, 3234, 194, '2021-11-02', 4);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20082, 3244, 135, '2021-11-03', 240);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20083, 3225, 120, '2021-11-07', 12);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20088, 3253, 120, '2021-12-29', 12);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20091, 3243, 172, '2022-01-20', 0);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20095, 3239, 136, '2022-02-21', 0);
insert into LabResults(PatEncID, HealthCareProviderID, TestID, StoreTime,Val) values (20096, 3247, 179, '2022-02-20', 14);



-------------------VitalSignDetails----------------------------
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (1, 'BP Systolic' , 'mm/hg');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (2, 'BP Diastolic' , 'mm/hg');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (3, 'Pulse' , 'per min');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (4, 'Respiration' , 'per min');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (5, 'Temperature' , 'F');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (6, 'Weight' , 'lbs');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (7, 'Height' , 'm');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (8, 'BMI' , 'lbs/m2');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (9, 'SPO2' , '%');
insert into VitalSignDetails (VitalID, VitalName, VitalUnit) values (10, 'Pain Scale' , 'level');


------------VitalSigns---------------------------

insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20001, 10, '2020-01-06', 5);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20002, 3, '2020-01-21', 108);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20003, 1, '2020-01-30', 115);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20004, 3, '2020-02-15', 101);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20005, 7, '2020-02-22', 2);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20006, 8, '2020-02-17', 26);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20007, 10, '2020-03-03', 5);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20008, 8, '2020-02-24', 29);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20009, 10, '2020-03-02', 2);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20010, 2, '2020-03-17', 100);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20011, 2, '2020-03-12', 77);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20012, 10, '2020-03-11', 7);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20013, 5, '2020-03-25', 98);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20014, 5, '2020-03-18', 104);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20015, 1, '2020-04-10', 112);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20016, 4, '2020-04-12', 27);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20017, 7, '2020-04-20', 2);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20018, 5, '2020-04-23', 103);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20019, 5, '2020-04-22', 108);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20020, 8, '2020-05-19', 32);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20021, 8, '2020-06-09', 31);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20022, 7, '2020-07-04', 1);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20023, 4, '2020-07-12', 13);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20024, 4, '2020-07-26', 24);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20025, 1, '2020-07-28', 111);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20026, 7, '2020-07-31', 2);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20027, 5, '2020-08-08', 106);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20028, 4, '2020-08-21', 10);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20029, 4, '2020-09-04', 11);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20030, 6, '2020-09-04', 167);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20031, 6, '2020-10-05', 120);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20032, 6, '2020-10-06', 182);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20033, 9, '2020-10-25', 91);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20034, 5, '2020-11-05', 101);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20035, 2, '2020-11-04', 77);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20036, 3, '2020-11-18', 82);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20037, 1, '2020-11-15', 125);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20038, 3, '2020-11-17', 136);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20039, 10, '2020-11-21', 7);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20040, 10, '2020-12-08', 3);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20041, 2, '2020-12-09', 99);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20042, 9, '2020-12-19', 95);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20043, 5, '2020-12-24', 102);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20044, 2, '2020-12-28', 86);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20045, 3, '2020-12-29', 97);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20046, 9, '2021-01-02', 91);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20047, 6, '2021-01-18', 276);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20048, 3, '2021-01-05', 115);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20049, 7, '2021-01-14', 1);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20050, 9, '2021-01-22', 93);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20051, 4, '2021-01-26', 29);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20052, 5, '2021-01-31', 98);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20053, 9, '2021-02-25', 96);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20054, 3, '2021-03-01', 150);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20055, 10, '2021-04-06', 6);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20056, 2, '2021-04-05', 66);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20057, 9, '2021-04-09', 99);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20058, 9, '2021-05-01', 92);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20059, 7, '2021-05-14', 2);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20060, 10, '2021-05-19', 7);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20061, 1, '2021-05-31', 108);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20062, 2, '2021-05-25', 79);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20063, 3, '2021-05-28', 121);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20064, 10, '2021-06-03', 7);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20065, 3, '2021-06-19', 130);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20066, 2, '2021-06-26', 73);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20067, 8, '2021-06-21', 28);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20068, 3, '2021-06-24', 129);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20069, 8, '2021-07-23', 23);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20070, 3, '2021-07-30', 130);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20071, 3, '2021-08-04', 144);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20072, 2, '2021-08-11', 75);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20073, 2, '2021-08-14', 87);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20074, 2, '2021-08-24', 69);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20075, 6, '2021-09-15', 224);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20076, 4, '2021-09-21', 26);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20077, 10, '2021-09-22', 6);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20078, 4, '2021-10-15', 28);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20079, 7, '2021-10-26', 2);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20080, 10, '2021-10-20', 3);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20081, 4, '2021-11-02', 16);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20082, 7, '2021-11-10', 2);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20083, 1, '2021-11-06', 101);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20084, 2, '2021-11-10', 67);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20085, 6, '2021-11-24', 237);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20086, 9, '2021-11-29', 93);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20087, 1, '2021-12-30', 115);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20088, 6, '2021-12-28', 126);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20089, 7, '2022-01-19', 1);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20090, 6, '2022-01-17', 121);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20091, 3, '2022-01-22', 110);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20092, 8, '2022-01-21', 20);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20093, 5, '2022-01-26', 97);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20094, 8, '2022-01-27', 18);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20095, 8, '2022-02-16', 26);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20096, 4, '2022-02-23', 23);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20097, 6, '2022-02-24', 189);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20098, 1, '2022-03-09', 119);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20099, 7, '2022-03-18', 1);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20100, 1, '2022-03-21', 134);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20101, 8, '2022-03-21', 34);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20102, 1, '2022-03-21', 135);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20103, 7, '2022-03-20', 2);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20104, 6, '2022-03-24', 264);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20105, 10, '2022-03-25', 8);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20106, 2, '2022-04-07', 61);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20107, 5, '2022-04-05', 108);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20108, 1, '2022-04-06', 125);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20109, 9, '2022-04-10', 90);
insert into VitalSigns(PatEncID, VitalID, StoreTime, VitalVal) values (20110, 5, '2022-04-09', 103);


----------------------MedicationDetails--------------------------

insert into MedicationDetails(MedID, MedName, MedPrice) values (41, 'Contac', 6.86);
insert into MedicationDetails(MedID, MedName, MedPrice) values (42, 'Tylenol', 6.5);
insert into MedicationDetails(MedID, MedName, MedPrice) values (43, 'Atorvastatin', 5.4);
insert into MedicationDetails(MedID, MedName, MedPrice) values (44, 'Lisinopril', 3);
insert into MedicationDetails(MedID, MedName, MedPrice) values (45, 'Metformin', 4);
insert into MedicationDetails(MedID, MedName, MedPrice) values (46, 'Advil', 5.99);
insert into MedicationDetails(MedID, MedName, MedPrice) values (47, 'Nyquil', 9.99);
insert into MedicationDetails(MedID, MedName, MedPrice) values (48, 'Gabapentin', 10.2);
insert into MedicationDetails(MedID, MedName, MedPrice) values (49, 'Omeprazole', 5.1);
insert into MedicationDetails(MedID, MedName, MedPrice) values (50, 'Losartan', 2.14);
insert into MedicationDetails(MedID, MedName, MedPrice) values (51, 'Amlodipine', 3.9);

---------------------------Prescription-----------------------------

insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8001, 47, 20001, 3233, '2020-01-06', '2020-01-11', 2, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8002, 49, 20002, 3223, '2020-01-27', '2020-01-31', 1, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8003, 45, 20003, 3231, '2020-01-25', '2020-01-25', 3, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8004, 49, 20004, 3231, '2020-02-12', '2020-02-15', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8005, 43, 20005, 3252, '2020-02-13', '2020-02-20', 2, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8006, 44, 20006, 3231, '2020-02-14', '2020-02-16', 3, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8007, 44, 20007, 3216, '2020-02-24', '2020-02-29', 1, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8008, 41, 20008, 3220, '2020-02-27', '2020-02-27', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8009, 50, 20009, 3260, '2020-03-02', '2020-03-08', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8010, 45, 20010, 3232, '2020-03-11', '2020-03-12', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8011, 47, 20011, 3233, '2020-03-12', '2020-03-17', 2, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8012, 48, 20012, 3232, '2020-03-13', '2020-03-17', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8013, 47, 20013, 3232, '2020-03-27', '2020-03-27', 1, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8014, 43, 20014, 3229, '2020-03-21', '2020-03-27', 1, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8015, 50, 20015, 3257, '2020-04-08', '2020-04-11', 1, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8016, 41, 20016, 3237, '2020-04-15', '2020-04-16', 2, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8017, 47, 20017, 3223, '2020-04-20', '2020-04-23', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8018, 48, 20018, 3262, '2020-04-25', '2020-04-26', 3, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8019, 43, 20019, 3253, '2020-04-21', '2020-04-24', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8020, 42, 20020, 3235, '2020-05-19', '2020-05-25', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8021, 43, 20021, 3261, '2020-06-06', '2020-06-10', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8022, 41, 20022, 3223, '2020-07-04', '2020-07-05', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8023, 49, 20023, 3247, '2020-07-10', '2020-07-16', 2, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8024, 45, 20024, 3249, '2020-07-27', '2020-08-02', 3, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8025, 47, 20025, 3233, '2020-07-30', '2020-07-31', 2, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8026, 47, 20026, 3264, '2020-08-08', '2020-08-09', 3, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8027, 47, 20027, 3229, '2020-08-06', '2020-08-13', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8028, 51, 20028, 3253, '2020-08-15', '2020-08-16', 2, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8029, 45, 20029, 3250, '2020-09-04', '2020-09-10', 3, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8030, 51, 20030, 3224, '2020-09-06', '2020-09-06', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8031, 42, 20031, 3264, '2020-10-04', '2020-10-05', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8032, 49, 20032, 3233, '2020-10-07', '2020-10-09', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8033, 51, 20033, 3253, '2020-10-27', '2020-10-30', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8034, 41, 20034, 3263, '2020-10-29', '2020-11-03', 3, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8035, 49, 20035, 3221, '2020-11-02', '2020-11-06', 2, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8036, 47, 20036, 3230, '2020-11-17', '2020-11-17', 1, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8037, 49, 20037, 3250, '2020-11-23', '2020-11-26', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8038, 47, 20038, 3261, '2020-11-19', '2020-11-26', 1, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8039, 50, 20039, 3236, '2020-11-29', '2020-12-05', 3, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8040, 44, 20040, 3234, '2020-12-09', '2020-12-15', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8041, 46, 20041, 3216, '2020-12-07', '2020-12-11', 3, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8042, 41, 20042, 3232, '2020-12-19', '2020-12-20', 2, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8043, 42, 20043, 3235, '2020-12-23', '2020-12-25', 1, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8044, 50, 20044, 3264, '2020-12-30', '2021-01-03', 3, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8045, 51, 20045, 3239, '2020-12-30', '2021-01-02', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8046, 44, 20046, 3263, '2021-01-04', '2021-01-10', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8047, 46, 20047, 3225, '2021-01-04', '2021-01-10', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8048, 45, 20048, 3235, '2021-01-04', '2021-01-08', 2, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8049, 50, 20049, 3223, '2021-01-12', '2021-01-19', 1, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8050, 45, 20050, 3220, '2021-01-24', '2021-01-27', 2, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8051, 42, 20051, 3261, '2021-01-27', '2021-02-02', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8052, 43, 20052, 3225, '2021-01-30', '2021-02-03', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8053, 42, 20053, 3220, '2021-02-25', '2021-03-01', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8054, 43, 20054, 3225, '2021-03-06', '2021-03-08', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8055, 43, 20055, 3247, '2021-04-04', '2021-04-05', 3, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8056, 44, 20056, 3223, '2021-03-31', '2021-04-04', 2, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8057, 47, 20057, 3251, '2021-04-13', '2021-04-15', 2, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8058, 46, 20058, 3252, '2021-05-05', '2021-05-11', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8059, 45, 20059, 3225, '2021-05-13', '2021-05-13', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8060, 49, 20060, 3244, '2021-05-14', '2021-05-14', 2, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8061, 51, 20061, 3225, '2021-05-26', '2021-05-28', 3, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8062, 44, 20062, 3264, '2021-05-24', '2021-05-28', 2, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8063, 41, 20063, 3237, '2021-05-29', '2021-06-01', 1, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8064, 48, 20064, 3250, '2021-06-02', '2021-06-08', 3, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8065, 44, 20065, 3250, '2021-06-15', '2021-06-22', 3, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8066, 51, 20066, 3257, '2021-06-27', '2021-07-02', 2, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8067, 47, 20067, 3220, '2021-06-25', '2021-07-01', 1, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8068, 47, 20068, 3253, '2021-06-27', '2021-07-02', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8069, 47, 20069, 3251, '2021-07-18', '2021-07-22', 3, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8070, 51, 20070, 3250, '2021-08-08', '2021-08-08', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8071, 47, 20071, 3260, '2021-08-04', '2021-08-10', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8072, 49, 20072, 3247, '2021-08-14', '2021-08-20', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8073, 47, 20073, 3257, '2021-08-18', '2021-08-23', 2, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8074, 41, 20074, 3232, '2021-08-23', '2021-08-30', 1, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8075, 49, 20075, 3224, '2021-09-15', '2021-09-16', 2, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8076, 42, 20076, 3239, '2021-09-26', '2021-09-27', 2, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8077, 43, 20077, 3230, '2021-09-30', '2021-10-06', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8078, 46, 20078, 3223, '2021-10-16', '2021-10-18', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8079, 44, 20079, 3247, '2021-10-21', '2021-10-25', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8080, 41, 20080, 3234, '2021-10-19', '2021-10-22', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8081, 46, 20081, 3216, '2021-11-03', '2021-11-04', 2, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8082, 50, 20082, 3230, '2021-11-01', '2021-11-06', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8083, 49, 20083, 3228, '2021-11-07', '2021-11-13', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8084, 41, 20084, 3223, '2021-11-10', '2021-11-10', 2, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8085, 42, 20085, 3235, '2021-11-15', '2021-11-16', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8086, 42, 20086, 3216, '2021-11-25', '2021-11-30', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8087, 42, 20087, 3251, '2021-12-27', '2022-01-02', 1, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8088, 50, 20088, 3216, '2021-12-28', '2022-01-01', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8089, 48, 20089, 3262, '2022-01-19', '2022-01-19', 1, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8090, 43, 20090, 3243, '2022-01-18', '2022-01-25', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8091, 44, 20091, 3243, '2022-01-17', '2022-01-23', 3, 5);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8092, 45, 20092, 3251, '2022-01-24', '2022-01-30', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8093, 46, 20093, 3262, '2022-01-29', '2022-02-03', 2, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8094, 49, 20094, 3260, '2022-01-30', '2022-02-05', 1, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8095, 42, 20095, 3249, '2022-02-16', '2022-02-21', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8096, 43, 20096, 3251, '2022-02-20', '2022-02-27', 2, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8097, 51, 20097, 3257, '2022-02-23', '2022-02-25', 2, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8098, 46, 20098, 3235, '2022-02-27', '2022-03-01', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8099, 43, 20099, 3251, '2022-03-17', '2022-03-22', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8100, 51, 20100, 3263, '2022-03-17', '2022-03-20', 1, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8101, 42, 20101, 3252, '2022-03-17', '2022-03-18', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8102, 47, 20102, 3222, '2022-03-17', '2022-03-23', 2, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8103, 41, 20103, 3220, '2022-03-18', '2022-03-25', 2, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8104, 43, 20104, 3249, '2022-03-19', '2022-03-23', 2, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8105, 44, 20105, 3253, '2022-03-25', '2022-03-26', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8106, 41, 20106, 3232, '2022-04-02', '2022-04-09', 2, 4);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8107, 44, 20107, 3216, '2022-04-04', '2022-04-10', 3, 2);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8108, 51, 20108, 3250, '2022-04-05', '2022-04-08', 1, 1);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8109, 45, 20109, 3253, '2022-04-06', '2022-04-13', 3, 3);
insert into Prescription(PrescriptionID, MedID, PatEncID, HealthCareProviderID, PrescStartDate, PrescEndDate, PrescDose,PrescQty) values (8110, 44, 20110, 3263, '2022-04-07', '2022-04-08', 2, 3);



----------------Billing-------------------


insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7001, 20001, 'Yes', 70);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7002, 20002, 'Yes', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7003, 20003, 'Yes', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7004, 20004, 'Yes', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7005, 20005, 'Partial', 116);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7006, 20006, 'Yes', 128);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7007, 20007, 'No', 2);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7008, 20008, 'Partial', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7009, 20009, 'Yes', 2);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7010, 20010, 'Yes', 156);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7011, 20011, 'Partial', 8);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7012, 20012, 'Yes', 8);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7013, 20013, 'Partial', 9);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7014, 20014, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7015, 20015, 'No', 2);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7016, 20016, 'Partial', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7017, 20017, 'Yes', 8);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7018, 20018, 'Yes', 9);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7019, 20019, 'Yes', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7020, 20020, 'Partial', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7021, 20021, 'Yes', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7022, 20022, 'Partial', 70);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7023, 20023, 'Yes', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7024, 20024, 'Partial', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7025, 20025, 'Yes', 8);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7026, 20026, 'Yes', 8);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7027, 20027, 'Partial', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7028, 20028, 'No', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7029, 20029, 'No', 99);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7030, 20030, 'Partial', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7031, 20031, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7032, 20032, 'Yes', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7033, 20033, 'Partial', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7034, 20034, 'Partial', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7035, 20035, 'Yes', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7036, 20036, 'No', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7037, 20037, 'Partial', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7038, 20038, 'Partial', 7);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7039, 20039, 'No', 2);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7040, 20040, 'No', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7041, 20041, 'Yes', 140);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7042, 20042, 'No', 98);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7043, 20043, 'Yes', 42);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7044, 20044, 'Partial', 2);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7045, 20045, 'Partial', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7046, 20046, 'Yes', 131);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7047, 20047, 'Yes', 126);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7048, 20048, 'Partial', 132);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7049, 20049, 'Yes', 53);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7050, 20050, 'Partial', 104);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7051, 20051, 'Partial', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7052, 20052, 'Partial', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7053, 20053, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7054, 20054, 'Yes', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7055, 20055, 'Yes', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7056, 20056, 'Yes', 2);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7057, 20057, 'Yes', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7058, 20058, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7059, 20059, 'Partial', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7060, 20060, 'Yes', 42);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7061, 20061, 'Yes', 162);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7062, 20062, 'Partial', 82);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7063, 20063, 'Yes', 153);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7064, 20064, 'Yes', 61);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7065, 20065, 'Yes', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7066, 20066, 'Partial', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7067, 20067, 'Yes', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7068, 20068, 'Yes', 120);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7069, 20069, 'Yes', 9);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7070, 20070, 'Yes', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7071, 20071, 'Yes', 9);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7072, 20072, 'Yes', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7073, 20073, 'Yes', 9);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7074, 20074, 'Yes', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7075, 20075, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7076, 20076, 'Yes', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7077, 20077, 'Partial', 81);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7078, 20078, 'No', 153);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7079, 20079, 'Yes', 2);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7080, 20080, 'Yes', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7081, 20081, 'Yes', 82);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7082, 20082, 'Yes', 105);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7083, 20083, 'No', 64);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7084, 20084, 'Yes', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7085, 20085, 'Yes', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7086, 20086, 'Yes', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7087, 20087, 'Yes', 6);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7088, 20088, 'Yes', 76);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7089, 20089, 'Yes', 7);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7090, 20090, 'Yes', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7091, 20091, 'Yes', 50);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7092, 20092, 'Partial', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7093, 20093, 'Yes', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7094, 20094, 'No', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7095, 20095, 'No', 62);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7096, 20096, 'No', 120);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7097, 20097, 'No', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7098, 20098, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7099, 20099, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7100, 20100, 'No', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7101, 20101, 'No', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7102, 20102, 'No', 9);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7103, 20103, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7104, 20104, 'No', 4);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7105, 20105, 'No', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7106, 20106, 'No', 5);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7107, 20107, 'No', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7108, 20108, 'No', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7109, 20109, 'No', 3);
insert into Billing(BillingID, PatEncID, PaymentStatus, ClaimSanctionAmt) values (7110, 20110, 'No', 2);



---------------Checks for Computed Columns, Table check constraints and Trigger-------------------

---computed column age in Patient
Select * from Patient

----computed column LengthOfStay in PatientEncounter--
Select * from PatientEncounter

----Computed Column OrderTotal in Billing---

----Trigger updates Payment Status based on OrderTotal and ClaimSanctionAmount after Insert--------

Select * from Billing


-----------Testing for Table level check constraint for Admit Physician----
-------- 3215 is a Hospital pharmacist (Cannot Admit a Patient)----------

insert into PatientEncounter(PatEncID, PatID, HealthCareProviderID, PatEncAdmitDate, AdmitType, AdmitLocation, PatEncDiscDate, DiscLocation) values (20111, 130, 3215, '2022-04-07', 'Emergency', 'Intensive Care Unit (ICU)', NULL, NULL);

---------Testing for Table level check for Diagnosing Physician----
-------- 3219 Social worker (Cannot Diagnose a Patient)----------

insert into Diagnosis( PatEncID, HealthCareProviderID, DxCode) values (20099, 3219, 46);


----------------View for details of Patient(Demographic Details, EPOC, InsuranceProvider)-------


CREATE VIEW PatientDetails AS SELECT 
pat.PatID, pat.FirstName, pat.LastName, pat.DoB, pat.Street, 
pat.City, pat.State, pat.ZipCode, pat.PhoneNo, pat.EmailAddress, pat.Age,
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

--------------------View to get all the PatientEncounter --------------
----------------level LabResults and VitalSigns details----------------


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

-----------------------------------------------------