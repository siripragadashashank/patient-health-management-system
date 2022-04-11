CREATE TABLE LabResults
(
ParEncID INT FOREIGN KEY 
REFERENCES PatientEncounter(PatEncID), 
HealthCareProviderID INT 
REFERENCES PatientEncounter(HealthCareProviderID),
TESTID INT FOREIGN KEY NOT NULL,
StoreTime Date,
Value Double,
ValNum INT
);

CREATE TABLE LabResultDetails
(
TestID INT PRIMARY KEY 
REFERENCES LabResults(TestID),
TestName VARCHAR(45),
TestDept VARCHAR(45),
Price DOUBLE

);

CREATE TABLE VitalSigns
(
PatEncID INT FOREIGN KEY
REFERENCES PatientEncounter(PatEncID),
VitalID INT FOREIGN KEY NOT NULL,
StoreTime DATE,
VitalVal VARCHAR(45),
VitalValNum DOUBLE
);

CREATE TABLE VitalSignDetails
(
VitalID INT PRIMARY KEY 
REFERENCES VitalSigns(VitalID),
VitalName VARCHAR(45),
VitalUnit VARCHAR(45)
);