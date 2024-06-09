from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List
from datetime import date
from sqlalchemy import create_engine, text
import random
import uuid

from models import Employee, Allowance, Deduction, Payroll, Payslip, User, Department, UserActivityLog, Position, EmployeeExtraHours,EmployeeAllowance,EmployeeDeduction

app = FastAPI(title = "Payroll System", description="This is the Final Project for Database Foundations", version="0.0")

db_connection = create_engine("postgresql://ud_admin:HDjZLf03nK69O6IGs4Rg@localhost:5432/ud_DBFoundations_project")
db_client = db_connection = db_connection.connect()

@app.get("/")
def healthcheck():
    """This is a service to validate web API is up and running."""
    return {"status": "ok"}

# Employees

@app.get("/employees_with_position_and_department")
def get_employees_with_position_and_department():
    query = """
    SELECT e."name" as employee_name, e.lastname, e.email, e.phone, p.name as position_name, d.name as department_name
    FROM public.employee e 
    JOIN public."Position" p ON e.position_fk = p.id 
    JOIN public.department d ON p.department_fk = d.id;
    """
    result = db_client.execute(query).fetchall()
    return [dict(row) for row in result]

@app.get("/employees/{employee_uuid}/allowances")
def get_allowances_of_employee(employee_uuid: str):
    try:
        employee_uuid = uuid.UUID(employee_uuid)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid UUID format")
    
    query = """
    SELECT e.name as employee_name, a.name as allowance_name, ea.amount, ea.effective_date 
    FROM public.employee_allowances ea 
    JOIN public.employee e ON ea.employee_fk = e."UUID" 
    JOIN public.allowance a ON ea.allowance_fk = a.id 
    WHERE ea.employee_fk = :employee_uuid;
    """
    result = db_client.execute(text(query), {"employee_uuid": str(employee_uuid)}).fetchall()
    return [dict(row) for row in result]

@app.get("/employees/{employee_uuid}/deductions")
def get_deductions_of_employee(employee_uuid: str):
    query = """
    SELECT e.name as employee_name, d.name as deduction_name, ed.amount, ed.effective_date
    FROM public.employee_deductions ed 
    JOIN public.employee e ON ed.employee_fk = e."UUID" 
    JOIN public.deduction d ON ed.deduction_fk = d.id 
    WHERE ed.employee_fk = :employee_uuid;
    """
    result = db_client.execute(text(query), {"employee_uuid": employee_uuid}).fetchall()
    return [dict(row) for row in result]

@app.get("/payrolls")
def get_payrolls_in_date_range(start_date: str, end_date: str):
    query = """
    SELECT p.id as payroll_id, pt.name as payroll_type, p.reference_number, p.status, p.date_from, p.date_to, p.date_created
    FROM public.payroll p 
    JOIN public.payroll_type pt ON p.paroll_type_fk = pt.id 
    WHERE p.date_from >= :start_date AND p.date_to <= :end_date;
    """
    result = db_client.execute(text(query), {"start_date": start_date, "end_date": end_date}).fetchall()
    return [dict(row) for row in result]

@app.get("/employees/{employee_uuid}/payroll_summary")
def get_employee_payroll_summary(employee_uuid: str):
    query = """
    SELECT e.name as employee_name, ps.present, ps.absent, ps.salary, ps.allowance_amount, ps.net, ps.date_created
    FROM public.payslip ps 
    JOIN public.employee e ON ps.employee_fk = e."UUID" 
    WHERE ps.employee_fk = :employee_uuid;
    """
    result = db_client.execute(text(query), {"employee_uuid": employee_uuid}).fetchall()
    return [dict(row) for row in result]

@app.get("/departments/report")
def get_departments_report():
    query = """
    SELECT d.id as department_id, d.name as department_name, count(e."UUID") as number_of_employees, avg(e.salary) as average_salary
    FROM public.department d 
    JOIN public."Position" p ON d.id = p.department_fk 
    JOIN public.employee e ON p.id = e.position_fk 
    GROUP BY d.id, d.name 
    ORDER BY number_of_employees DESC;
    """
    result = db_client.execute(query).fetchall()
    return [dict(row) for row in result]

@app.get("/employees/extra_hours")
def get_employees_with_extra_hours(start_date: str, end_date: str):
    query = """
    SELECT e.name as employee_name, sum(eh.hours) as total_hours, sum(eh.amount) as total_amount, min(eh.effective_date) as period_start, max(eh.effective_date) as period_end
    FROM public.employee_extra_hours eh 
    JOIN public.employee e ON eh.employee_fk = e."UUID" 
    WHERE eh.effective_date >= :start_date AND eh.effective_date <= :end_date
    GROUP BY e."UUID", e.name 
    ORDER BY total_amount DESC;
    """
    result = db_client.execute(text(query), {"start_date": start_date, "end_date": end_date}).fetchall()
    return [dict(row) for row in result]

@app.get("/payrolls/compensations_deductions")
def get_compensations_and_deductions():
    query = """
    SELECT pt.name as payroll_type, e.name as employee_name, 
           sum(CASE WHEN ea.amount IS NULL THEN 0 ELSE ea.amount END) as total_allowances, 
           sum(CASE WHEN ed.amount IS NULL THEN 0 ELSE ed.amount END) as total_deductions
    FROM public.payroll p 
    JOIN public.payslip ps ON p.id = ps.payroll_fk 
    JOIN public.employee e ON ps.employee_fk = e."UUID" 
    LEFT JOIN public.employee_allowances ea ON e."UUID" = ea.employee_fk AND ea.payroll_type_fk = p.paroll_type_fk 
    LEFT JOIN public.employee_deductions ed ON e."UUID" = ed.employee_fk AND ed.payroll_type_fk = p.paroll_type_fk 
    JOIN public.payroll_type pt ON p.paroll_type_fk = pt.id 
    GROUP BY pt.name, e."UUID", e.name
    ORDER BY pt.name, e.name;
    """
    result = db_client.execute(query).fetchall()
    return [dict(row) for row in result]

@app.get("/employees/{employee_uuid}/payment_history")
def get_employee_payment_history(employee_uuid: str):
    query = """
    SELECT e.name as employee_name, ps.present, ps.absent, ps.salary, ps.allowance_amount, ps.deduction_amount, ps.net, p.date_from, p.date_to, ps.date_created
    FROM public.payslip ps 
    JOIN public.employee e ON ps.employee_fk = e."UUID" 
    JOIN public.payroll p ON ps.payroll_fk = p.id 
    WHERE ps.employee_fk = :employee_uuid
    ORDER BY p.date_from DESC;
    """
    result = db_client.execute(text(query), {"employee_uuid": employee_uuid}).fetchall()
    return [dict(row) for row in result]

@app.get("/users_with_roles")
def get_users_with_roles():
    query = """
    SELECT u.name as user_name, u.username, r.name as role_name
    FROM public."User" u 
    JOIN public."Role" r ON u.role_fk = r.id 
    ORDER BY u.name;
    """
    result = db_client.execute(query).fetchall()
    return [dict(row) for row in result]

@app.get("/users/role_counts")
def get_user_counts_per_role():
    query = """
    SELECT r.name as role_name, count(u."UUID") as user_count
    FROM public."User" u 
    JOIN public."Role" r ON u.role_fk = r.id 
    GROUP BY r.name 
    ORDER BY user_count DESC;
    """
    result = db_client.execute(query).fetchall()
    return [dict(row) for row in result]

@app.get("/employees/status_counts")
def get_employee_counts_per_status():
    query = """
    SELECT s.name as payroll_status, count(e."UUID") as employee_count
    FROM public.employee e 
    JOIN public.status s ON e.status_fk = s.id 
    GROUP BY s.name 
    ORDER BY employee_count DESC;
    """
    result = db_client.execute(query).fetchall()
    return [dict(row) for row in result]

@app.put("/employees/{employee_uuid}/position")
def update_employee_position(employee_uuid: str, position_fk: int):
    query = """
    UPDATE public.employee 
    SET position_fk = :position_fk 
    WHERE "UUID" = :employee_uuid 
    RETURNING *;
    """
    result = db_client.execute(text(query), {"employee_uuid": employee_uuid, "position_fk": position_fk}).fetchone()
    db_client.commit()
    if result is None:
        raise HTTPException(status_code=404, detail="Employee not found")
    return dict(result)

@app.put("/employees/{employee_uuid}/salary")
def update_employee_salary(employee_uuid: str, salary: float):
    query = """
    UPDATE public.employee 
    SET salary = :salary 
    WHERE "UUID" = :employee_uuid 
    RETURNING *;
    """
    result = db_client.execute(text(query), {"employee_uuid": employee_uuid, "salary": salary}).fetchone()
    db_client.commit()
    if result is None:
        raise HTTPException(status_code=404, detail="Employee not found")
    return dict(result)

@app.put("/employees/{employee_uuid}/status")
def update_employee_status(employee_uuid: str, status_fk: int):
    query = """
    UPDATE public.employee 
    SET status_fk = :status_fk 
    WHERE "UUID" = :employee_uuid 
    RETURNING *;
    """
    result = db_client.execute(text(query), {"employee_uuid": employee_uuid, "status_fk": status_fk}).fetchone()
    db_client.commit()
    if result is None:
        raise HTTPException(status_code=404, detail="Employee not found")
    return dict(result)

@app.put("/employees/{employee_uuid}/email")
def update_employee_email(employee_uuid: str, email: str):
    query = """
    UPDATE public.employee 
    SET email = :email 
    WHERE "UUID" = :employee_uuid 
    RETURNING *;
    """
    result = db_client.execute(text(query), {"employee_uuid": employee_uuid, "email": email}).fetchone()
    db_client.commit()
    if result is None:
        raise HTTPException(status_code=404, detail="Employee not found")
    return dict(result)

@app.put("/users/{user_uuid}/role")
def update_user_role(user_uuid: str, role_fk: int):
    query = """
    UPDATE public."User" 
    SET role_fk = :role_fk 
    WHERE "UUID" = :user_uuid 
    RETURNING *;
    """
    result = db_client.execute(text(query), {"user_uuid": user_uuid, "role_fk": role_fk}).fetchone()
    db_client.commit()
    if result is None:
        raise HTTPException(status_code=404, detail="User not found")
    return dict(result)

@app.put("/employees/extra_hours/{extra_hours_id}")
def update_employee_extra_hours(extra_hours_id: int, hours: int, amount: float):
    query = """
    UPDATE public.employee_extra_hours 
    SET hours = :hours, amount = :amount 
    WHERE id = :extra_hours_id 
    RETURNING *;
    """
    result = db_client.execute(text(query), {"extra_hours_id": extra_hours_id, "hours": hours, "amount": amount}).fetchone()
    db_client.commit()
    if result is None:
        raise HTTPException(status_code=404, detail="Record not found")
    return dict(result)

@app.put("/employees/{employee_uuid}/phone")
def update_employee_phone(employee_uuid: str, phone: str):
    query = """
    UPDATE public.employee 
    SET phone = :phone 
    WHERE "UUID" = :employee_uuid 
    RETURNING *;
    """
    result = db_client.execute(text(query), {"employee_uuid": employee_uuid, "phone": phone}).fetchone()
    db_client.commit()
    if result is None:
        raise HTTPException(status_code=404, detail="Employee not found")
    return dict(result)

@app.put("/positions/{position_id}/title")
def update_position_title(position_id: int, title: str):
    query = """
    UPDATE public."Position" 
    SET name = :title 
    WHERE id = :position_id 
    RETURNING *;
    """
    result = db_client.execute(text(query), {"position_id": position_id, "title": title}).fetchone()
    db_client.commit()
    if result is None:
        raise HTTPException(status_code=404, detail="Position not found")
    return dict(result)

@app.delete("/employees/{employee_uuid}")
def delete_employee(employee_uuid: str):
    try:
        employee_uuid = uuid.UUID(employee_uuid)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid UUID format")

    query = "DELETE FROM public.employee WHERE UUID = :employee_uuid"
    result = db_client.execute(text(query), {"employee_uuid": str(employee_uuid)})
    db_client.commit()
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Employee not found")
    return {"status": "deleted"}

@app.delete("/employee_allowances/{allowance_id}")
def delete_employee_allowance(allowance_id: int):
    query = "DELETE FROM public.employee_allowances WHERE id = :allowance_id"
    db_client.execute(text(query), {"allowance_id": allowance_id})
    db_client.commit()
    return {"status": "deleted"}

@app.delete("/users/{user_uuid}")
def delete_user(user_uuid: str):
    query = "DELETE FROM public.\"User\" WHERE UUID = :user_uuid"
    db_client.execute(text(query), {"user_uuid": user_uuid})
    db_client.commit()
    return {"status": "deleted"}

@app.delete("/departments/{department_id}")
def delete_department(department_id: int):
    # Delete employees first
    query = """
    DELETE FROM public.employee 
    WHERE position_fk IN (SELECT id FROM public."Position" WHERE department_fk = :department_id);
    """
    db_client.execute(text(query), {"department_id": department_id})
    
    # Delete positions
    query = "DELETE FROM public.\"Position\" WHERE department_fk = :department_id"
    db_client.execute(text(query), {"department_id": department_id})
    
    # Finally, delete the department
    query = "DELETE FROM public.department WHERE id = :department_id"
    db_client.execute(text(query), {"department_id": department_id})
    
    db_client.commit()
    return {"status": "deleted"}

@app.delete("/employee_deductions/{deduction_id}")
def delete_employee_deduction(deduction_id: int):
    query = "DELETE FROM public.employee_deductions WHERE id = :deduction_id"
    db_client.execute(text(query), {"deduction_id": deduction_id})
    db_client.commit()
    return {"status": "deleted"}

@app.delete("/employee_extra_hours/{extra_hours_id}")
def delete_employee_extra_hours(extra_hours_id: int):
    query = "DELETE FROM public.employee_extra_hours WHERE id = :extra_hours_id"
    db_client.execute(text(query), {"extra_hours_id": extra_hours_id})
    db_client.commit()
    return {"status": "deleted"}

@app.delete("/payrolls/{date_created}")
def delete_old_payrolls(date_created: int):
    query = "DELETE FROM public.payroll WHERE date_created = :date_created"
    db_client.execute(text(query), {"date_created": date_created})
    db_client.commit()
    return {"status": "deleted"}

@app.delete("/payrolls/date_range")
def delete_payrolls_in_date_range(start_date: str, end_date: str):
    query = """
    DELETE FROM public.payroll 
    WHERE date_from >= :start_date AND date_to <= :end_date
    """
    db_client.execute(text(query), {"start_date": start_date, "end_date": end_date})
    db_client.commit()
    return {"status": "deleted"}

@app.post("/positions/add", status_code=201)
def add_position(position: Position):
    query = text('''
        INSERT INTO public."Position" (name, description, department_fk)
        VALUES (:name, :description, :department_fk)
    ''')
    db_client.execute(query, {
        'name': position.name,
        'description': position.description,
        'department_fk': position.department_fk
    })
    db_client.commit()
    return {"status": "Position added"}

@app.post("/users/add", status_code=201)
def add_user(user: User):
    query = text('''
        INSERT INTO public."User" ("UUID", name, password, username, role_fk)
        VALUES (:UUID, :name, :password, :username, :role_fk)
    ''')
    db_client.execute(query, {
        'UUID': user.UUID,
        'name': user.name,
        'password': user.password,
        'username': user.username,
        'role_fk': user.role_fk
    })
    db_client.commit()
    return {"status": "User added"}

@app.post("/employees/add", status_code=201)
def add_employee(employee: Employee):
    user_check_query = text('SELECT COUNT(1) FROM public."User" WHERE "UUID" = :UUID')
    user_exists = db_client.execute(user_check_query, {'UUID': employee.UUID}).scalar()
    
    if not user_exists:
        raise HTTPException(status_code=404, detail="User not found, please add the user first.")

    query = text('''
        INSERT INTO public.employee ("UUID", employee_code, name, position_fk, lastname, email, status_fk, bank_account, salary, phone)
        VALUES (:UUID, :employee_code, :name, :position_fk, :lastname, :email, :status_fk, :bank_account, :salary, :phone)
    ''')
    db_client.execute(query, {
        'UUID': employee.UUID,
        'employee_code': employee.employee_code,
        'name': employee.name,
        'position_fk': employee.position_fk,
        'lastname': employee.lastname,
        'email': employee.email,
        'status_fk': employee.status_fk,
        'bank_account': employee.bank_account,
        'salary': employee.salary,
        'phone': employee.phone
    })
    db_client.commit()
    return {"status": "Employee added"}

@app.post("/allowances/add", status_code=201)
def add_allowance(allowance: Allowance):
    query = text('''
        INSERT INTO public.allowance (name, description)
        VALUES (:name, :description)
    ''')
    db_client.execute(query, {
        'name': allowance.name,
        'description': allowance.description
    })
    db_client.commit()
    return {"status": "Allowance added"}

@app.post("/deductions/add", status_code=201)
def add_deduction(deduction: Deduction):
    query = text('''
        INSERT INTO public.deduction (name, description)
        VALUES (:name, :description)
    ''')
    db_client.execute(query, {
        'name': deduction.name,
        'description': deduction.description
    })
    db_client.commit()
    return {"status": "Deduction added"}

@app.post("/employee_allowances/add", status_code=201)
def add_employee_allowance(employee_allowance: EmployeeAllowance):
    query = text('''
        INSERT INTO public.employee_allowances (employee_fk, allowance_fk, payroll_type_fk, effective_date, date_created, amount)
        VALUES (:employee_fk, :allowance_fk, :payroll_type_fk, :effective_date, :date_created, :amount)
    ''')
    db_client.execute(query, {
        'employee_fk': employee_allowance.employee_fk,
        'allowance_fk': employee_allowance.allowance_fk,
        'payroll_type_fk': employee_allowance.payroll_type_fk,
        'effective_date': employee_allowance.effective_date,
        'date_created': employee_allowance.date_created,
        'amount': employee_allowance.amount
    })
    db_client.commit()
    return {"status": "Employee allowance added"}

@app.post("/employee_deductions/add", status_code=201)
def add_employee_deduction(employee_deduction: EmployeeDeduction):
    query = text('''
        INSERT INTO public.employee_deductions (employee_fk, deduction_fk, payroll_type_fk, amount, effective_date, date_created)
        VALUES (:employee_fk, :deduction_fk, :payroll_type_fk, :amount, :effective_date, :date_created)
    ''')
    db_client.execute(query, {
        'employee_fk': employee_deduction.employee_fk,
        'deduction_fk': employee_deduction.deduction_fk,
        'payroll_type_fk': employee_deduction.payroll_type_fk,
        'amount': employee_deduction.amount,
        'effective_date': employee_deduction.effective_date,
        'date_created': employee_deduction.date_created
    })
    db_client.commit()
    return {"status": "Employee deduction added"}

@app.post("/employee_extra_hours/add", status_code=201)
def add_employee_extra_hours(employee_extra_hours: EmployeeExtraHours):
    query = text('''
        INSERT INTO public.employee_extra_hours (hours, amount, effective_date, date_created, employee_fk, payroll_type_fk)
        VALUES (:hours, :amount, :effective_date, :date_created, :employee_fk, :payroll_type_fk)
    ''')
    db_client.execute(query, {
        'hours': employee_extra_hours.hours,
        'amount': employee_extra_hours.amount,
        'effective_date': employee_extra_hours.effective_date,
        'date_created': employee_extra_hours.date_created,
        'employee_fk': employee_extra_hours.employee_fk,
        'payroll_type_fk': employee_extra_hours.payroll_type_fk
    })
    db_client.commit()
    return {"status": "Employee extra hours added"}

@app.post("/payrolls/add", status_code=201)
def add_payroll(payroll: Payroll):
    query = text('''
        INSERT INTO public.payroll (paroll_type_fk, reference_number, status, date_from, date_to, date_created)
        VALUES (:paroll_type_fk, :reference_number, :status, :date_from, :date_to, :date_created)
    ''')
    db_client.execute(query, {
        'paroll_type_fk': payroll.paroll_type_fk,
        'reference_number': payroll.reference_number,
        'status': payroll.status,
        'date_from': payroll.date_from,
        'date_to': payroll.date_to,
        'date_created': payroll.date_created
    })
    db_client.commit()
    return {"status": "Payroll added"}

@app.post("/payslips/add", status_code=201)
def add_payslip(payslip: Payslip):
    query = text('''
        INSERT INTO public.payslip (payroll_fk, employee_fk, present, absent, salary, allowance_amount, net, deduction_amount, date_created)
        VALUES (:payroll_fk, :employee_fk, :present, :absent, :salary, :allowance_amount, :net, :deduction_amount, :date_created)
    ''')
    db_client.execute(query, {
        'payroll_fk': payslip.payroll_fk,
        'employee_fk': payslip.employee_fk,
        'present': payslip.present,
        'absent': payslip.absent,
        'salary': payslip.salary,
        'allowance_amount': payslip.allowance_amount,
        'net': payslip.net,
        'deduction_amount': payslip.deduction_amount,
        'date_created': payslip.date_created
    })
    db_client.commit()
    return {"status": "Payslip added"}

@app.post("/departments/add", status_code=201)
def add_department(department: Department):
    query = text('''
        INSERT INTO public.department (name, description)
        VALUES (:name, :description)
    ''')
    db_client.execute(query, {
        'name': department.name,
        'description': department.description
    })
    db_client.commit()
    return {"status": "Department added"}

@app.post("/user_activity_log/add", status_code=201)
def add_user_activity_log(activity_log: UserActivityLog):
    query = text('''
        INSERT INTO public.user_activity_log (user_fk, action, action_timestamp)
        VALUES (:user_fk, :action, :action_timestamp)
    ''')
    db_client.execute(query, {
        'user_fk': activity_log.user_fk,
        'action': activity_log.action,
        'action_timestamp': activity_log.action_timestamp
    })
    db_client.commit()
    return {"status": "User activity log added"}