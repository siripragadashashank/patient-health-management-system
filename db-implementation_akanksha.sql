use PHMS;

 CREATE TABLE Patient
(
PatID INT PRIMARY KEY, 
FirstName VARCHAR(100),
LastName VARCHAR(100),
DoB DateTime,
Street VARCHAR(100),
City VARCHAR(100),
State VARCHAR(100),
ZipCode INT,
PhoneNo INT, 
EmailAddress VARCHAR(100),
);

 CREATE TABLE HealthCareProvider
(
HealthCareProviderID INT PRIMARY KEY, 
Designation VARCHAR(45),
EmpFirstName VARCHAR(45),
EmpLastName VARCHAR(45),
EmpContactNo INT,
);



 CREATE TABLE PatientEncounter
(
PatEncID INT PRIMARY KEY, 
PatID INT NOT NULL
REFERENCES Patient(PatID),
HealthCareProviderID INT NOT NULL
REFERENCES HealthCareProvider(HealthCareProviderID),
PatEncAdmitDate DateTime,
AdmitType VARCHAR(45),
AdmitLocation VARCHAR(45),
PatEncDiscDate DATETIME,
DiscLocation VARCHAR(45),
);


CREATE TABLE SymptomDetails
(
SymCode INT PRIMARY KEY, 
SymName VARCHAR(45)
);



CREATE TABLE Symptoms
(
PatEncID INT NOT NULL
REFERENCES PatientEncounter(PatEncID),
SymCode INT NOT NULL
REFERENCES SymptomDetails(SymCode),
Duration INT
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
MedID INT NOT NULL
REFERENCES MedicationDetails(MedID),
PatEncID INT NOT NULL
REFERENCES PatientEncounter(PatEncID),
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
OrderTotal DOUBLE PRECISION,
PaymentStatus VARCHAR(45),
ClaimSanctionAmt DOUBLE PRECISION
);



