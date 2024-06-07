import psycopg2
import random
import uuid
from faker import Faker

conn = psycopg2.connect(
    dbname="ud_DBFoundations_project",
    user="ud_admin",
    password="HDjZLf03nK69O6IGs4Rg",
    host="localhost",  # Cambia según sea necesario
    port="5432"  # Puerto predeterminado para PostgreSQL
)

cur = conn.cursor()
fake = Faker()

def truncate_table(table_name):
    cur.execute(f'TRUNCATE TABLE {table_name} RESTART IDENTITY CASCADE;')
    conn.commit()

def reset_sequence(sequence_name):
    cur.execute(f'ALTER SEQUENCE {sequence_name} RESTART WITH 1;')
    conn.commit()

# Truncar tablas y reiniciar secuencias antes de insertar nuevos datos
truncate_table('public."Position"')
truncate_table('public."User"')
truncate_table('public.employee')
truncate_table('public.allowance')
truncate_table('public.deduction')
truncate_table('public.employee_allowances')
truncate_table('public.employee_deductions')
truncate_table('public.employee_extra_hours')
truncate_table('public.payroll')
truncate_table('public.payslip')
truncate_table('public.department')

# Reiniciar secuencias manualmente
reset_sequence('public."Position_id_seq"')
reset_sequence('public.allowance_id_seq')
reset_sequence('public.deduction_id_seq')
reset_sequence('public.employee_allowances_id_seq')
reset_sequence('public.employee_deductions_id_seq')
reset_sequence('public.employee_extra_hours_id_seq')
reset_sequence('public.payroll_id_seq')
reset_sequence('public.payslip_id_seq')
reset_sequence('public.department_id_seq')

# Continuar con la inserción de datos de prueba
def truncate(value, max_length):
    return value if len(value) <= max_length else value[:max_length]

def create_positions(num):
    position_ids = []
    for _ in range(num):
        name = truncate(fake.job(), 50)
        description = truncate(fake.text(max_nb_chars=150), 150)
        department_fk = random.randint(1, 5)  # Ajustar según los IDs de department existentes
        cur.execute('''
            INSERT INTO public."Position" (id, name, description, department_fk)
            VALUES (DEFAULT, %s, %s, %s)
            RETURNING id;
        ''', (name, description, department_fk))
        position_id = cur.fetchone()[0]
        position_ids.append(position_id)
        conn.commit()
    return position_ids

def create_users(num):
    user_uuids = []
    for _ in range(num):
        user_uuid = str(uuid.uuid4())
        name = truncate(fake.name(), 80)
        password = fake.password()
        username = truncate(fake.user_name(), 50)
        role_fk = random.choice([1, 2])  # Solo admin y user
        cur.execute('''
            INSERT INTO public."User" ("UUID", name, password, username, role_fk)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING "UUID";
        ''', (user_uuid, name, password, username, role_fk))
        user_uuids.append(user_uuid)
        conn.commit()
    return user_uuids

def create_employees(num, position_ids):
    employee_uuids = []
    for _ in range(num):
        employee_uuid = str(uuid.uuid4())
        employee_code = truncate(fake.unique.ean(length=8), 10)
        name = truncate(fake.name(), 200)
        position_fk = random.choice(position_ids)  # Usar IDs válidos de Position
        lastname = truncate(fake.last_name(), 200)
        email = truncate(fake.email(), 100)
        status_fk = random.choice([1, 2])  # Solo New y Computed
        bank_account = fake.iban()
        salary = round(random.uniform(30000, 100000), 2)
        phone = truncate(fake.phone_number(), 15)  # Ajustar el tamaño máximo del teléfono
        cur.execute('''
            INSERT INTO public.employee ("UUID", employee_code, name, position_fk, lastname, email, status_fk, bank_account, salary, phone)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING "UUID";
        ''', (employee_uuid, employee_code, name, position_fk, lastname, email, status_fk, bank_account, salary, phone))
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
        employee_fk = random.choice(employee_uuids)  # Usar UUIDs válidos de empleados
        allowance_fk = random.choice(allowance_ids)  # Usar IDs válidos de allowance
        payroll_type_fk = random.choice([1, 2, 3])  # Solo Monthly, Semi-Monthly y Once
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
        employee_fk = random.choice(employee_uuids)  # Usar UUIDs válidos de empleados
        deduction_fk = random.choice(deduction_ids)  # Usar IDs válidos de deduction
        payroll_type_fk = random.choice([1, 2, 3])  # Solo Monthly, Semi-Monthly y Once
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
        employee_fk = random.choice(employee_uuids)  # Usar UUIDs válidos de empleados
        payroll_type_fk = random.choice([1, 2, 3])  # Solo Monthly, Semi-Monthly y Once
        cur.execute('''
            INSERT INTO public.employee_extra_hours (id, hours, amount, effective_date, date_created, employee_fk, payroll_type_fk)
            VALUES (DEFAULT, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        ''', (hours, amount, effective_date, date_created, employee_fk, payroll_type_fk))
        conn.commit()

def create_payrolls(num):
    payroll_ids = []
    for _ in range(num):
        paroll_type_fk = random.choice([1, 2, 3])  # Solo Monthly, Semi-Monthly y Once
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
        payroll_fk = random.choice(payroll_ids)  # Usar IDs válidos de payroll
        employee_fk = random.choice(employee_uuids)  # Usar UUIDs válidos de empleados
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

# Crear datos de prueba
department_ids = create_departments(5)
position_ids = create_positions(10)
user_uuids = create_users(20)
employee_uuids = create_employees(50, position_ids)
allowance_ids = create_allowances(50)
deduction_ids = create_deductions(48)
payroll_ids = create_payrolls(50)

create_employee_allowances(50, employee_uuids, allowance_ids)
create_employee_deductions(50, employee_uuids, deduction_ids)
create_employee_extra_hours(35, employee_uuids)
create_payslips(50, employee_uuids, payroll_ids)

# Cerrar la conexión
cur.close()
conn.close()
