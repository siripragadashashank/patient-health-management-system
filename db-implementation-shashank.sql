--Create database PHMS;

use PHMS;


CREATE TABLE PatientDemographics
(
PatID INT NOT NULL
REFERENCES Patient(PatID),
Gender VARCHAR(45),
Race VARCHAR(45),
Ethnicity VARCHAR(45),
MaritalStatus VARCHAR(45),
EmploymentStatus VARCHAR(45)
);
