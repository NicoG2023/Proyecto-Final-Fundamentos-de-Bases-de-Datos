CREATE TABLE public."Position" (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(150),
    department_fk integer NOT NULL
);
CREATE TABLE public."Role" (
    name character varying(80) NOT NULL,
    id integer NOT NULL
);
CREATE TABLE public.allowance (
    id integer NOT NULL,
    name character varying(80) NOT NULL,
    description character varying(150) NOT NULL
);

CREATE TABLE public.deduction (
    id integer NOT NULL,
    name character varying(80) NOT NULL,
    description character varying(150) NOT NULL
);
CREATE TABLE public.department (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    description character varying(150)
);
CREATE TABLE public.employee (
    "UUID" uuid NOT NULL,
    employee_code character varying(10) NOT NULL,
    name character varying(200) NOT NULL,
    position_fk integer NOT NULL,
    lastname character varying(200) NOT NULL,
    email character varying(100) NOT NULL,
    status_fk integer NOT NULL,
    bank_account text NOT NULL,
    salary numeric NOT NULL,
    phone character varying(15) NOT NULL,
    password character varying(60) NOT NULL,
    role_fk integer NOT NULL
);
CREATE TABLE public.employee_allowances (
    id integer NOT NULL,
    employee_fk uuid NOT NULL,
    allowance_fk integer NOT NULL,
    payroll_type_fk integer NOT NULL,
    effective_date character varying NOT NULL,
    date_created bigint NOT NULL,
    amount numeric DEFAULT 0 NOT NULL
);
CREATE TABLE public.employee_deductions (
    id integer NOT NULL,
    employee_fk uuid NOT NULL,
    deduction_fk integer NOT NULL,
    payroll_type_fk integer NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    effective_date date NOT NULL,
    date_created bigint NOT NULL
);
CREATE TABLE public.employee_extra_hours (
    id integer NOT NULL,
    hours smallint NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    effective_date date NOT NULL,
    date_created bigint NOT NULL,
    employee_fk uuid,
    payroll_type_fk integer NOT NULL
);
CREATE TABLE public.payroll (
    id integer NOT NULL,
    paroll_type_fk integer NOT NULL,
    reference_number character varying(80) NOT NULL,
    status smallint NOT NULL,
    date_from date NOT NULL,
    date_to date NOT NULL,
    date_created bigint NOT NULL
);
CREATE TABLE public.payroll_type (
    id integer NOT NULL,
    name character varying(80) NOT NULL
);
CREATE TABLE public.payslip (
    id integer NOT NULL,
    payroll_fk integer NOT NULL,
    employee_fk uuid NOT NULL,
    present smallint NOT NULL,
    absent smallint NOT NULL,
    salary numeric NOT NULL,
    allowance_amount numeric NOT NULL,
    net numeric NOT NULL,
    deduction_amount numeric NOT NULL,
    date_created date NOT NULL
);
CREATE TABLE public.status (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    comments character varying(100) NOT NULL
);
CREATE TABLE public.user_activity_log (
    id integer NOT NULL,
    action text NOT NULL,
    action_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    employee_fk uuid NOT NULL
);
ALTER TABLE ONLY public.allowance
    ADD CONSTRAINT allowance_pk PRIMARY KEY (id);

ALTER TABLE ONLY public.deduction
    ADD CONSTRAINT deduction_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pk PRIMARY KEY (id);


ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_pk PRIMARY KEY (id);


ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_pk PRIMARY KEY (id);


ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_pk PRIMARY KEY (id);


ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pk PRIMARY KEY ("UUID");

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique UNIQUE (employee_code);

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_1 UNIQUE (email);

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_2 UNIQUE (bank_account);

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_3 UNIQUE (phone);

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_pk PRIMARY KEY (id);

ALTER TABLE ONLY public.payroll_type
    ADD CONSTRAINT payroll_type_pk PRIMARY KEY (id);

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_unique UNIQUE (reference_number);

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_pk PRIMARY KEY (id);

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_pk PRIMARY KEY (id);

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_unique UNIQUE (name);

ALTER TABLE ONLY public."Role"
    ADD CONSTRAINT role_pk PRIMARY KEY (id);

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pk PRIMARY KEY (id);

ALTER TABLE ONLY public.user_activity_log
    ADD CONSTRAINT user_activity_log_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_allowance_fk FOREIGN KEY (allowance_fk) REFERENCES public.allowance(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_deduction_fk FOREIGN KEY (deduction_fk) REFERENCES public.deduction(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_position_fk FOREIGN KEY (position_fk) REFERENCES public."Position"(id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_role_fk FOREIGN KEY (role_fk) REFERENCES public."Role"(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_status_fk FOREIGN KEY (status_fk) REFERENCES public.status(id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_payroll_type_fk FOREIGN KEY (paroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_payroll_fk FOREIGN KEY (payroll_fk) REFERENCES public.payroll(id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_department_fk FOREIGN KEY (department_fk) REFERENCES public.department(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.user_activity_log
    ADD CONSTRAINT user_activity_log_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;
