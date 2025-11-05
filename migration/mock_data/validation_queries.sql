-- Validation Queries for HR Database
-- Case Study 3 - Data Integrity Checks

-- Check 1: Verify all departments have been created
SELECT 'Department Count Check' AS check_name, 
       COUNT(*) AS actual_count, 
       4 AS expected_count,
       CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END AS status
FROM departments;

-- Check 2: Verify employee count (should be at least 50 active + some inactive)
SELECT 'Employee Count Check' AS check_name,
       COUNT(*) AS total_count,
       COUNT(CASE WHEN status = 'active' THEN 1 END) AS active_count,
       COUNT(CASE WHEN status IN ('terminated', 'inactive') THEN 1 END) AS inactive_count
FROM employees;

-- Check 3: Verify all departments have managers assigned
SELECT 'Department Manager Check' AS check_name,
       d.name,
       d.manager_id,
       e.first_name || ' ' || e.last_name AS manager_name,
       CASE WHEN d.manager_id IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status
FROM departments d
LEFT JOIN employees e ON d.manager_id = e.id;

-- Check 4: Verify all employees have valid department assignments
SELECT 'Employee Department Check' AS check_name,
       COUNT(*) AS employees_with_department,
       COUNT(CASE WHEN department_id IS NULL THEN 1 END) AS without_department
FROM employees
WHERE status = 'active';

-- Check 5: Verify employee distribution across departments
SELECT 'Department Distribution' AS check_name,
       d.name AS department,
       COUNT(e.id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.status = 'active'
GROUP BY d.name
ORDER BY COUNT(e.id) DESC;

-- Check 6: Verify SSN encryption (should all have encrypted values)
SELECT 'SSN Encryption Check' AS check_name,
       COUNT(*) AS total_employees,
       COUNT(ssn_encrypted) AS with_encrypted_ssn,
       CASE WHEN COUNT(*) = COUNT(ssn_encrypted) THEN 'PASS' ELSE 'FAIL' END AS status
FROM employees;

-- Check 7: Verify access logs have been populated
SELECT 'Access Logs Check' AS check_name,
       COUNT(*) AS log_count,
       CASE WHEN COUNT(*) >= 10 THEN 'PASS' ELSE 'FAIL' END AS status
FROM access_logs;

-- Check 8: Verify leave requests
SELECT 'Leave Requests Check' AS check_name,
       COUNT(*) AS total_requests,
       COUNT(CASE WHEN status = 'approved' THEN 1 END) AS approved,
       COUNT(CASE WHEN status = 'pending' THEN 1 END) AS pending,
       COUNT(CASE WHEN status = 'rejected' THEN 1 END) AS rejected
FROM leave_requests;

-- Check 9: Verify equipment assignments
SELECT 'Equipment Check' AS check_name,
       COUNT(*) AS total_equipment,
       COUNT(CASE WHEN status = 'assigned' THEN 1 END) AS assigned,
       COUNT(CASE WHEN status = 'returned' THEN 1 END) AS returned
FROM equipment;

-- Check 10: Verify email uniqueness (no duplicates)
SELECT 'Email Uniqueness Check' AS check_name,
       COUNT(*) AS total_emails,
       COUNT(DISTINCT email) AS unique_emails,
       CASE WHEN COUNT(*) = COUNT(DISTINCT email) THEN 'PASS' ELSE 'FAIL' END AS status
FROM employees;

-- Check 11: Verify employee number uniqueness
SELECT 'Employee Number Uniqueness Check' AS check_name,
       COUNT(*) AS total_numbers,
       COUNT(DISTINCT employee_number) AS unique_numbers,
       CASE WHEN COUNT(*) = COUNT(DISTINCT employee_number) THEN 'PASS' ELSE 'FAIL' END AS status
FROM employees;

-- Check 12: Verify hire dates are in the past
SELECT 'Hire Date Validation Check' AS check_name,
       COUNT(*) AS total_employees,
       COUNT(CASE WHEN hire_date <= CURRENT_DATE THEN 1 END) AS valid_hire_dates,
       CASE WHEN COUNT(*) = COUNT(CASE WHEN hire_date <= CURRENT_DATE THEN 1 END) 
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM employees;

-- Check 13: Verify referential integrity (all manager_ids reference valid employees)
SELECT 'Manager Referential Integrity Check' AS check_name,
       COUNT(e1.id) AS employees_with_manager,
       COUNT(e2.id) AS valid_manager_references,
       CASE WHEN COUNT(e1.id) = COUNT(e2.id) THEN 'PASS' ELSE 'FAIL' END AS status
FROM employees e1
LEFT JOIN employees e2 ON e1.manager_id = e2.id
WHERE e1.manager_id IS NOT NULL;

-- Check 14: Salary range validation
SELECT 'Salary Range Check' AS check_name,
       MIN(salary) AS min_salary,
       MAX(salary) AS max_salary,
       AVG(salary)::NUMERIC(10,2) AS avg_salary,
       CASE WHEN MIN(salary) > 0 AND MAX(salary) < 200000 THEN 'PASS' ELSE 'FAIL' END AS status
FROM employees
WHERE status = 'active';

-- Check 15: Access logs have valid employee references
SELECT 'Access Log Referential Integrity' AS check_name,
       COUNT(al.id) AS total_logs,
       COUNT(e.id) AS valid_employee_refs,
       CASE WHEN COUNT(al.id) = COUNT(e.id) THEN 'PASS' ELSE 'FAIL' END AS status
FROM access_logs al
LEFT JOIN employees e ON al.employee_id = e.id;

-- Summary Report
SELECT '==================== VALIDATION SUMMARY ====================' AS summary;

SELECT 'Total Departments' AS metric, COUNT(*)::TEXT AS value FROM departments
UNION ALL
SELECT 'Total Employees', COUNT(*)::TEXT FROM employees
UNION ALL
SELECT 'Active Employees', COUNT(*)::TEXT FROM employees WHERE status = 'active'
UNION ALL
SELECT 'Terminated Employees', COUNT(*)::TEXT FROM employees WHERE status IN ('terminated', 'inactive')
UNION ALL
SELECT 'Access Log Entries', COUNT(*)::TEXT FROM access_logs
UNION ALL
SELECT 'Leave Requests', COUNT(*)::TEXT FROM leave_requests
UNION ALL
SELECT 'Equipment Items', COUNT(*)::TEXT FROM equipment;

-- Display sample data from each table
SELECT '==================== SAMPLE EMPLOYEES ====================' AS sample;
SELECT id, employee_number, first_name, last_name, email, job_title, 
       (SELECT name FROM departments WHERE id = employees.department_id) AS department
FROM employees
WHERE status = 'active'
LIMIT 10;

SELECT '==================== SAMPLE ACCESS LOGS ====================' AS sample;
SELECT id, 
       (SELECT first_name || ' ' || last_name FROM employees WHERE id = access_logs.employee_id) AS employee,
       resource, action, status, timestamp
FROM access_logs
ORDER BY timestamp DESC
LIMIT 10;
