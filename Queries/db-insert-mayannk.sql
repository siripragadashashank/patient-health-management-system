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

--------------------------------------------------