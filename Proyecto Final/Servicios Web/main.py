from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from typing import List
from datetime import date
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
import uuid

from models import Employee, Allowance, Deduction, Payroll, Payslip, User, Department, UserActivityLog, Position, EmployeeExtraHours, EmployeeAllowance, EmployeeDeduction

app = FastAPI(title="Payroll System", description="This is the Final Project for Database Foundations", version="0.0")

db_connection = create_engine("postgresql://ud_admin:HDjZLf03nK69O6IGs4Rg@localhost:5432/ud_DBFoundations_project")
db_client = db_connection.connect()

@app.get("/")
def healthcheck():
    """This is a service to validate web API is up and running."""
    return {"status": "ok"}

# Employees
@app.get("/employees_with_position_and_department")
def get_employees_with_position_and_department():
    try:
        query = text('''
        SELECT e."name" as employee_name, e.lastname, e.email, e.phone, p.name as position_name, d.name as department_name
        FROM public.employee e 
        JOIN public."Position" p ON e.position_fk = p.id 
        JOIN public.department d ON p.department_fk = d.id;
        ''')
        result = db_client.execute(query)
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/employees/{employee_uuid}/allowances")
def get_allowances_of_employee(employee_uuid: str):
    try:
        query = text('''
        SELECT e.name as employee_name, a.name as allowance_name, ea.amount, ea.effective_date 
        FROM public.employee_allowances ea 
        JOIN public.employee e ON ea.employee_fk = e."UUID" 
        JOIN public.allowance a ON ea.allowance_fk = a.id 
        WHERE ea.employee_fk = :employee_uuid;
        ''')
        result = db_client.execute(query, {"employee_uuid": employee_uuid})
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/employees/{employee_uuid}/deductions")
def get_deductions_of_employee(employee_uuid: str):
    try:
        query = text('''
        SELECT e.name as employee_name, d.name as deduction_name, ed.amount, ed.effective_date
        FROM public.employee_deductions ed 
        JOIN public.employee e ON ed.employee_fk = e."UUID" 
        JOIN public.deduction d ON ed.deduction_fk = d.id 
        WHERE ed.employee_fk = :employee_uuid;
        ''')
        result = db_client.execute(query, {"employee_uuid": employee_uuid})
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/payrolls")
def get_payrolls_in_date_range(
    start_date: date = Query(..., description="Start date in the format YYYY-MM-DD"),
    end_date: date = Query(..., description="End date in the format YYYY-MM-DD"),
):
    try:
        query = text('''
        SELECT p.id as payroll_id, pt.name as payroll_type, p.reference_number, p.status, p.date_from, p.date_to, p.date_created
        FROM public.payroll p 
        JOIN public.payroll_type pt ON p.paroll_type_fk = pt.id 
        WHERE p.date_from >= :start_date AND p.date_to <= :end_date;
        ''')
        result = db_client.execute(query, {"start_date": start_date, "end_date": end_date})
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/employees/{employee_uuid}/payroll_summary")
def get_employee_payroll_summary(employee_uuid: str):
    try:
        query = text('''
        SELECT e.name as employee_name, ps.present, ps.absent, ps.salary, ps.allowance_amount, ps.net, ps.date_created
        FROM public.payslip ps 
        JOIN public.employee e ON ps.employee_fk = e."UUID" 
        WHERE ps.employee_fk = :employee_uuid;
        ''')
        result = db_client.execute(query, {"employee_uuid": employee_uuid})
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/departments/report")
def get_departments_report():
    try:
        query = text('''
        SELECT d.id as department_id, d.name as department_name, count(e."UUID") as number_of_employees, avg(e.salary) as average_salary
        FROM public.department d 
        JOIN public."Position" p ON d.id = p.department_fk 
        JOIN public.employee e ON p.id = e.position_fk 
        GROUP BY d.id, d.name 
        ORDER BY number_of_employees DESC;
        ''')
        result = db_client.execute(query)
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/employees/extra_hours")
def get_employees_with_extra_hours(
    start_date: str = Query(..., description="Start date in the format YYYY-MM-DD"),
    end_date: str = Query(..., description="End date in the format YYYY-MM-DD")
):
    try:
        query = text('''
        SELECT e.name as employee_name, sum(eh.hours) as total_hours, sum(eh.amount) as total_amount, min(eh.effective_date) as period_start, max(eh.effective_date) as period_end
        FROM public.employee_extra_hours eh 
        JOIN public.employee e ON eh.employee_fk = e."UUID" 
        WHERE eh.effective_date >= :start_date AND eh.effective_date <= :end_date
        GROUP BY e."UUID", e.name 
        ORDER BY total_amount DESC;
        ''')
        result = db_client.execute(query, {"start_date": start_date, "end_date": end_date})
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/payrolls/compensations_deductions")
def get_compensations_and_deductions():
    try:
        query = text('''
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
        ''')
        result = db_client.execute(query)
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/employees/{employee_uuid}/payment_history")
def get_employee_payment_history(employee_uuid: str):
    try:
        query = text('''
        SELECT e.name as employee_name, ps.present, ps.absent, ps.salary, ps.allowance_amount, ps.deduction_amount, ps.net, p.date_from, p.date_to, ps.date_created
        FROM public.payslip ps 
        JOIN public.employee e ON ps.employee_fk = e."UUID" 
        JOIN public.payroll p ON ps.payroll_fk = p.id 
        WHERE ps.employee_fk = :employee_uuid
        ORDER BY p.date_from DESC;
        ''')
        result = db_client.execute(query, {"employee_uuid": employee_uuid})
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users_with_roles")
def get_users_with_roles():
    try:
        query = text('''
        SELECT u.name as user_name, u.username, r.name as role_name
        FROM public."User" u 
        JOIN public."Role" r ON u.role_fk = r.id 
        ORDER BY u.name;
        ''')
        result = db_client.execute(query)
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users/role_counts")
def get_user_counts_per_role():
    try:
        query = text('''
        SELECT r.name as role_name, count(u."UUID") as user_count
        FROM public."User" u 
        JOIN public."Role" r ON u.role_fk = r.id 
        GROUP BY r.name 
        ORDER BY user_count DESC;
        ''')
        result = db_client.execute(query)
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/employees/status_counts")
def get_employee_counts_per_status():
    try:
        query = text('''
        SELECT s.name as payroll_status, count(e."UUID") as employee_count
        FROM public.employee e 
        JOIN public.status s ON e.status_fk = s.id 
        GROUP BY s.name 
        ORDER BY employee_count DESC;
        ''')
        result = db_client.execute(query)
        rows = result.fetchall()
        return [dict(row._mapping) for row in rows]
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

class PositionUpdate(BaseModel):
    position_fk: int

@app.put("/employees/{employee_uuid}/position")
def update_employee_position(employee_uuid: str, position_update: PositionUpdate):
    try:
        query = text("""
        UPDATE public.employee 
        SET position_fk = :position_fk 
        WHERE "UUID" = :employee_uuid 
        RETURNING *;
        """)
        result = db_client.execute(query, {"employee_uuid": employee_uuid, "position_fk": position_update.position_fk}).fetchone()
        db_client.commit()
        if result is None:
            raise HTTPException(status_code=404, detail="Employee not found")
        return dict(result._mapping)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

class SalaryUpdate(BaseModel):
    salary: float

@app.put("/employees/{employee_uuid}/salary")
def update_employee_salary(employee_uuid: str, salary_update: SalaryUpdate):
    try:
        query = text("""
        UPDATE public.employee 
        SET salary = :salary 
        WHERE "UUID" = :employee_uuid 
        RETURNING *;
        """)
        result = db_client.execute(query, {"employee_uuid": employee_uuid, "salary": salary_update.salary}).fetchone()
        db_client.commit()
        if result is None:
            raise HTTPException(status_code=404, detail="Employee not found")
        return dict(result._mapping)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))


class StatusUpdate(BaseModel):
    status_fk: int

@app.put("/employees/{employee_uuid}/status")
def update_employee_status(employee_uuid: str, status_update: StatusUpdate):
    try:
        query = text("""
        UPDATE public.employee 
        SET status_fk = :status_fk 
        WHERE "UUID" = :employee_uuid 
        RETURNING *;
        """)
        result = db_client.execute(query, {"employee_uuid": employee_uuid, "status_fk": status_update.status_fk}).fetchone()
        db_client.commit()
        if result is None:
            raise HTTPException(status_code=404, detail="Employee not found")
        return dict(result._mapping)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))


class EmailUpdate(BaseModel):
    email: str

@app.put("/employees/{employee_uuid}/email")
def update_employee_email(employee_uuid: str, email_update: EmailUpdate):
    try:
        query = text("""
        UPDATE public.employee 
        SET email = :email 
        WHERE "UUID" = :employee_uuid 
        RETURNING *;
        """)
        result = db_client.execute(query, {"employee_uuid": employee_uuid, "email": email_update.email}).fetchone()
        db_client.commit()
        if result is None:
            raise HTTPException(status_code=404, detail="Employee not found")
        return dict(result._mapping)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))


class RoleUpdate(BaseModel):
    role_fk: int

@app.put("/users/{user_uuid}/role")
def update_user_role(user_uuid: str, role_update: RoleUpdate):
    try:
        query = text("""
        UPDATE public."User" 
        SET role_fk = :role_fk 
        WHERE "UUID" = :user_uuid 
        RETURNING *;
        """)
        result = db_client.execute(query, {"user_uuid": user_uuid, "role_fk": role_update.role_fk}).fetchone()
        db_client.commit()
        if result is None:
            raise HTTPException(status_code=404, detail="User not found")
        return dict(result._mapping)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))


class ExtraHoursUpdate(BaseModel):
    hours: int
    amount: float

@app.put("/employees/extra_hours/{extra_hours_id}")
def update_employee_extra_hours(extra_hours_id: int, extra_hours_update: ExtraHoursUpdate):
    try:
        query = text("""
        UPDATE public.employee_extra_hours 
        SET hours = :hours, amount = :amount 
        WHERE id = :extra_hours_id 
        RETURNING *;
        """)
        result = db_client.execute(query, {"extra_hours_id": extra_hours_id, "hours": extra_hours_update.hours, "amount": extra_hours_update.amount}).fetchone()
        db_client.commit()
        if result is None:
            raise HTTPException(status_code=404, detail="Record not found")
        return dict(result._mapping)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))


class PhoneUpdate(BaseModel):
    phone: str

@app.put("/employees/{employee_uuid}/phone")
def update_employee_phone(employee_uuid: str, phone_update: PhoneUpdate):
    try:
        query = text("""
        UPDATE public.employee 
        SET phone = :phone 
        WHERE "UUID" = :employee_uuid 
        RETURNING *;
        """)
        result = db_client.execute(query, {"employee_uuid": employee_uuid, "phone": phone_update.phone}).fetchone()
        db_client.commit()
        if result is None:
            raise HTTPException(status_code=404, detail="Employee not found")
        return dict(result._mapping)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))


class PositionTitleUpdate(BaseModel):
    title: str

@app.put("/positions/{position_id}/title")
def update_position_title(position_id: int, title_update: PositionTitleUpdate):
    try:
        query = text("""
        UPDATE public."Position" 
        SET name = :title 
        WHERE id = :position_id 
        RETURNING *;
        """)
        result = db_client.execute(query, {"position_id": position_id, "title": title_update.title}).fetchone()
        db_client.commit()
        if result is None:
            raise HTTPException(status_code=404, detail="Position not found")
        return dict(result._mapping)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/employees/{employee_uuid}")
def delete_employee(employee_uuid: str):
    try:
        query = text('DELETE FROM public.employee WHERE "UUID" = :employee_uuid')
        result = db_client.execute(query, {"employee_uuid": employee_uuid})
        db_client.commit()
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Employee not found")
        return {"status": "deleted"}
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/employee_allowances/{allowance_id}")
def delete_employee_allowance(allowance_id: int):
    try:
        query = text('DELETE FROM public.employee_allowances WHERE id = :allowance_id')
        result = db_client.execute(query, {"allowance_id": allowance_id})
        db_client.commit()
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Employee allowance not found")
        return {"status": "deleted"}
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/users/{user_uuid}")
def delete_user(user_uuid: str):
    try:
        query = text('DELETE FROM public."User" WHERE "UUID" = :user_uuid')
        result = db_client.execute(query, {"user_uuid": user_uuid})
        db_client.commit()
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="User not found")
        return {"status": "deleted"}
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/departments/{department_id}")
def delete_department(department_id: int):
    try:
        # Delete employees first
        query = text('''
            DELETE FROM public.employee 
            WHERE position_fk IN (SELECT id FROM public."Position" WHERE department_fk = :department_id)
        ''')
        db_client.execute(query, {"department_id": department_id})
        
        # Delete positions
        query = text('DELETE FROM public."Position" WHERE department_fk = :department_id')
        db_client.execute(query, {"department_id": department_id})
        
        # Finally, delete the department
        query = text('DELETE FROM public.department WHERE id = :department_id')
        result = db_client.execute(query, {"department_id": department_id})
        
        db_client.commit()
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Department not found")
        return {"status": "deleted"}
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/employee_deductions/{deduction_id}")
def delete_employee_deduction(deduction_id: int):
    try:
        query = text('DELETE FROM public.employee_deductions WHERE id = :deduction_id')
        result = db_client.execute(query, {"deduction_id": deduction_id})
        db_client.commit()
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Employee deduction not found")
        return {"status": "deleted"}
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/employee_extra_hours/{extra_hours_id}")
def delete_employee_extra_hours(extra_hours_id: int):
    try:
        query = text('DELETE FROM public.employee_extra_hours WHERE id = :extra_hours_id')
        result = db_client.execute(query, {"extra_hours_id": extra_hours_id})
        db_client.commit()
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Employee extra hours not found")
        return {"status": "deleted"}
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/payrolls/{date_created}")
def delete_old_payrolls(date_created: int):
    try:
        query = text('''
            DELETE FROM public.payroll WHERE date_created = :date_created
        ''')
        result = db_client.execute(query, {"date_created": date_created})
        db_client.commit()
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="No payrolls found with the specified date created")
        return {"status": "deleted"}
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/payroll/date_range")
def delete_payrolls_in_date_range(
    start_date: str = Query(..., description="Start date in the format YYYY-MM-DD"),
    end_date: str = Query(..., description="End date in the format YYYY-MM-DD")
):
    try:
        # First, delete dependent records in the payslip table
        delete_payslips_query = text('''
            DELETE FROM public.payslip 
            WHERE payroll_fk IN (
                SELECT id FROM public.payroll 
                WHERE date_from >= :start_date AND date_to <= :end_date
            )
        ''')
        db_client.execute(delete_payslips_query, {"start_date": start_date, "end_date": end_date})

        # Then, delete records in the payroll table
        delete_payrolls_query = text('''
            DELETE FROM public.payroll 
            WHERE date_from >= :start_date AND date_to <= :end_date
        ''')
        result = db_client.execute(delete_payrolls_query, {"start_date": start_date, "end_date": end_date})

        db_client.commit()
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="No payrolls found in the specified date range")
        return {"status": "deleted"}
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=str(e))
