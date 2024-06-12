import psycopg2
import random
import uuid
from faker import Faker

conn = psycopg2.connect(
    dbname="ud_DBFoundations_project",
    user="ud_admin",
    password="HDjZLf03nK69O6IGs4Rg",
    host="localhost",  # Change as needed
    port="5432"  # Default port for PostgreSQL
)

cur = conn.cursor()
fake = Faker()

def truncate_table(table_name):
    cur.execute(f'TRUNCATE TABLE {table_name} RESTART IDENTITY CASCADE;')
    conn.commit()

def reset_sequence(sequence_name):
    cur.execute(f'ALTER SEQUENCE {sequence_name} RESTART WITH 1;')
    conn.commit()

# Truncate tables and reset sequences before inserting new data
truncate_table('public.employee_extra_hours')
truncate_table('public.employee_deductions')
truncate_table('public.employee_allowances')
truncate_table('public.payslip')
truncate_table('public.payroll')
truncate_table('public.employee')
truncate_table('public.department')
truncate_table('public."Position"')
truncate_table('public.allowance')
truncate_table('public.deduction')
truncate_table('public.payroll_type')
truncate_table('public.status')
truncate_table('public."Role"')
truncate_table('public.user_activity_log')

# Reset sequences manually
reset_sequence('public.employee_extra_hours_id_seq')
reset_sequence('public.employee_deductions_id_seq')
reset_sequence('public.employee_allowances_id_seq')
reset_sequence('public.payslip_id_seq')
reset_sequence('public.payroll_id_seq')
reset_sequence('public.department_id_seq')
reset_sequence('public."Position_id_seq"')
reset_sequence('public.allowance_id_seq')
reset_sequence('public.deduction_id_seq')
reset_sequence('public.payroll_type_id_seq')
reset_sequence('public.status_id_seq')
reset_sequence('public."Role_id_seq"')
reset_sequence('public.user_activity_log_id_seq')

# Continue with the insertion of test data
def truncate(value, max_length):
    return value if len(value) <= max_length else value[:max_length]

def create_departments(num):
    department_ids = []
    for _ in range(num):
        name = truncate(fake.company(), 60)
        description = truncate(fake.text(max_nb_chars=150), 150)
        cur.execute('''
            INSERT INTO public.department (id, name, description)
            VALUES (DEFAULT, %s, %s)
            RETURNING id;
        ''', (name, description))
        department_id = cur.fetchone()[0]
        department_ids.append(department_id)
        conn.commit()
    return department_ids

def create_positions(num, department_ids):
    position_ids = []
    for _ in range(num):
        name = truncate(fake.job(), 50)
        description = truncate(fake.text(max_nb_chars=150), 150)
        department_fk = random.choice(department_ids)
        cur.execute('''
            INSERT INTO public."Position" (id, name, description, department_fk)
            VALUES (DEFAULT, %s, %s, %s)
            RETURNING id;
        ''', (name, description, department_fk))
        position_id = cur.fetchone()[0]
        position_ids.append(position_id)
        conn.commit()
    return position_ids

def create_roles():
    roles = ['Admin', 'User']
    role_ids = []
    for role in roles:
        cur.execute('''
            INSERT INTO public."Role" (id, name)
            VALUES (DEFAULT, %s)
            RETURNING id;
        ''', (role,))
        role_id = cur.fetchone()[0]
        role_ids.append(role_id)
        conn.commit()
    return role_ids

def create_employees(num, position_ids, role_ids, status_ids):
    employee_uuids = []
    for _ in range(num):
        employee_uuid = str(uuid.uuid4())
        employee_code = truncate(fake.unique.ean(length=8), 10)
        name = truncate(fake.name(), 200)
        position_fk = random.choice(position_ids)
        lastname = truncate(fake.last_name(), 200)
        email = truncate(fake.email(), 100)
        status_fk = random.choice(status_ids)
        bank_account = fake.iban()
        salary = round(random.uniform(30000, 100000), 2)
        phone = truncate(fake.phone_number(), 15)
        password = fake.password()
        role_fk = random.choice(role_ids)
        cur.execute('''
            INSERT INTO public.employee ("UUID", employee_code, name, position_fk, lastname, email, status_fk, bank_account, salary, phone, password, role_fk)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING "UUID";
        ''', (employee_uuid, employee_code, name, position_fk, lastname, email, status_fk, bank_account, salary, phone, password, role_fk))
        employee_uuids.append(employee_uuid)
        conn.commit()
    return employee_uuids

def create_allowances(num):
    allowance_ids = []
    for _ in range(num):
        name = truncate(fake.bs(), 80)
        description = truncate(fake.text(max_nb_chars=150), 150)
        cur.execute('''
            INSERT INTO public.allowance (id, name, description)
            VALUES (DEFAULT, %s, %s)
            RETURNING id;
        ''', (name, description))
        allowance_id = cur.fetchone()[0]
        allowance_ids.append(allowance_id)
        conn.commit()
    return allowance_ids

def create_deductions(num):
    deduction_ids = []
    for _ in range(num):
        name = truncate(fake.bs(), 80)
        description = truncate(fake.text(max_nb_chars=150), 150)
        cur.execute('''
            INSERT INTO public.deduction (id, name, description)
            VALUES (DEFAULT, %s, %s)
            RETURNING id;
        ''', (name, description))
        deduction_id = cur.fetchone()[0]
        deduction_ids.append(deduction_id)
        conn.commit()
    return deduction_ids

def create_employee_allowances(num, employee_uuids, allowance_ids):
    for _ in range(num):
        employee_fk = random.choice(employee_uuids)
        allowance_fk = random.choice(allowance_ids)
        payroll_type_fk = random.choice([1, 2, 3])
        effective_date = fake.date()
        date_created = fake.unix_time()
        amount = round(random.uniform(100, 1000), 2)
        cur.execute('''
            INSERT INTO public.employee_allowances (id, employee_fk, allowance_fk, payroll_type_fk, effective_date, date_created, amount)
            VALUES (DEFAULT, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        ''', (employee_fk, allowance_fk, payroll_type_fk, effective_date, date_created, amount))
        conn.commit()

def create_employee_deductions(num, employee_uuids, deduction_ids):
    for _ in range(num):
        employee_fk = random.choice(employee_uuids)
        deduction_fk = random.choice(deduction_ids)
        payroll_type_fk = random.choice([1, 2, 3])
        amount = round(random.uniform(100, 1000), 2)
        effective_date = fake.date()
        date_created = fake.unix_time()
        cur.execute('''
            INSERT INTO public.employee_deductions (id, employee_fk, deduction_fk, payroll_type_fk, amount, effective_date, date_created)
            VALUES (DEFAULT, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        ''', (employee_fk, deduction_fk, payroll_type_fk, amount, effective_date, date_created))
        conn.commit()

def create_employee_extra_hours(num, employee_uuids):
    for _ in range(num):
        hours = random.randint(1, 12)
        amount = round(random.uniform(10, 100), 2)
        effective_date = fake.date()
        date_created = fake.unix_time()
        employee_fk = random.choice(employee_uuids)
        payroll_type_fk = random.choice([1, 2, 3])
        cur.execute('''
            INSERT INTO public.employee_extra_hours (id, hours, amount, effective_date, date_created, employee_fk, payroll_type_fk)
            VALUES (DEFAULT, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        ''', (hours, amount, effective_date, date_created, employee_fk, payroll_type_fk))
        conn.commit()

def create_payroll_types():
    payroll_types = ['Monthly', 'Semi-Monthly', 'Once']
    payroll_type_ids = []
    for payroll_type in payroll_types:
        cur.execute('''
            INSERT INTO public.payroll_type (id, name)
            VALUES (DEFAULT, %s)
            RETURNING id;
        ''', (payroll_type,))
        payroll_type_id = cur.fetchone()[0]
        payroll_type_ids.append(payroll_type_id)
        conn.commit()
    return payroll_type_ids

def create_statuses():
    statuses = ['New', 'Computed']
    status_ids = []
    for status in statuses:
        cur.execute('''
            INSERT INTO public.status (id, name, comments)
            VALUES (DEFAULT, %s, %s)
            RETURNING id;
        ''', (status, fake.text(max_nb_chars=100)))
        status_id = cur.fetchone()[0]
        status_ids.append(status_id)
        conn.commit()
    return status_ids

def create_payrolls(num, payroll_type_ids):
    payroll_ids = []
    for _ in range(num):
        paroll_type_fk = random.choice(payroll_type_ids)
        reference_number = truncate(fake.unique.ean(length=8), 80)
        status = random.randint(0, 1)
        date_from = fake.date()
        date_to = fake.date()
        date_created = fake.unix_time()
        cur.execute('''
            INSERT INTO public.payroll (id, paroll_type_fk, reference_number, status, date_from, date_to, date_created)
            VALUES (DEFAULT, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        ''', (paroll_type_fk, reference_number, status, date_from, date_to, date_created))
        payroll_id = cur.fetchone()[0]
        payroll_ids.append(payroll_id)
        conn.commit()
    return payroll_ids

def create_payslips(num, employee_uuids, payroll_ids):
    for _ in range(num):
        payroll_fk = random.choice(payroll_ids)
        employee_fk = random.choice(employee_uuids)
        present = random.randint(0, 30)
        absent = random.randint(0, 30)
        salary = round(random.uniform(1000, 5000), 2)
        allowance_amount = round(random.uniform(100, 500), 2)
        net = round(salary + allowance_amount - random.uniform(50, 200), 2)
        deduction_amount = round(random.uniform(50, 200), 2)
        date_created = fake.date()
        cur.execute('''
            INSERT INTO public.payslip (id, payroll_fk, employee_fk, present, absent, salary, allowance_amount, net, deduction_amount, date_created)
            VALUES (DEFAULT, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        ''', (payroll_fk, employee_fk, present, absent, salary, allowance_amount, net, deduction_amount, date_created))
        conn.commit()

def create_user_activity_log(num, employee_uuids):
    actions = ["login", "logout", "create", "update", "delete"]
    for _ in range(num):
        employee_fk = random.choice(employee_uuids)
        action = random.choice(actions)
        action_timestamp = fake.date_time_this_year()
        cur.execute('''
            INSERT INTO public.user_activity_log (employee_fk, action, action_timestamp)
            VALUES (%s, %s, %s)
            RETURNING id;
        ''', (employee_fk, action, action_timestamp))
        conn.commit()

# Create test data
department_ids = create_departments(5)
position_ids = create_positions(10, department_ids)
role_ids = create_roles()
status_ids = create_statuses()
payroll_type_ids = create_payroll_types()
allowance_ids = create_allowances(50)
deduction_ids = create_deductions(48)
payroll_ids = create_payrolls(50, payroll_type_ids)

employee_uuids = create_employees(20, position_ids, role_ids, status_ids)
create_employee_allowances(50, employee_uuids, allowance_ids)
create_employee_deductions(50, employee_uuids, deduction_ids)
create_employee_extra_hours(35, employee_uuids)
create_payslips(50, employee_uuids, payroll_ids)
create_user_activity_log(100, employee_uuids)

# Close the connection
cur.close()
conn.close()
