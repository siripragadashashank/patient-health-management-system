--Create database PHMS;

use PHMS;


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
EPOCPhoneNo INTEGER
);

create table InsuranceProvider
(
InsuranceProviderID int primary key,
PatID INT NOT NULL REFERENCES Patient(PatID),
InsuranceProviderName VARCHAR(45),
PatientInsuranceNo Int
);

create table SymptomDetails
(
SymCode int primary key,
SymName varchar(45)
);

create table Symptom
(
PatEncID int not null references PatientEncounter(PatEncID),
SymCode int not null references SymptomDetails(SymCode),
Duration int
);

create table DiagnosisDetails
(
DxCode int primary key,
DxName varchar(45)
);

create table Diagnosis
(
PatEncID int not null references PatientEncounter(PatEncID),
HealthCareProviderID int not null references HealthCareProvider(HealthCareProviderID),
DxCode int not null references DiagnosisDetails(DxCode)
);