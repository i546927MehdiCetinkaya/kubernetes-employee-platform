-- Seed Data for HR Database
-- Case Study 3 - Mock Employee Data (GDPR-compliant)
-- 50+ employees across 4 departments

-- Insert Departments first
INSERT INTO departments (name, budget, location) VALUES
    ('Engineering', 2500000.00, 'Amsterdam, Netherlands'),
    ('HR', 800000.00, 'Rotterdam, Netherlands'),
    ('Finance', 1200000.00, 'Amsterdam, Netherlands'),
    ('IT', 1500000.00, 'Utrecht, Netherlands');

-- Insert Employees (managers first, then other employees)
-- Engineering Department
INSERT INTO employees (employee_number, first_name, last_name, email, phone, department_id, job_title, hire_date, birth_date, ssn_encrypted, salary, status) VALUES
    ('EMP-001', 'Lars', 'van der Berg', 'lars.vandeberg@innovatech.nl', '+31-20-1234567', 1, 'VP of Engineering', '2018-01-15', '1980-03-20', encode('123-45-6789'::bytea, 'base64'), 125000.00, 'active'),
    ('EMP-002', 'Sophie', 'Jansen', 'sophie.jansen@innovatech.nl', '+31-20-1234568', 1, 'Senior Software Engineer', '2019-03-10', '1985-07-14', encode('234-56-7890'::bytea, 'base64'), 95000.00, 'active'),
    ('EMP-003', 'Daan', 'de Vries', 'daan.devries@innovatech.nl', '+31-20-1234569', 1, 'Software Engineer', '2020-06-22', '1990-11-08', encode('345-67-8901'::bytea, 'base64'), 75000.00, 'active'),
    ('EMP-004', 'Emma', 'Bakker', 'emma.bakker@innovatech.nl', '+31-20-1234570', 1, 'Software Engineer', '2021-02-15', '1992-05-22', encode('456-78-9012'::bytea, 'base64'), 72000.00, 'active'),
    ('EMP-005', 'Noah', 'Visser', 'noah.visser@innovatech.nl', '+31-20-1234571', 1, 'DevOps Engineer', '2020-09-01', '1988-09-30', encode('567-89-0123'::bytea, 'base64'), 85000.00, 'active'),
    ('EMP-006', 'Lotte', 'van Dijk', 'lotte.vandijk@innovatech.nl', '+31-20-1234572', 1, 'QA Engineer', '2021-04-12', '1991-02-17', encode('678-90-1234'::bytea, 'base64'), 68000.00, 'active'),
    ('EMP-007', 'Sem', 'Mulder', 'sem.mulder@innovatech.nl', '+31-20-1234573', 1, 'Junior Software Engineer', '2022-01-10', '1995-08-05', encode('789-01-2345'::bytea, 'base64'), 55000.00, 'active'),
    ('EMP-008', 'Julia', 'de Jong', 'julia.dejong@innovatech.nl', '+31-20-1234574', 1, 'Junior Software Engineer', '2022-03-20', '1996-12-11', encode('890-12-3456'::bytea, 'base64'), 53000.00, 'active'),
    ('EMP-009', 'Lucas', 'Hendriks', 'lucas.hendriks@innovatech.nl', '+31-20-1234575', 1, 'Software Architect', '2017-11-05', '1982-06-28', encode('901-23-4567'::bytea, 'base64'), 110000.00, 'active'),
    ('EMP-010', 'Mila', 'Peters', 'mila.peters@innovatech.nl', '+31-20-1234576', 1, 'Frontend Developer', '2021-08-15', '1993-04-19', encode('012-34-5678'::bytea, 'base64'), 70000.00, 'active'),
    ('EMP-011', 'Thijs', 'Smit', 'thijs.smit@innovatech.nl', '+31-20-1234577', 1, 'Backend Developer', '2020-11-22', '1989-10-03', encode('123-45-6780'::bytea, 'base64'), 80000.00, 'active'),
    ('EMP-012', 'Fleur', 'Vermeer', 'fleur.vermeer@innovatech.nl', '+31-20-1234578', 1, 'Data Engineer', '2021-05-30', '1990-07-25', encode('234-56-7891'::bytea, 'base64'), 82000.00, 'active'),
    ('EMP-013', 'Bram', 'de Boer', 'bram.deboer@innovatech.nl', '+31-20-1234579', 1, 'Machine Learning Engineer', '2020-02-14', '1987-01-12', encode('345-67-8902'::bytea, 'base64'), 92000.00, 'active');

-- HR Department
INSERT INTO employees (employee_number, first_name, last_name, email, phone, department_id, job_title, hire_date, birth_date, ssn_encrypted, salary, status) VALUES
    ('EMP-014', 'Anna', 'Meijer', 'anna.meijer@innovatech.nl', '+31-10-1234567', 2, 'HR Director', '2017-03-01', '1978-09-15', encode('456-78-9013'::bytea, 'base64'), 105000.00, 'active'),
    ('EMP-015', 'Sven', 'van Leeuwen', 'sven.vanleeuwen@innovatech.nl', '+31-10-1234568', 2, 'HR Manager', '2019-07-10', '1985-05-22', encode('567-89-0124'::bytea, 'base64'), 78000.00, 'active'),
    ('EMP-016', 'Lisa', 'Willems', 'lisa.willems@innovatech.nl', '+31-10-1234569', 2, 'Recruiter', '2020-04-20', '1991-11-30', encode('678-90-1235'::bytea, 'base64'), 58000.00, 'active'),
    ('EMP-017', 'Max', 'Dekker', 'max.dekker@innovatech.nl', '+31-10-1234570', 2, 'HR Coordinator', '2021-09-05', '1993-03-17', encode('789-01-2346'::bytea, 'base64'), 52000.00, 'active'),
    ('EMP-018', 'Eva', 'van Dam', 'eva.vandam@innovatech.nl', '+31-10-1234571', 2, 'Payroll Specialist', '2020-01-15', '1988-08-08', encode('890-12-3457'::bytea, 'base64'), 60000.00, 'active'),
    ('EMP-019', 'Tom', 'Kok', 'tom.kok@innovatech.nl', '+31-10-1234572', 2, 'Benefits Administrator', '2021-11-01', '1990-12-05', encode('901-23-4568'::bytea, 'base64'), 55000.00, 'active');

-- Finance Department
INSERT INTO employees (employee_number, first_name, last_name, email, phone, department_id, job_title, hire_date, birth_date, ssn_encrypted, salary, status) VALUES
    ('EMP-020', 'Pieter', 'Brouwer', 'pieter.brouwer@innovatech.nl', '+31-20-2234567', 3, 'CFO', '2017-06-01', '1975-04-12', encode('012-34-5679'::bytea, 'base64'), 140000.00, 'active'),
    ('EMP-021', 'Charlotte', 'Vos', 'charlotte.vos@innovatech.nl', '+31-20-2234568', 3, 'Financial Controller', '2019-02-15', '1983-10-20', encode('123-45-6781'::bytea, 'base64'), 95000.00, 'active'),
    ('EMP-022', 'Finn', 'van den Berg', 'finn.vandenberg@innovatech.nl', '+31-20-2234569', 3, 'Senior Accountant', '2020-05-10', '1986-06-15', encode('234-56-7892'::bytea, 'base64'), 72000.00, 'active'),
    ('EMP-023', 'Sanne', 'Jacobs', 'sanne.jacobs@innovatech.nl', '+31-20-2234570', 3, 'Accountant', '2021-03-22', '1991-02-28', encode('345-67-8903'::bytea, 'base64'), 60000.00, 'active'),
    ('EMP-024', 'Jesse', 'van Wijk', 'jesse.vanwijk@innovatech.nl', '+31-20-2234571', 3, 'Junior Accountant', '2022-07-01', '1995-09-10', encode('456-78-9014'::bytea, 'base64'), 48000.00, 'active'),
    ('EMP-025', 'Noa', 'de Groot', 'noa.degroot@innovatech.nl', '+31-20-2234572', 3, 'Financial Analyst', '2020-10-05', '1989-05-18', encode('567-89-0125'::bytea, 'base64'), 68000.00, 'active'),
    ('EMP-026', 'Milan', 'Hoekstra', 'milan.hoekstra@innovatech.nl', '+31-20-2234573', 3, 'Budget Analyst', '2021-06-18', '1992-11-22', encode('678-90-1236'::bytea, 'base64'), 62000.00, 'active');

-- IT Department
INSERT INTO employees (employee_number, first_name, last_name, email, phone, department_id, job_title, hire_date, birth_date, ssn_encrypted, salary, status) VALUES
    ('EMP-027', 'Robin', 'van der Meer', 'robin.vandermeer@innovatech.nl', '+31-30-3234567', 4, 'IT Director', '2018-04-10', '1979-07-08', encode('789-01-2347'::bytea, 'base64'), 115000.00, 'active'),
    ('EMP-028', 'Isa', 'Scholten', 'isa.scholten@innovatech.nl', '+31-30-3234568', 4, 'IT Manager', '2019-09-20', '1984-12-14', encode('890-12-3458'::bytea, 'base64'), 88000.00, 'active'),
    ('EMP-029', 'Luuk', 'Prins', 'luuk.prins@innovatech.nl', '+31-30-3234569', 4, 'Systems Administrator', '2020-03-15', '1988-03-25', encode('901-23-4569'::bytea, 'base64'), 70000.00, 'active'),
    ('EMP-030', 'Zoey', 'Kuipers', 'zoey.kuipers@innovatech.nl', '+31-30-3234570', 4, 'Network Engineer', '2021-01-20', '1990-08-30', encode('012-34-5680'::bytea, 'base64'), 75000.00, 'active'),
    ('EMP-031', 'Jayden', 'Verhoeven', 'jayden.verhoeven@innovatech.nl', '+31-30-3234571', 4, 'Security Engineer', '2020-07-12', '1987-04-19', encode('123-45-6782'::bytea, 'base64'), 85000.00, 'active'),
    ('EMP-032', 'Tess', 'van der Linden', 'tess.vanderlinden@innovatech.nl', '+31-30-3234572', 4, 'IT Support Specialist', '2021-10-01', '1993-06-07', encode('234-56-7893'::bytea, 'base64'), 52000.00, 'active'),
    ('EMP-033', 'Dex', 'Timmerman', 'dex.timmerman@innovatech.nl', '+31-30-3234573', 4, 'Database Administrator', '2020-12-15', '1989-01-23', encode('345-67-8904'::bytea, 'base64'), 78000.00, 'active'),
    ('EMP-034', 'Luna', 'Bosch', 'luna.bosch@innovatech.nl', '+31-30-3234574', 4, 'Cloud Engineer', '2021-05-22', '1991-10-11', encode('456-78-9015'::bytea, 'base64'), 82000.00, 'active'),
    ('EMP-035', 'Sam', 'van den Heuvel', 'sam.vandenheuvel@innovatech.nl', '+31-30-3234575', 4, 'IT Support Technician', '2022-02-28', '1994-07-29', encode('567-89-0126'::bytea, 'base64'), 48000.00, 'active');

-- Additional employees across departments for diversity
INSERT INTO employees (employee_number, first_name, last_name, email, phone, department_id, job_title, hire_date, birth_date, ssn_encrypted, salary, status) VALUES
    ('EMP-036', 'Nina', 'Postma', 'nina.postma@innovatech.nl', '+31-20-1234580', 1, 'Product Manager', '2019-12-01', '1986-02-14', encode('678-90-1237'::bytea, 'base64'), 90000.00, 'active'),
    ('EMP-037', 'Owen', 'Koster', 'owen.koster@innovatech.nl', '+31-20-1234581', 1, 'UX Designer', '2020-08-10', '1990-05-05', encode('789-01-2348'::bytea, 'base64'), 72000.00, 'active'),
    ('EMP-038', 'Evi', 'Blom', 'evi.blom@innovatech.nl', '+31-20-1234582', 1, 'Technical Writer', '2021-07-05', '1992-09-18', encode('890-12-3459'::bytea, 'base64'), 58000.00, 'active'),
    ('EMP-039', 'Hugo', 'van Beek', 'hugo.vanbeek@innovatech.nl', '+31-10-1234573', 2, 'Training Specialist', '2020-11-15', '1988-11-11', encode('901-23-4570'::bytea, 'base64'), 60000.00, 'active'),
    ('EMP-040', 'Liv', 'de Wit', 'liv.dewit@innovatech.nl', '+31-20-2234574', 3, 'Tax Consultant', '2019-05-20', '1984-03-08', encode('012-34-5681'::bytea, 'base64'), 85000.00, 'active'),
    ('EMP-041', 'Mees', 'Kramer', 'mees.kramer@innovatech.nl', '+31-20-2234575', 3, 'Auditor', '2021-09-12', '1990-06-24', encode('123-45-6783'::bytea, 'base64'), 68000.00, 'active'),
    ('EMP-042', 'Roos', 'van Vliet', 'roos.vanvliet@innovatech.nl', '+31-30-3234576', 4, 'IT Project Manager', '2019-03-25', '1985-08-16', encode('234-56-7894'::bytea, 'base64'), 92000.00, 'active'),
    ('EMP-043', 'Olivier', 'Schouten', 'olivier.schouten@innovatech.nl', '+31-30-3234577', 4, 'DevOps Lead', '2018-10-08', '1983-12-02', encode('345-67-8905'::bytea, 'base64'), 98000.00, 'active'),
    ('EMP-044', 'Yara', 'van Dijk', 'yara.vandijk@innovatech.nl', '+31-20-1234583', 1, 'Scrum Master', '2020-04-18', '1989-07-21', encode('456-78-9016'::bytea, 'base64'), 75000.00, 'active'),
    ('EMP-045', 'Lars', 'Evers', 'lars.evers@innovatech.nl', '+31-20-1234584', 1, 'Business Analyst', '2021-02-22', '1991-04-09', encode('567-89-0127'::bytea, 'base64'), 70000.00, 'active'),
    ('EMP-046', 'Sophie', 'Vermeulen', 'sophie.vermeulen@innovatech.nl', '+31-10-1234574', 2, 'Employee Relations Specialist', '2020-06-30', '1987-10-26', encode('678-90-1238'::bytea, 'base64'), 62000.00, 'active'),
    ('EMP-047', 'Finn', 'van Doorn', 'finn.vandoorn@innovatech.nl', '+31-20-2234576', 3, 'Procurement Specialist', '2021-11-08', '1992-01-15', encode('789-01-2349'::bytea, 'base64'), 58000.00, 'active'),
    ('EMP-048', 'Noor', 'Bakker', 'noor.bakker@innovatech.nl', '+31-30-3234578', 4, 'Information Security Analyst', '2020-09-22', '1988-05-12', encode('890-12-3460'::bytea, 'base64'), 80000.00, 'active'),
    ('EMP-049', 'Bas', 'Vink', 'bas.vink@innovatech.nl', '+31-20-1234585', 1, 'Software Engineer', '2022-05-15', '1994-03-03', encode('901-23-4571'::bytea, 'base64'), 68000.00, 'active'),
    ('EMP-050', 'Esmee', 'van der Heijden', 'esmee.vanderheijden@innovatech.nl', '+31-20-1234586', 1, 'Junior DevOps Engineer', '2022-08-01', '1996-11-20', encode('012-34-5682'::bytea, 'base64'), 55000.00, 'active');

-- Some terminated/inactive employees for realistic data
INSERT INTO employees (employee_number, first_name, last_name, email, phone, department_id, job_title, hire_date, birth_date, ssn_encrypted, salary, status) VALUES
    ('EMP-051', 'Mark', 'Jansen', 'mark.jansen@innovatech.nl', '+31-20-1234587', 1, 'Software Engineer', '2019-01-10', '1987-06-15', encode('123-45-6784'::bytea, 'base64'), 70000.00, 'terminated'),
    ('EMP-052', 'Emily', 'de Vries', 'emily.devries@innovatech.nl', '+31-10-1234575', 2, 'HR Assistant', '2020-03-15', '1993-09-22', encode('234-56-7895'::bytea, 'base64'), 45000.00, 'terminated'),
    ('EMP-053', 'Daniel', 'Smits', 'daniel.smits@innovatech.nl', '+31-30-3234579', 4, 'IT Support', '2021-01-05', '1995-02-11', encode('345-67-8906'::bytea, 'base64'), 46000.00, 'inactive');

-- Update department managers
UPDATE departments SET manager_id = 1 WHERE name = 'Engineering';   -- Lars van der Berg
UPDATE departments SET manager_id = 14 WHERE name = 'HR';           -- Anna Meijer
UPDATE departments SET manager_id = 20 WHERE name = 'Finance';      -- Pieter Brouwer
UPDATE departments SET manager_id = 27 WHERE name = 'IT';           -- Robin van der Meer

-- Update employee managers (reporting structure)
UPDATE employees SET manager_id = 1 WHERE id IN (2, 3, 4, 9, 36, 37);        -- Engineering team reports to Lars
UPDATE employees SET manager_id = 9 WHERE id IN (5, 6, 7, 8, 10, 11, 12, 13, 44, 45, 49, 50);  -- Engineers report to Architect
UPDATE employees SET manager_id = 14 WHERE id IN (15, 16, 17, 18, 19, 39, 46);  -- HR team reports to Anna
UPDATE employees SET manager_id = 20 WHERE id IN (21, 22, 23, 24, 25, 26, 40, 41, 47);  -- Finance team reports to Pieter
UPDATE employees SET manager_id = 27 WHERE id IN (28, 42, 43);                 -- IT leads report to Robin
UPDATE employees SET manager_id = 28 WHERE id IN (29, 30, 31, 32, 33, 34, 35, 48);  -- IT team reports to IT Manager

-- Insert sample access logs (GDPR audit trail)
INSERT INTO access_logs (employee_id, resource, action, status, ip_address, user_agent) VALUES
    (1, '/api/employees', 'READ', 'success', '10.100.1.25', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (2, '/api/employees/2', 'UPDATE', 'success', '10.100.1.32', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'),
    (14, '/api/employees', 'READ', 'success', '10.100.1.45', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (14, '/api/employees/15', 'UPDATE', 'success', '10.100.1.45', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (20, '/api/finance/reports', 'READ', 'success', '10.100.1.78', 'Mozilla/5.0 (X11; Linux x86_64)'),
    (27, '/api/systems/logs', 'READ', 'success', '10.100.1.92', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (3, '/api/employees/51', 'DELETE', 'denied', '10.100.1.33', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'),
    (5, '/api/deployments', 'CREATE', 'success', '10.100.1.28', 'curl/7.68.0'),
    (9, '/api/architecture/diagrams', 'READ', 'success', '10.100.1.41', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (15, '/api/employees', 'READ', 'success', '10.100.1.47', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'),
    (21, '/api/finance/budgets', 'UPDATE', 'success', '10.100.1.81', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (28, '/api/systems/users', 'CREATE', 'success', '10.100.1.95', 'Mozilla/5.0 (X11; Linux x86_64)'),
    (1, '/api/employees', 'EXPORT', 'success', '10.100.1.25', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (14, '/api/employees/sensitive', 'READ', 'denied', '10.100.1.45', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (6, '/api/tests/results', 'CREATE', 'success', '10.100.1.35', 'pytest/7.4.0'),
    (31, '/api/security/scans', 'READ', 'success', '10.100.1.88', 'Mozilla/5.0 (X11; Linux x86_64)'),
    (42, '/api/projects', 'UPDATE', 'success', '10.100.1.99', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
    (11, '/api/services/deploy', 'CREATE', 'success', '10.100.1.38', 'kubectl/1.28.0'),
    (34, '/api/cloud/resources', 'READ', 'success', '10.100.1.97', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'),
    (16, '/api/candidates', 'CREATE', 'success', '10.100.1.49', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

-- Insert some leave requests
INSERT INTO leave_requests (employee_id, leave_type, start_date, end_date, status, approver_id, reason) VALUES
    (2, 'vacation', '2024-07-15', '2024-07-26', 'approved', 1, 'Summer vacation'),
    (3, 'sick', '2024-06-10', '2024-06-12', 'approved', 9, 'Flu'),
    (15, 'vacation', '2024-08-01', '2024-08-15', 'approved', 14, 'Family trip'),
    (22, 'personal', '2024-06-20', '2024-06-21', 'approved', 20, 'Personal matters'),
    (29, 'vacation', '2024-09-05', '2024-09-12', 'pending', 28, 'Holiday'),
    (5, 'parental', '2024-10-01', '2024-12-31', 'approved', 9, 'Parental leave'),
    (37, 'vacation', '2024-11-20', '2024-11-24', 'pending', 1, 'Long weekend');

-- Insert equipment assignments
INSERT INTO equipment (employee_id, equipment_type, brand, model, serial_number, assigned_date, status) VALUES
    (1, 'Laptop', 'Apple', 'MacBook Pro 16"', 'MBP-2023-001', '2023-01-15', 'assigned'),
    (2, 'Laptop', 'Dell', 'XPS 15', 'DELL-2023-002', '2023-03-10', 'assigned'),
    (3, 'Laptop', 'Lenovo', 'ThinkPad X1', 'LEN-2023-003', '2023-06-22', 'assigned'),
    (14, 'Laptop', 'Apple', 'MacBook Air 13"', 'MBA-2023-004', '2023-03-01', 'assigned'),
    (20, 'Laptop', 'HP', 'EliteBook 840', 'HP-2023-005', '2023-06-01', 'assigned'),
    (27, 'Laptop', 'Dell', 'Latitude 7420', 'DELL-2023-006', '2023-04-10', 'assigned'),
    (5, 'Monitor', 'Dell', 'UltraSharp 27"', 'MON-2023-007', '2023-09-01', 'assigned'),
    (9, 'Monitor', 'LG', '34" Ultrawide', 'LG-2023-008', '2023-11-05', 'assigned'),
    (51, 'Laptop', 'HP', 'ProBook 450', 'HP-2022-009', '2022-01-10', 'returned'),
    (52, 'Laptop', 'Lenovo', 'ThinkPad E14', 'LEN-2022-010', '2022-03-15', 'returned');
