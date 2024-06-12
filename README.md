# Payroll System

This repository contains the source code and database schema for the Payroll System project, developed as part of the Database Foundations course. The system provides comprehensive payroll management, including employee management, allowance and deduction tracking, payroll processing, and user activity logging.

## Table of Contents

- [Overview](#overview)
- [Database Design](#database-design)
- [Technologies Used](#technologies-used)
- [Usage](#usage)
- [API Endpoints](#api-endpoints)
- [Procedures](#procedures)
- [Views](#views)
- [Triggers](#triggers)
- [Data Population](#data-population)
- [Testing](#testing)
- [Results](#results)
- [Conclusions](#conclusions)
- [Webgraphy](#webgraphy)

## Overview

Trimeca S.A. is a manufacturing company seeking an efficient and reliable payroll system. This project includes a PostgreSQL database designed to manage payroll, a FastAPI web service to handle data operations, and various scripts for database population and testing. The system includes features such as employee management, payroll calculation, allowance and deduction tracking, and user activity logging.

## Database Design

The database consists of several tables including:
- Employee
- Position
- Department
- Allowance
- Deduction
- Payroll
- Payslip
- Role
- UserActivityLog
- Status
- EmployeeAllowances
- EmployeeDeductions
- EmployeeExtraHours
- PayrollType

## Technologies Used

### Web Services
- FastAPI
- SQLAlchemy
- Pydantic
- Uvicorn
- Psycopg2-binary

### Database Creation
- PostgreSQL
- DBeaver

Usage
To run the FastAPI application, execute the following command:

bash
Copiar código
uvicorn main:app --reload
The API documentation will be available at http://127.0.0.1:8000/docs.

API Endpoints
Employees
GET /employees_with_position_and_department
GET /employees/{employee_uuid}/allowances
GET /employees/{employee_uuid}/deductions
GET /employees/{employee_uuid}/payroll_summary
GET /employees/{employee_uuid}/payment_history
GET /employees/extra_hours
GET /employees/status_counts
POST /employees/add
PUT /employees/{employee_uuid}/position
PUT /employees/{employee_uuid}/salary
PUT /employees/{employee_uuid}/status
PUT /employees/{employee_uuid}/email
PUT /employees/{employee_uuid}/phone
DELETE /employees/{employee_uuid}
Users
GET /users_with_roles
GET /users/role_counts
POST /users/add
PUT /users/{user_uuid}/role
DELETE /users/{user_uuid}
Payrolls
GET /payrolls
GET /payrolls/compensations_deductions
POST /payrolls/add
DELETE /payrolls/{date_created}
DELETE /payroll/date_range
Departments
GET /departments/report
POST /departments/add
DELETE /departments/{department_id}
Allowances
POST /allowances/add
DELETE /employee_allowances/{allowance_id}
Deductions
POST /deductions/add
DELETE /employee_deductions/{deduction_id}
Employee Extra Hours
POST /employee_extra_hours/add
PUT /employees/extra_hours/{extra_hours_id}
DELETE /employee_extra_hours/{extra_hours_id}
User Activity Log
POST /user_activity_log/add
Procedures
CALL list_employees_with_roles()
CALL count_users_per_role()
CALL count_employees_per_status()
Views
employee_payroll_summary
department_employee_summary
user_activity_summary
department_salary_budget
employee_attendance_summary
Triggers
payroll_status_update
employee_changes_log
check_negative_salary
cascade_delete_employee_records
Data Population
The data.py script is used to populate the database with dummy data. It uses the Faker library to generate realistic data for testing purposes.

Testing
The API endpoints have been tested using Postman. Various test cases have been created to ensure the correct functionality of the endpoints, including edge cases and error handling.

Results
The Payroll System project successfully implements a comprehensive solution for payroll management. The database schema supports various operations such as employee management, payroll processing, allowance and deduction tracking, and user activity logging. The FastAPI web service provides a robust interface for interacting with the database.

Conclusions
The Payroll System project demonstrates the importance of a well-designed database and a reliable web service for managing payroll operations. The integration of FastAPI with PostgreSQL provides a powerful and efficient solution. Future improvements could include additional features such as advanced reporting and analytics.

Webgraphy
FastAPI. (n.d.). Retrieved from https://fastapi.tiangolo.com/
SQLAlchemy. (n.d.). Retrieved from https://www.sqlalchemy.org/
PostgreSQL. (n.d.). Retrieved from https://www.postgresql.org/
Faker. (n.d.). Retrieved from https://faker.readthedocs.io/en/master/
