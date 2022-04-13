USE PHMS

--------------------DiagnosisDetails------------------------------
insert into DiagnosisDetails(DxCode, DxName) values (7, 'Congestive heart failure (CHF)');
insert into DiagnosisDetails(DxCode, DxName) values (8, 'Acute myocardial infarction');
insert into DiagnosisDetails(DxCode, DxName) values (9, 'Cardiac dysrhythmia');
insert into DiagnosisDetails(DxCode, DxName) values (12, 'Lumbago');
insert into DiagnosisDetails(DxCode, DxName) values (15, 'Chronic obstructive pulmonary disease (COPD)');
insert into DiagnosisDetails(DxCode, DxName) values (19, 'Atrial fibrillation');
insert into DiagnosisDetails(DxCode, DxName) values (25, 'Diabetes Type I');
insert into DiagnosisDetails(DxCode, DxName) values (26, 'Diabetes Type II');
insert into DiagnosisDetails(DxCode, DxName) values (27, 'Urinary tract infection (UTI)');
insert into DiagnosisDetails(DxCode, DxName) values (34, 'Abdominal infection');
insert into DiagnosisDetails(DxCode, DxName) values (35, 'Osteoarthritis');
insert into DiagnosisDetails(DxCode, DxName) values (42, 'Jaundice');
insert into DiagnosisDetails(DxCode, DxName) values (57, 'Hypertension');
insert into DiagnosisDetails(DxCode, DxName) values (60, 'Surgical Complication');
insert into DiagnosisDetails(DxCode, DxName) values (62, 'Heart failure');
insert into DiagnosisDetails(DxCode, DxName) values (64, 'Acute bronchitis');
insert into DiagnosisDetails(DxCode, DxName) values (67, 'Pneumonia');
insert into DiagnosisDetails(DxCode, DxName) values (68, 'COVID-19');
insert into DiagnosisDetails(DxCode, DxName) values (71, 'Basal cell carcinoma of skin');
insert into DiagnosisDetails(DxCode, DxName) values (72, 'Carcinoma in stomach');
insert into DiagnosisDetails(DxCode, DxName) values (73, 'Carcinoma in eye');
insert into DiagnosisDetails(DxCode, DxName) values (80, 'Cerebral infraction');
insert into DiagnosisDetails(DxCode, DxName) values (84, 'Clostridium difficile (C.Diff)');
insert into DiagnosisDetails(DxCode, DxName) values (98, 'Sepsis');
insert into DiagnosisDetails(DxCode, DxName) values (99, 'Severe sepsis');

select * from DiagnosisDetails

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

select * from LabResultDetails

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
select * from EPOC