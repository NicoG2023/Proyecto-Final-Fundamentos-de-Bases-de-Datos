from pydantic import BaseModel, Field
from datetime import date
import uuid

class Employee(BaseModel):
    UUID: uuid.UUID
    employee_code: str = Field(max_length=10)
    name: str = Field(max_length=200)
    position_fk: int
    lastname: str = Field(max_length=200)
    email: str = Field(max_length=100)
    status_fk: int
    bank_account: str = Field(max_length=34)
    salary: float
    phone: str = Field(max_length=15)
    password: str=Field(max_length=50)
    role_fk: int

class Allowance(BaseModel):
    name: str = Field(max_length=80)
    description: str = Field(max_length=150)

class Deduction(BaseModel):
    name: str = Field(max_length=80)
    description: str = Field(max_length=150)

class Payroll(BaseModel):
    paroll_type_fk: int
    reference_number: str = Field(max_length=80)
    status: int
    date_from: date
    date_to: date
    date_created: int

class Payslip(BaseModel):
    payroll_fk: int
    employee_fk: uuid.UUID
    present: int
    absent: int
    salary: float
    allowance_amount: float
    net: float
    deduction_amount: float
    date_created: date

class Department(BaseModel):
    name: str = Field(max_length=60)
    description: str = Field(max_length=150)

class Position(BaseModel):
    name: str = Field(max_length=50)
    description: str = Field(max_length=150)
    department_fk: int


class UserActivityLog(BaseModel):
    employee_fk: uuid.UUID
    action: str
    action_timestamp: date

class EmployeeDeduction(BaseModel):
    employee_fk: uuid.UUID
    deduction_fk: int
    payroll_type_fk: int
    effective_date:str
    date_created: int
    amount: float

class EmployeeAllowance(BaseModel):
    employee_fk: uuid.UUID
    allowance_fk: int
    payroll_type_fk: int
    effective_date:str
    date_created: int
    amount: float

class EmployeeExtraHours(BaseModel):
    employee_fk: uuid.UUID
    hours: int
    payroll_type_fk: int
    effective_date: date
    date_created: int
    amount: float