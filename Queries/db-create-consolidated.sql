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


-----------------CREATE----------------------------

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