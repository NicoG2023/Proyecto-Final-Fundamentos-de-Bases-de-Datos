--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2 (Debian 16.2-1.pgdg120+2)
-- Dumped by pg_dump version 16.2

-- Started on 2024-06-11 22:28:59

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3547 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 262 (class 1255 OID 58698)
-- Name: archive_old_payrolls(date); Type: PROCEDURE; Schema: public; Owner: ud_admin
--

CREATE PROCEDURE public.archive_old_payrolls(IN cutoff_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Insert old records into the archive table
    INSERT INTO public.archive_payroll (id, paroll_type_fk, reference_number, status, date_from, date_to, date_created)
    SELECT id, paroll_type_fk, reference_number, status, date_from, date_to, date_created
    FROM public.payroll
    WHERE date_to < cutoff_date;
    
    -- Delete old records from the main table
    DELETE FROM public.payroll
    WHERE date_to < cutoff_date;
END;
$$;


ALTER PROCEDURE public.archive_old_payrolls(IN cutoff_date date) OWNER TO ud_admin;

--
-- TOC entry 249 (class 1255 OID 58701)
-- Name: count_users_per_role(); Type: PROCEDURE; Schema: public; Owner: ud_admin
--

CREATE PROCEDURE public.count_users_per_role()
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT r.name AS role_name, COUNT(e."UUID") AS employee_count
    FROM public.employee e 
    JOIN public."Role" r ON e.role_fk = r.id 
    GROUP BY r.name 
    ORDER BY employee_count DESC;
END;
$$;


ALTER PROCEDURE public.count_users_per_role() OWNER TO ud_admin;

--
-- TOC entry 248 (class 1255 OID 58700)
-- Name: list_employees_with_roles(); Type: PROCEDURE; Schema: public; Owner: ud_admin
--

CREATE PROCEDURE public.list_employees_with_roles()
    LANGUAGE plpgsql
    AS $$
begin 
	select e.name as employee_name, e.email, r.name as role_name
	from public.employee e 
	join public."Role" r on e.role_fk = r.id 
	order by e."name" ;
end;
$$;


ALTER PROCEDURE public.list_employees_with_roles() OWNER TO ud_admin;

--
-- TOC entry 247 (class 1255 OID 50567)
-- Name: prevent_negative_salary(); Type: FUNCTION; Schema: public; Owner: ud_admin
--

CREATE FUNCTION public.prevent_negative_salary() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin 
	if new.salary < 0 then raise exception 'Salary cannot be negative';
	end if;
	return new;
end;
$$;


ALTER FUNCTION public.prevent_negative_salary() OWNER TO ud_admin;

--
-- TOC entry 263 (class 1255 OID 58699)
-- Name: recalculate_salaries(); Type: PROCEDURE; Schema: public; Owner: ud_admin
--

CREATE PROCEDURE public.recalculate_salaries()
    LANGUAGE plpgsql
    AS $$
DECLARE
    emp RECORD;
    new_salary NUMERIC;
BEGIN
    FOR emp IN 
        SELECT e."UUID", e.salary, p.id as position_id, p.salary_increment
        FROM public.employee e
        JOIN public."Position" p ON e.position_fk = p.id
    LOOP
        new_salary := emp.salary + emp.salary * emp.salary_increment / 100;
        UPDATE public.employee
        SET salary = new_salary
        WHERE "UUID" = emp."UUID";
        
        INSERT INTO public.user_activity_log(user_fk, action, action_timestamp)
        VALUES (emp."UUID", 'salary recalculated', NOW());
    END LOOP;
END;
$$;


ALTER PROCEDURE public.recalculate_salaries() OWNER TO ud_admin;

--
-- TOC entry 250 (class 1255 OID 50572)
-- Name: refresh_employee_payroll_summary(); Type: PROCEDURE; Schema: public; Owner: ud_admin
--

CREATE PROCEDURE public.refresh_employee_payroll_summary()
    LANGUAGE plpgsql
    AS $$
begin 
	drop view if exists employee_payroll_summary;
	create view employee_payroll_summary as
	select e."UUID" as employee_id, e.name as employee_name, e.salary as base_salary, coalesce(sum(ea.amount),0) as total_allowances, coalesce(sum(ed.amount),0) as total_deductions,
	(e.salary + coalesce(sum(ea.amount),0) - coalesce(sum(ed.amount),0)) as net_salary
	from public.employee e 
	left join public.employee_allowances ea on e."UUID" = ea.employee_fk
	left join public.employee_deductions ed on e."UUID" = ed.employee_fk
	group by e."UUID", e.name, e.salary;
end;
$$;


ALTER PROCEDURE public.refresh_employee_payroll_summary() OWNER TO ud_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 228 (class 1259 OID 24646)
-- Name: Position; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public."Position" (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(150),
    department_fk integer NOT NULL
);


ALTER TABLE public."Position" OWNER TO ud_admin;

--
-- TOC entry 227 (class 1259 OID 24645)
-- Name: Position_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public."Position_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Position_id_seq" OWNER TO ud_admin;

--
-- TOC entry 3548 (class 0 OID 0)
-- Dependencies: 227
-- Name: Position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public."Position_id_seq" OWNED BY public."Position".id;


--
-- TOC entry 217 (class 1259 OID 24584)
-- Name: Role; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public."Role" (
    name character varying(80) NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public."Role" OWNER TO ud_admin;

--
-- TOC entry 220 (class 1259 OID 24601)
-- Name: Role_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public."Role_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Role_id_seq" OWNER TO ud_admin;

--
-- TOC entry 3549 (class 0 OID 0)
-- Dependencies: 220
-- Name: Role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public."Role_id_seq" OWNED BY public."Role".id;


--
-- TOC entry 224 (class 1259 OID 24616)
-- Name: allowance; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.allowance (
    id integer NOT NULL,
    name character varying(80) NOT NULL,
    description character varying(150) NOT NULL
);


ALTER TABLE public.allowance OWNER TO ud_admin;

--
-- TOC entry 223 (class 1259 OID 24615)
-- Name: allowance_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.allowance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.allowance_id_seq OWNER TO ud_admin;

--
-- TOC entry 3550 (class 0 OID 0)
-- Dependencies: 223
-- Name: allowance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.allowance_id_seq OWNED BY public.allowance.id;


--
-- TOC entry 216 (class 1259 OID 24578)
-- Name: deduction; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.deduction (
    id integer NOT NULL,
    name character varying(80) NOT NULL,
    description character varying(150) NOT NULL
);


ALTER TABLE public.deduction OWNER TO ud_admin;

--
-- TOC entry 215 (class 1259 OID 24577)
-- Name: deduction_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.deduction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.deduction_id_seq OWNER TO ud_admin;

--
-- TOC entry 3551 (class 0 OID 0)
-- Dependencies: 215
-- Name: deduction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.deduction_id_seq OWNED BY public.deduction.id;


--
-- TOC entry 219 (class 1259 OID 24590)
-- Name: department; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.department (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    description character varying(150)
);


ALTER TABLE public.department OWNER TO ud_admin;

--
-- TOC entry 229 (class 1259 OID 24659)
-- Name: employee; Type: TABLE; Schema: public; Owner: ud_admin
--

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


ALTER TABLE public.employee OWNER TO ud_admin;

--
-- TOC entry 243 (class 1259 OID 58678)
-- Name: department_employee_summary; Type: VIEW; Schema: public; Owner: ud_admin
--

CREATE VIEW public.department_employee_summary AS
 SELECT d.id AS department_id,
    d.name AS department_name,
    count(e."UUID") AS employee_count,
    avg(e.salary) AS average_salary
   FROM ((public.department d
     JOIN public."Position" p ON ((d.id = p.department_fk)))
     JOIN public.employee e ON ((p.id = e.position_fk)))
  GROUP BY d.id, d.name;


ALTER VIEW public.department_employee_summary OWNER TO ud_admin;

--
-- TOC entry 218 (class 1259 OID 24589)
-- Name: department_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.department_id_seq OWNER TO ud_admin;

--
-- TOC entry 3552 (class 0 OID 0)
-- Dependencies: 218
-- Name: department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.department_id_seq OWNED BY public.department.id;


--
-- TOC entry 237 (class 1259 OID 24746)
-- Name: employee_allowances; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.employee_allowances (
    id integer NOT NULL,
    employee_fk uuid NOT NULL,
    allowance_fk integer NOT NULL,
    payroll_type_fk integer NOT NULL,
    effective_date character varying NOT NULL,
    date_created bigint NOT NULL,
    amount numeric DEFAULT 0 NOT NULL
);


ALTER TABLE public.employee_allowances OWNER TO ud_admin;

--
-- TOC entry 3553 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN employee_allowances.amount; Type: COMMENT; Schema: public; Owner: ud_admin
--

COMMENT ON COLUMN public.employee_allowances.amount IS 'es el precio y datos de un solo allowance de los varios que puede tener un empleado';


--
-- TOC entry 245 (class 1259 OID 58688)
-- Name: department_salary_budget; Type: VIEW; Schema: public; Owner: ud_admin
--

CREATE VIEW public.department_salary_budget AS
 SELECT d.id AS department_id,
    d.name AS department_name,
    sum(e.salary) AS total_base_salaries,
    COALESCE(sum(ea.amount), (0)::numeric) AS total_budget
   FROM (((public.department d
     JOIN public."Position" p ON ((d.id = p.department_fk)))
     JOIN public.employee e ON ((p.id = e.position_fk)))
     LEFT JOIN public.employee_allowances ea ON ((e."UUID" = ea.employee_fk)))
  GROUP BY d.id, d.name;


ALTER VIEW public.department_salary_budget OWNER TO ud_admin;

--
-- TOC entry 236 (class 1259 OID 24745)
-- Name: employee_allowances_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.employee_allowances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_allowances_id_seq OWNER TO ud_admin;

--
-- TOC entry 3554 (class 0 OID 0)
-- Dependencies: 236
-- Name: employee_allowances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.employee_allowances_id_seq OWNED BY public.employee_allowances.id;


--
-- TOC entry 235 (class 1259 OID 24727)
-- Name: payslip; Type: TABLE; Schema: public; Owner: ud_admin
--

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


ALTER TABLE public.payslip OWNER TO ud_admin;

--
-- TOC entry 3555 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN payslip.net; Type: COMMENT; Schema: public; Owner: ud_admin
--

COMMENT ON COLUMN public.payslip.net IS 'Salario total del empleado sumado y restado allowances y deductions';


--
-- TOC entry 246 (class 1259 OID 58693)
-- Name: employee_attendance_summary; Type: VIEW; Schema: public; Owner: ud_admin
--

CREATE VIEW public.employee_attendance_summary AS
 SELECT e.name AS employee_name,
    sum(ps.present) AS total_days_present,
    sum(ps.absent) AS total_days_absent
   FROM (public.employee e
     JOIN public.payslip ps ON ((e."UUID" = ps.employee_fk)))
  GROUP BY e."UUID", e.name;


ALTER VIEW public.employee_attendance_summary OWNER TO ud_admin;

--
-- TOC entry 239 (class 1259 OID 24771)
-- Name: employee_deductions; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.employee_deductions (
    id integer NOT NULL,
    employee_fk uuid NOT NULL,
    deduction_fk integer NOT NULL,
    payroll_type_fk integer NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    effective_date date NOT NULL,
    date_created bigint NOT NULL
);


ALTER TABLE public.employee_deductions OWNER TO ud_admin;

--
-- TOC entry 3556 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN employee_deductions.amount; Type: COMMENT; Schema: public; Owner: ud_admin
--

COMMENT ON COLUMN public.employee_deductions.amount IS 'precio y datos de uno de los varios deductions que puede tener un empleado';


--
-- TOC entry 238 (class 1259 OID 24770)
-- Name: employee_deductions_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.employee_deductions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_deductions_id_seq OWNER TO ud_admin;

--
-- TOC entry 3557 (class 0 OID 0)
-- Dependencies: 238
-- Name: employee_deductions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.employee_deductions_id_seq OWNED BY public.employee_deductions.id;


--
-- TOC entry 231 (class 1259 OID 24694)
-- Name: employee_extra_hours; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.employee_extra_hours (
    id integer NOT NULL,
    hours smallint NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    effective_date date NOT NULL,
    date_created bigint NOT NULL,
    employee_fk uuid,
    payroll_type_fk integer NOT NULL
);


ALTER TABLE public.employee_extra_hours OWNER TO ud_admin;

--
-- TOC entry 230 (class 1259 OID 24693)
-- Name: employee_extra_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.employee_extra_hours_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_extra_hours_id_seq OWNER TO ud_admin;

--
-- TOC entry 3558 (class 0 OID 0)
-- Dependencies: 230
-- Name: employee_extra_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.employee_extra_hours_id_seq OWNED BY public.employee_extra_hours.id;


--
-- TOC entry 242 (class 1259 OID 58673)
-- Name: employee_payroll_summary; Type: VIEW; Schema: public; Owner: ud_admin
--

CREATE VIEW public.employee_payroll_summary AS
 SELECT e."UUID" AS employee_id,
    e.name AS employee_name,
    e.salary AS base_salary,
    COALESCE(sum(ea.amount), (0)::numeric) AS total_allowances,
    COALESCE(sum(ed.amount), (0)::numeric) AS total_deductions,
    ((e.salary + COALESCE(sum(ea.amount), (0)::numeric)) - COALESCE(sum(ed.amount), (0)::numeric)) AS net_salary
   FROM ((public.employee e
     LEFT JOIN public.employee_allowances ea ON ((e."UUID" = ea.employee_fk)))
     LEFT JOIN public.employee_deductions ed ON ((e."UUID" = ed.employee_fk)))
  GROUP BY e."UUID", e.name, e.salary;


ALTER VIEW public.employee_payroll_summary OWNER TO ud_admin;

--
-- TOC entry 233 (class 1259 OID 24713)
-- Name: payroll; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.payroll (
    id integer NOT NULL,
    paroll_type_fk integer NOT NULL,
    reference_number character varying(80) NOT NULL,
    status smallint NOT NULL,
    date_from date NOT NULL,
    date_to date NOT NULL,
    date_created bigint NOT NULL
);


ALTER TABLE public.payroll OWNER TO ud_admin;

--
-- TOC entry 232 (class 1259 OID 24712)
-- Name: payroll_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.payroll_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payroll_id_seq OWNER TO ud_admin;

--
-- TOC entry 3559 (class 0 OID 0)
-- Dependencies: 232
-- Name: payroll_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.payroll_id_seq OWNED BY public.payroll.id;


--
-- TOC entry 226 (class 1259 OID 24639)
-- Name: payroll_type; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.payroll_type (
    id integer NOT NULL,
    name character varying(80) NOT NULL
);


ALTER TABLE public.payroll_type OWNER TO ud_admin;

--
-- TOC entry 225 (class 1259 OID 24638)
-- Name: payroll_type_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.payroll_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payroll_type_id_seq OWNER TO ud_admin;

--
-- TOC entry 3560 (class 0 OID 0)
-- Dependencies: 225
-- Name: payroll_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.payroll_type_id_seq OWNED BY public.payroll_type.id;


--
-- TOC entry 234 (class 1259 OID 24726)
-- Name: payslip_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.payslip_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payslip_id_seq OWNER TO ud_admin;

--
-- TOC entry 3561 (class 0 OID 0)
-- Dependencies: 234
-- Name: payslip_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.payslip_id_seq OWNED BY public.payslip.id;


--
-- TOC entry 222 (class 1259 OID 24609)
-- Name: status; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.status (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    comments character varying(100) NOT NULL
);


ALTER TABLE public.status OWNER TO ud_admin;

--
-- TOC entry 221 (class 1259 OID 24608)
-- Name: status_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_id_seq OWNER TO ud_admin;

--
-- TOC entry 3562 (class 0 OID 0)
-- Dependencies: 221
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.status_id_seq OWNED BY public.status.id;


--
-- TOC entry 241 (class 1259 OID 50351)
-- Name: user_activity_log; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.user_activity_log (
    id integer NOT NULL,
    action text NOT NULL,
    action_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    employee_fk uuid NOT NULL
);


ALTER TABLE public.user_activity_log OWNER TO ud_admin;

--
-- TOC entry 240 (class 1259 OID 50350)
-- Name: user_activity_log_id_seq; Type: SEQUENCE; Schema: public; Owner: ud_admin
--

CREATE SEQUENCE public.user_activity_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_activity_log_id_seq OWNER TO ud_admin;

--
-- TOC entry 3563 (class 0 OID 0)
-- Dependencies: 240
-- Name: user_activity_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.user_activity_log_id_seq OWNED BY public.user_activity_log.id;


--
-- TOC entry 244 (class 1259 OID 58683)
-- Name: user_activity_summary; Type: VIEW; Schema: public; Owner: ud_admin
--

CREATE VIEW public.user_activity_summary AS
 SELECT e."UUID" AS user_id,
    e.name AS user_name,
    r.name AS role_name,
    a.action,
    a.action_timestamp
   FROM ((public.employee e
     JOIN public."Role" r ON ((e.role_fk = r.id)))
     JOIN public.user_activity_log a ON ((e."UUID" = a.employee_fk)));


ALTER VIEW public.user_activity_summary OWNER TO ud_admin;

--
-- TOC entry 3299 (class 2604 OID 24649)
-- Name: Position id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Position" ALTER COLUMN id SET DEFAULT nextval('public."Position_id_seq"'::regclass);


--
-- TOC entry 3294 (class 2604 OID 24602)
-- Name: Role id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Role" ALTER COLUMN id SET DEFAULT nextval('public."Role_id_seq"'::regclass);


--
-- TOC entry 3297 (class 2604 OID 24619)
-- Name: allowance id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.allowance ALTER COLUMN id SET DEFAULT nextval('public.allowance_id_seq'::regclass);


--
-- TOC entry 3293 (class 2604 OID 24581)
-- Name: deduction id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.deduction ALTER COLUMN id SET DEFAULT nextval('public.deduction_id_seq'::regclass);


--
-- TOC entry 3295 (class 2604 OID 24593)
-- Name: department id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.department ALTER COLUMN id SET DEFAULT nextval('public.department_id_seq'::regclass);


--
-- TOC entry 3304 (class 2604 OID 24749)
-- Name: employee_allowances id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances ALTER COLUMN id SET DEFAULT nextval('public.employee_allowances_id_seq'::regclass);


--
-- TOC entry 3306 (class 2604 OID 24774)
-- Name: employee_deductions id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions ALTER COLUMN id SET DEFAULT nextval('public.employee_deductions_id_seq'::regclass);


--
-- TOC entry 3300 (class 2604 OID 24697)
-- Name: employee_extra_hours id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_extra_hours ALTER COLUMN id SET DEFAULT nextval('public.employee_extra_hours_id_seq'::regclass);


--
-- TOC entry 3302 (class 2604 OID 24716)
-- Name: payroll id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll ALTER COLUMN id SET DEFAULT nextval('public.payroll_id_seq'::regclass);


--
-- TOC entry 3298 (class 2604 OID 24642)
-- Name: payroll_type id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll_type ALTER COLUMN id SET DEFAULT nextval('public.payroll_type_id_seq'::regclass);


--
-- TOC entry 3303 (class 2604 OID 24730)
-- Name: payslip id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payslip ALTER COLUMN id SET DEFAULT nextval('public.payslip_id_seq'::regclass);


--
-- TOC entry 3296 (class 2604 OID 24612)
-- Name: status id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.status ALTER COLUMN id SET DEFAULT nextval('public.status_id_seq'::regclass);


--
-- TOC entry 3308 (class 2604 OID 50354)
-- Name: user_activity_log id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.user_activity_log ALTER COLUMN id SET DEFAULT nextval('public.user_activity_log_id_seq'::regclass);


--
-- TOC entry 3528 (class 0 OID 24646)
-- Dependencies: 228
-- Data for Name: Position; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public."Position" VALUES (1, 'Chartered public finance accountant', 'Six million everything there cut receive. Hour why still think sport newspaper.
Follow this vote your we.', 2);
INSERT INTO public."Position" VALUES (2, 'Restaurant manager', 'Make concern six that past according. North four across one but idea as.
Determine card summer. Very into oil talk he full. Accept remember civil.', 2);
INSERT INTO public."Position" VALUES (3, 'Marine scientist', 'May inside idea cup early wide. Ground simply store newspaper carry.', 5);
INSERT INTO public."Position" VALUES (4, 'Engineer, biomedical', 'Sign idea control behind. Certainly bill sing.
Nearly often could position. Stock war seek think action key street remember.', 2);
INSERT INTO public."Position" VALUES (5, 'Energy manager', 'Including line class wife husband. We practice strategy word food. Woman situation present eat. Cause what her federal feel too per.', 1);
INSERT INTO public."Position" VALUES (6, 'Designer, graphic', 'Down million movie movement thought design. Purpose affect oil pass cell I. Do bring remain.', 1);
INSERT INTO public."Position" VALUES (7, 'Technical author', 'Up safe tend music point none. Watch night start building.', 4);
INSERT INTO public."Position" VALUES (8, 'Control and instrumentation engineer', 'Myself no attention option less let live. Organization against something natural within. College quickly should character child.', 2);
INSERT INTO public."Position" VALUES (9, 'Nurse, learning disability', 'Chance interest attack maybe work wrong simply idea. Necessary physical give central choose civil baby.
Three nor hard.', 5);
INSERT INTO public."Position" VALUES (10, 'Fitness centre manager', 'Wonder hospital language. Dinner trip finish doctor continue grow thus. Admit article person record I. Put drug challenge head quality audience.', 1);
INSERT INTO public."Position" VALUES (11, 'Software Engineer', 'Responsible for developing and maintaining software applications.', 3);


--
-- TOC entry 3517 (class 0 OID 24584)
-- Dependencies: 217
-- Data for Name: Role; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public."Role" VALUES ('Admin', 1);
INSERT INTO public."Role" VALUES ('User', 2);


--
-- TOC entry 3524 (class 0 OID 24616)
-- Dependencies: 224
-- Data for Name: allowance; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.allowance VALUES (1, 'empower out-of-the-box schemas', 'Inside past learn despite job factor kid respond. Think indicate past. Produce various nature recognize two hair month describe.');
INSERT INTO public.allowance VALUES (2, 'synergize cross-platform functionalities', 'Hit manage these. Outside development fish fast course strategy movie military.');
INSERT INTO public.allowance VALUES (3, 'visualize front-end functionalities', 'Force attention just. Produce industry various affect he listen. Level east myself window live air probably.');
INSERT INTO public.allowance VALUES (4, 'deploy strategic portals', 'Method where source far.
Best so agency. Station single where other suffer man type.');
INSERT INTO public.allowance VALUES (5, 'seize value-added experiences', 'Garden chair could present hot make. Onto bank hotel enjoy. I power high treatment half push. Generation threat suggest year.');
INSERT INTO public.allowance VALUES (6, 'enhance enterprise channels', 'Exist bar environment million particularly maybe. Computer leave live member difference speech.
Order adult drive begin source ahead.');
INSERT INTO public.allowance VALUES (7, 'reinvent synergistic e-services', 'Single bar common hotel population money speech. Senior hot official somebody.');
INSERT INTO public.allowance VALUES (8, 'incubate integrated portals', 'The minute term power girl forward speak college. Ready health fact soon huge.');
INSERT INTO public.allowance VALUES (9, 'grow revolutionary action-items', 'Public skill employee use over safe wind. Manage help rate rich.');
INSERT INTO public.allowance VALUES (10, 'engineer strategic web-readiness', 'Wind miss exist. You none owner analysis total.
Get affect whole consumer wonder. Behind when agree.');
INSERT INTO public.allowance VALUES (11, 'generate back-end info-mediaries', 'Experience just forget image world suffer. Detail early leader understand. Wonder start movie talk hope.');
INSERT INTO public.allowance VALUES (12, 'embrace e-business models', 'Bank main least dark. Its by receive loss leader.');
INSERT INTO public.allowance VALUES (13, 'reinvent cross-media networks', 'Local friend travel peace alone special.
Water article quite director beyond anything fight apply. Per forget them.');
INSERT INTO public.allowance VALUES (14, 'streamline distributed niches', 'Bring through key family report his over. Bank film report local option sing girl. Skin board sea step owner far look food.');
INSERT INTO public.allowance VALUES (15, 'cultivate out-of-the-box mindshare', 'Drop recent enjoy all run over soldier however. Experience situation what parent year herself hotel region.');
INSERT INTO public.allowance VALUES (16, 'unleash e-business users', 'Forward interesting phone hard I important smile. Cut term provide find their one build. Scene class they lay meeting ready owner safe.');
INSERT INTO public.allowance VALUES (17, 'integrate user-centric architectures', 'They vote offer. Challenge fish free true bed.
Protect outside while quickly try city. Their wear seven exactly effort put sing.');
INSERT INTO public.allowance VALUES (18, 'mesh end-to-end convergence', 'Artist some each artist this. Military level tonight attention arrive.');
INSERT INTO public.allowance VALUES (19, 'leverage innovative channels', 'Relationship southern it message boy instead begin. Rule concern why accept maintain. Executive nor more can right possible.');
INSERT INTO public.allowance VALUES (20, 'extend vertical partnerships', 'Whom meet few once attention to. Nice toward policy international. End research result partner require.');
INSERT INTO public.allowance VALUES (21, 'empower best-of-breed eyeballs', 'Glass adult interesting degree her bed. Hot eye hundred table long tough people figure.
Each forget minute guess type manager.');
INSERT INTO public.allowance VALUES (22, 'mesh cutting-edge partnerships', 'Stand ability idea question. Character lot provide exist management cover.
Tree blood into. Better production thing alone significant reduce.');
INSERT INTO public.allowance VALUES (23, 'monetize efficient methodologies', 'Role party admit other ten important.
Than so computer by indeed own machine. Radio size them color shoulder collection.');
INSERT INTO public.allowance VALUES (24, 're-intermediate intuitive synergies', 'Book me trip young leader TV. Age cold recently last fish drug realize.');
INSERT INTO public.allowance VALUES (25, 'whiteboard integrated technologies', 'Who choice education great consider baby wrong.
Course industry including smile say process oil. White trouble also role.');
INSERT INTO public.allowance VALUES (26, 'iterate extensible supply-chains', 'Art style analysis teach person. Movie adult nice. Admit election team necessary life environment.');
INSERT INTO public.allowance VALUES (27, 'productize dynamic users', 'Democrat research blue experience top design bring. Bar color middle share. Manage recently tax none speak.');
INSERT INTO public.allowance VALUES (28, 'e-enable innovative markets', 'State policy word good. It agreement card main feeling positive. Leader center method add rather use.');
INSERT INTO public.allowance VALUES (29, 'benchmark impactful e-tailers', 'Market society night traditional form provide. Develop finally quality easy act action.');
INSERT INTO public.allowance VALUES (30, 'streamline virtual communities', 'Throughout do every series day. Discussion important month the. Form analysis police find present.');
INSERT INTO public.allowance VALUES (31, 'empower frictionless relationships', 'Generation picture easy card total budget still. Evening rise daughter voice. Kind imagine fly position.');
INSERT INTO public.allowance VALUES (32, 'architect user-centric applications', 'Wear rather wind evening.
Foreign possible race place continue TV Congress. Rise analysis research wide. Customer information reality newspaper add.');
INSERT INTO public.allowance VALUES (33, 'empower extensible e-business', 'Sport affect area heart training man middle tend. Focus finish it subject. Half what lot sure.');
INSERT INTO public.allowance VALUES (34, 'orchestrate dynamic technologies', 'Choice career effect sense. Miss them answer buy also. Memory support show official. Yes admit of bank will.');
INSERT INTO public.allowance VALUES (35, 'generate visionary e-services', 'Kid something leave land four realize. Feeling system trade hope when. Present tend involve single half rock.');
INSERT INTO public.allowance VALUES (36, 'iterate integrated eyeballs', 'Book allow support future Congress win heavy. According purpose executive nearly have.');
INSERT INTO public.allowance VALUES (37, 'visualize dynamic architectures', 'Six fear crime particular ahead present current. Today push woman stop lawyer onto.');
INSERT INTO public.allowance VALUES (38, 'strategize plug-and-play web services', 'No memory note shoulder. Born single behind do treat well. Behind piece Democrat high black go within.');
INSERT INTO public.allowance VALUES (39, 'implement e-business e-tailers', 'Available more clear commercial.
Message treat right to push. Exactly recently deep budget language dinner. Prevent send wide pattern over ahead.');
INSERT INTO public.allowance VALUES (40, 'whiteboard sticky initiatives', 'Cover long per party street crime carry. Now pattern sea water. American before home certain team also.');
INSERT INTO public.allowance VALUES (41, 're-contextualize robust content', 'Much most receive side big agent nothing. Former expert measure my provide reality much. Start generation store require new seven consumer modern.');
INSERT INTO public.allowance VALUES (42, 'revolutionize bricks-and-clicks info-mediaries', 'Full water we unit suffer forget walk detail. Way choose record call generation. Perhaps nothing last respond provide city take well.');
INSERT INTO public.allowance VALUES (43, 'redefine seamless niches', 'Carry environmental page push option house prove. Pull page next something.');
INSERT INTO public.allowance VALUES (44, 'e-enable virtual relationships', 'Line walk century unit eat. Campaign election article instead.');
INSERT INTO public.allowance VALUES (45, 'mesh scalable deliverables', 'Real home guess send art important myself. Various focus skin cost. Program yet stage interest.');
INSERT INTO public.allowance VALUES (46, 'innovate end-to-end partnerships', 'Specific quickly memory mouth Democrat able let. Expert should must. Above call husband sea type outside.');
INSERT INTO public.allowance VALUES (47, 'incentivize proactive e-services', 'Nice past heart blue military free decision. Media right interesting like establish range well. Cold surface section himself. Theory minute value.');
INSERT INTO public.allowance VALUES (48, 'brand dynamic functionalities', 'Think local process personal learn spring pattern. Financial marriage decision surface visit.');
INSERT INTO public.allowance VALUES (49, 'disintermediate turn-key info-mediaries', 'Wonder hundred model or. Only none something throw bring personal. Conference wish energy either reveal most less.');
INSERT INTO public.allowance VALUES (50, 'matrix cross-media e-markets', 'Choice defense raise sea artist collection. Keep along leave data explain. Scene black determine.');
INSERT INTO public.allowance VALUES (51, 'Housing Allowance', 'Monthly housing allowance.');


--
-- TOC entry 3516 (class 0 OID 24578)
-- Dependencies: 216
-- Data for Name: deduction; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.deduction VALUES (1, 'whiteboard user-centric vortals', 'Size might environment tonight Congress. Type any push approach appear. Thus low buy north worker.');
INSERT INTO public.deduction VALUES (2, 'exploit ubiquitous niches', 'War fear teach enter catch fish. Address bad during collection data. Customer deep laugh beyond.');
INSERT INTO public.deduction VALUES (3, 'maximize vertical partnerships', 'Want teacher heart partner rise see. Big tree term lead past or.');
INSERT INTO public.deduction VALUES (4, 'syndicate cutting-edge web services', 'Plant coach but movie along it simply. Up child give anything away.
Member down movie voice travel. Under business prepare pass thus shoulder.');
INSERT INTO public.deduction VALUES (5, 'deploy rich synergies', 'Focus economy war.
Personal without ground country culture. War test among remain talk go every treatment.');
INSERT INTO public.deduction VALUES (6, 'envisioneer sticky interfaces', 'Police doctor field third mission.
Soldier know military interest. Rest industry career say. Pretty serious nearly visit.');
INSERT INTO public.deduction VALUES (7, 'enhance integrated systems', 'Week west growth. Feel discussion country situation amount without.');
INSERT INTO public.deduction VALUES (8, 'enhance killer interfaces', 'Treat short activity everything. Fly example sell seat establish.');
INSERT INTO public.deduction VALUES (9, 'drive 24/365 solutions', 'View do majority science. Less step amount partner conference social. Ready stock Democrat author compare successful.');
INSERT INTO public.deduction VALUES (10, 'transition world-class systems', 'Traditional environmental during never. Above pay camera shoulder benefit entire. Near old note need program wall.');
INSERT INTO public.deduction VALUES (11, 'revolutionize revolutionary metrics', 'Floor himself fill.
Green training size bag exactly yet center. Coach air down market window.');
INSERT INTO public.deduction VALUES (12, 'benchmark real-time vortals', 'Challenge professor response.
Yard chance opportunity trouble next argue magazine.');
INSERT INTO public.deduction VALUES (13, 'monetize robust deliverables', 'My party tell. Military certainly fast start course. Beautiful really letter hour go family read.');
INSERT INTO public.deduction VALUES (14, 'mesh one-to-one users', 'Director in just stuff politics. Bad eat interest service girl success little.');
INSERT INTO public.deduction VALUES (15, 'streamline vertical bandwidth', 'Improve usually fear idea western only. Game truth part set.');
INSERT INTO public.deduction VALUES (16, 'enhance virtual interfaces', 'Sit soon entire mother hear.
Of standard not agreement research sense between. Some appear partner born he next history.');
INSERT INTO public.deduction VALUES (17, 'transform cross-media eyeballs', 'Face describe show read partner. Whatever build painting discover share business. Machine option center term paper daughter lead.');
INSERT INTO public.deduction VALUES (18, 'extend seamless technologies', 'Mean prepare important charge office former assume maintain. Represent magazine thousand toward. Husband student accept why.');
INSERT INTO public.deduction VALUES (19, 'expedite extensible e-tailers', 'Assume pay number during hotel morning education. Site never one build former. Place respond follow off.
Bank market wonder need seat turn defense.');
INSERT INTO public.deduction VALUES (20, 'reinvent sticky e-markets', 'Year face visit hand hospital number. Move to side film him next. Production election laugh behavior turn be despite important.');
INSERT INTO public.deduction VALUES (21, 'disintermediate cutting-edge networks', 'Small change enter finally her voice find. Five recent under heavy front street writer.');
INSERT INTO public.deduction VALUES (22, 'seize front-end interfaces', 'Bad rise else shoulder education others yourself. Night wind rate result science American kitchen that. Something about quite your.');
INSERT INTO public.deduction VALUES (23, 'matrix wireless bandwidth', 'Collection sometimes detail important pressure staff. Character opportunity look claim movement situation doctor. Such daughter form current.');
INSERT INTO public.deduction VALUES (24, 'embrace cross-media e-business', 'Color service decide wait during. Third audience your that any. Red environment community enter.
Camera through play stop.');
INSERT INTO public.deduction VALUES (25, 'monetize real-time e-commerce', 'Yourself apply various win third from best officer.
Key outside wrong past take. Do can various economy enjoy. Friend least you middle agree certain.');
INSERT INTO public.deduction VALUES (26, 'evolve synergistic mindshare', 'Result lawyer music tough miss tax. Quite ten big industry weight you point.');
INSERT INTO public.deduction VALUES (27, 're-intermediate bricks-and-clicks action-items', 'Up possible on over local add. Down past stand order government ready. Product season central.');
INSERT INTO public.deduction VALUES (28, 'morph plug-and-play e-commerce', 'Peace still recently upon. Who management ten box international my picture.
Black item course should apply. While federal pull space.');
INSERT INTO public.deduction VALUES (29, 'unleash transparent relationships', 'Think generation their art commercial source season pressure. Artist both or them friend or. After note least gas.');
INSERT INTO public.deduction VALUES (30, 'empower global eyeballs', 'Position million gas find. Week do story before.
Authority term young. Laugh power human particular two glass.');
INSERT INTO public.deduction VALUES (31, 'implement rich applications', 'Even indicate go even body movie. Good theory she business author in.
Trouble resource already human officer. Condition report save.');
INSERT INTO public.deduction VALUES (32, 're-contextualize ubiquitous portals', 'Eye fish hear popular cut. Listen player worry book rule. Fire question church blood remember management offer.');
INSERT INTO public.deduction VALUES (33, 'deploy leading-edge infrastructures', 'Official argue do determine. System manager large approach kid appear animal. Heavy wish improve value station.');
INSERT INTO public.deduction VALUES (34, 'innovate efficient solutions', 'Purpose growth way tree party. Open smile light room successful quite girl. Exist speech price hour bit summer value.');
INSERT INTO public.deduction VALUES (35, 'leverage 24/7 info-mediaries', 'Traditional claim sort make. Traditional nice nice issue. Down ground above born face lay civil understand.');
INSERT INTO public.deduction VALUES (36, 're-intermediate front-end methodologies', 'None test by stuff. Growth anyone decision smile purpose certainly. Mean daughter inside.');
INSERT INTO public.deduction VALUES (37, 'seize distributed e-services', 'Wind approach must experience statement our. City per away but true majority. Safe rich exactly claim shoulder continue. By somebody song little.');
INSERT INTO public.deduction VALUES (38, 'orchestrate user-centric experiences', 'Left board development little him cultural. Well evening resource of tend special serve quality. Ago eat ok.');
INSERT INTO public.deduction VALUES (39, 'productize open-source e-tailers', 'Claim blue remember speech go either short up. Realize decision model real computer.');
INSERT INTO public.deduction VALUES (40, 'enhance plug-and-play applications', 'Collection ground challenge note high commercial. Add everyone player herself instead.
Three contain where one soon feeling price everyone.');
INSERT INTO public.deduction VALUES (41, 'repurpose cross-platform models', 'Six fill Democrat later part suddenly rise. Meet speech fish computer box. Picture defense since TV vote suddenly Congress west.');
INSERT INTO public.deduction VALUES (42, 'syndicate proactive interfaces', 'Admit close particular answer push. Letter build usually bit learn its person.
Everyone approach fly during. Despite health if fact behind often.');
INSERT INTO public.deduction VALUES (43, 'envisioneer bleeding-edge deliverables', 'Particular even interview small baby. Health return prove ground expect of check. Also to visit.');
INSERT INTO public.deduction VALUES (44, 'engage rich partnerships', 'Single entire increase bring such see.');
INSERT INTO public.deduction VALUES (45, 'syndicate end-to-end architectures', 'Interest few boy run behind painting least. Live account show interview yet man.');
INSERT INTO public.deduction VALUES (46, 'seize 24/365 bandwidth', 'Order art rule need single agent. Writer prove American character treat whether ago. Risk visit minute thousand.');
INSERT INTO public.deduction VALUES (47, 'expedite rich info-mediaries', 'Establish discuss hotel game skin writer coach. Represent involve leg. Real now answer bag play.
Stay when operation shoulder start tree notice.');
INSERT INTO public.deduction VALUES (48, 'scale revolutionary channels', 'Close assume partner evening story around goal. See case nor democratic sister.');
INSERT INTO public.deduction VALUES (49, 'Tax Deduction', 'Monthly tax deduction.');


--
-- TOC entry 3519 (class 0 OID 24590)
-- Dependencies: 219
-- Data for Name: department; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.department VALUES (1, 'Acosta Ltd', 'Whom leave shoulder manager sometimes. Eat require treatment purpose believe.
Determine coach study quite him.');
INSERT INTO public.department VALUES (2, 'Roach Ltd', 'Reduce seek suffer. Language affect choice peace physical else their. Mind ask respond marriage since.');
INSERT INTO public.department VALUES (3, 'Bell Group', 'Public apply see natural out. Institution yet born magazine voice recently beautiful break.');
INSERT INTO public.department VALUES (4, 'Mccullough-Alexander', 'Especially try many use. Bed yes green. Official protect road pressure dinner place society however.');
INSERT INTO public.department VALUES (5, 'Lopez, Reynolds and Cooper', 'Present deep outside begin.
Money important church late wear pick always. Sell field continue help ago.');


--
-- TOC entry 3529 (class 0 OID 24659)
-- Dependencies: 229
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.employee VALUES ('360ade6b-9e18-4aaf-baf2-ee27080c3336', '53921925', 'David Jones', 7, 'Perry', 'thompsondavid@example.net', 1, 'GB78IAEI38772373807365', 84727.26, '(291)236-3407', '3k4tYao4!&', 2);
INSERT INTO public.employee VALUES ('a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', '28797777', 'Sarah Turner', 6, 'Mccarthy', 'ovaughan@example.org', 1, 'GB23KRYM89067845542999', 64499.65, '990.374.4203', 'Z$8DAHBa70', 1);
INSERT INTO public.employee VALUES ('e4c1c60e-5582-456c-9319-99ac6da65a59', '03939185', 'Jacqueline Acevedo', 9, 'Fuller', 'peterbuchanan@example.com', 1, 'GB51APFW11701765819264', 61259.79, '001-752-986-576', 'fD7O(HGxs*', 2);
INSERT INTO public.employee VALUES ('9631b51e-3cee-4c4f-b604-23c43c9da9c9', '48279963', 'Laura Tran', 1, 'Braun', 'philliptownsend@example.org', 2, 'GB33TZTB42082176428386', 84934.51, '935-856-2797', '$_H96qYt#^', 2);
INSERT INTO public.employee VALUES ('7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e', '35578444', 'Alyssa Gray', 6, 'Mcmahon', 'robinsonvalerie@example.net', 1, 'GB61NOUA68541321338532', 56488.11, '268-713-1368x83', 'ia6oPF&dr@', 1);
INSERT INTO public.employee VALUES ('3670cebc-711e-40a2-961d-d9040cdf6937', '91326430', 'Joseph Walsh', 7, 'Valdez', 'wrightchelsea@example.org', 2, 'GB87ZQYF46192350499418', 78009.78, '(919)933-7464x7', 'L5Y3Irsm_f', 2);
INSERT INTO public.employee VALUES ('93e78342-becc-4395-8049-d0fc028d137c', '43777129', 'Richard Clark', 6, 'Gomez', 'gallegosjeffrey@example.org', 1, 'GB44URBP04948736367234', 48450.67, '(241)389-9674x6', 'je0Cyo%Q#Z', 2);
INSERT INTO public.employee VALUES ('d5b6220b-1efb-4c6f-ae0c-484a5cefa7be', '81670543', 'Aaron Kelly', 4, 'Andrade', 'richardsonvalerie@example.net', 2, 'GB45CLRD12864985451256', 68073.04, '372.734.2470x84', ')3DWQ5_rmj', 1);
INSERT INTO public.employee VALUES ('faa61fb1-d27f-4f3b-b52c-2e7e5227e601', '52213694', 'Sarah Henry', 9, 'Zhang', 'ann49@example.net', 2, 'GB36NUYO43978838678297', 42891.98, '442-636-9372', '_EsS0C#o+!', 2);
INSERT INTO public.employee VALUES ('cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', '52399251', 'Angela Cain', 2, 'Davis', 'cpalmer@example.net', 2, 'GB85ILRR46493648215811', 71111.0, '+1-239-606-7833', 'Tk+8LW6t4Y', 1);
INSERT INTO public.employee VALUES ('7d937d48-010f-4b4f-bd0b-1a67f68f8185', '96126721', 'Maria Sharp', 10, 'Zuniga', 'seanbond@example.org', 1, 'GB80MMGX58496769065445', 44432.51, '881-827-9120', '@Yer2Jej%r', 1);
INSERT INTO public.employee VALUES ('fe8d7a50-80bd-49d5-b029-c73642a3f41b', '61497115', 'Deborah Green', 8, 'Smith', 'madisoncollins@example.org', 1, 'GB34BIMA32098403374778', 62918.58, '001-299-285-257', 'qM7pIOjT%)', 2);
INSERT INTO public.employee VALUES ('d3669caa-81d3-45eb-8dda-7114a82d904e', '77509208', 'Daniel Mahoney', 10, 'Hayes', 'johnnyharrington@example.org', 1, 'GB07UTHO81990229442744', 87951.03, '+1-359-852-4677', ')8ybOv*2wG', 2);
INSERT INTO public.employee VALUES ('37922b60-4903-4117-84ca-661ba83f9f97', '67195206', 'Tara Huffman', 8, 'Butler', 'figueroarebecca@example.com', 1, 'GB05BNFE89247448213656', 80244.33, '930.761.5817x25', 'hJyGf0Xh3(', 2);
INSERT INTO public.employee VALUES ('bb2435c2-d49b-4d10-a3f6-e323f9465b2e', '45709944', 'Mr. Nathan Kennedy', 3, 'Holland', 'nataliehuerta@example.net', 1, 'GB19NACT92633682506600', 75343.22, '001-286-330-365', '_LH6dPbjmT', 2);
INSERT INTO public.employee VALUES ('5a35b3e2-9782-491b-939b-518df92f5b75', '51466084', 'Jerry Boone', 5, 'Lewis', 'owatson@example.org', 1, 'GB61GLTY34603526159497', 75811.58, '(405)616-2674x4', '&Slz6XRo*_', 1);
INSERT INTO public.employee VALUES ('dd58823f-4b55-4692-b851-c54adddac03f', '38700064', 'Rachel Barrett', 10, 'Castillo', 'whiteamanda@example.net', 1, 'GB35XXQD79573172321998', 41399.77, '001-901-853-978', 'q#!X3nBbyQ', 2);
INSERT INTO public.employee VALUES ('2d6aa8fc-89b5-402d-928c-244dbb7a10a1', '20945633', 'Tonya Anderson', 5, 'Jennings', 'john41@example.org', 2, 'GB75MCIM18821532977585', 74860.4, '7585342164', 'J5D5Hl&S!k', 2);
INSERT INTO public.employee VALUES ('fcc69a8d-cb2d-423c-a7fc-6ea99b549858', '32375053', 'William Herring', 3, 'Robertson', 'michellegarrison@example.com', 2, 'GB76MDBW70083729271129', 44305.06, '+1-713-447-8208', '#nzVEYhxs8', 1);
INSERT INTO public.employee VALUES ('3e35d982-3067-4349-89db-6740c03ae1dc', '27303108', 'Calvin Thompson', 8, 'Camacho', 'david53@example.com', 2, 'GB55QXDJ30738327311024', 31792.95, '001-921-942-189', '!7$Wx5Ji7W', 1);
INSERT INTO public.employee VALUES ('550e8400-e29b-41d4-a716-446655440000', '12345678', 'John Doe', 1, 'Doe', 'john.doe@example.com', 1, '1234567890', 50000.0, '123-456-7890', 'SafePassword', 1);


--
-- TOC entry 3537 (class 0 OID 24746)
-- Dependencies: 237
-- Data for Name: employee_allowances; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.employee_allowances VALUES (1, 'dd58823f-4b55-4692-b851-c54adddac03f', 40, 3, '2016-07-20', 885604004, 681.84);
INSERT INTO public.employee_allowances VALUES (2, '3e35d982-3067-4349-89db-6740c03ae1dc', 34, 1, '1982-06-11', 631312203, 294.75);
INSERT INTO public.employee_allowances VALUES (3, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 42, 1, '2010-12-10', 401025004, 332.57);
INSERT INTO public.employee_allowances VALUES (4, 'd3669caa-81d3-45eb-8dda-7114a82d904e', 37, 2, '1994-03-09', 1667188257, 647.8);
INSERT INTO public.employee_allowances VALUES (5, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 38, 2, '2010-07-27', 912459233, 468.33);
INSERT INTO public.employee_allowances VALUES (6, 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601', 6, 1, '2021-07-23', 313203953, 752.12);
INSERT INTO public.employee_allowances VALUES (7, 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', 4, 2, '1998-04-18', 525319245, 400.04);
INSERT INTO public.employee_allowances VALUES (8, '360ade6b-9e18-4aaf-baf2-ee27080c3336', 46, 2, '1970-10-23', 333108407, 559.64);
INSERT INTO public.employee_allowances VALUES (9, '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e', 18, 3, '1978-11-21', 1635303896, 672.08);
INSERT INTO public.employee_allowances VALUES (10, 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601', 40, 3, '1994-10-26', 158853839, 815.18);
INSERT INTO public.employee_allowances VALUES (11, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 48, 3, '1985-04-05', 1666305838, 889.93);
INSERT INTO public.employee_allowances VALUES (12, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 46, 1, '1993-03-10', 17027886, 257.1);
INSERT INTO public.employee_allowances VALUES (13, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 32, 1, '2013-11-11', 621166028, 421.11);
INSERT INTO public.employee_allowances VALUES (14, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 44, 2, '2013-08-09', 1007804553, 771.79);
INSERT INTO public.employee_allowances VALUES (15, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 30, 3, '2010-11-04', 1298690218, 293.08);
INSERT INTO public.employee_allowances VALUES (16, '360ade6b-9e18-4aaf-baf2-ee27080c3336', 18, 2, '1987-04-06', 587971282, 833.49);
INSERT INTO public.employee_allowances VALUES (17, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 17, 3, '1970-01-04', 1261687808, 253.08);
INSERT INTO public.employee_allowances VALUES (18, '3670cebc-711e-40a2-961d-d9040cdf6937', 16, 1, '2012-01-05', 819404689, 385.29);
INSERT INTO public.employee_allowances VALUES (19, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 21, 1, '1998-01-08', 512898226, 432.42);
INSERT INTO public.employee_allowances VALUES (20, '37922b60-4903-4117-84ca-661ba83f9f97', 34, 1, '1990-11-17', 242294310, 959.09);
INSERT INTO public.employee_allowances VALUES (21, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 27, 3, '1987-03-21', 257721761, 920.24);
INSERT INTO public.employee_allowances VALUES (22, 'd3669caa-81d3-45eb-8dda-7114a82d904e', 29, 1, '1999-12-25', 885201555, 105.43);
INSERT INTO public.employee_allowances VALUES (23, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 1, 1, '1998-04-14', 1025247168, 747.37);
INSERT INTO public.employee_allowances VALUES (24, '3670cebc-711e-40a2-961d-d9040cdf6937', 34, 2, '1979-03-24', 489259650, 158.73);
INSERT INTO public.employee_allowances VALUES (25, '3e35d982-3067-4349-89db-6740c03ae1dc', 10, 2, '2023-01-28', 606596415, 536.75);
INSERT INTO public.employee_allowances VALUES (26, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 35, 3, '1984-02-04', 1577136491, 347.3);
INSERT INTO public.employee_allowances VALUES (27, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 35, 2, '1986-07-17', 1370715759, 420.47);
INSERT INTO public.employee_allowances VALUES (28, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 9, 3, '2013-03-28', 782376575, 656.82);
INSERT INTO public.employee_allowances VALUES (29, '3e35d982-3067-4349-89db-6740c03ae1dc', 43, 1, '1973-06-20', 4203993, 407.7);
INSERT INTO public.employee_allowances VALUES (30, '37922b60-4903-4117-84ca-661ba83f9f97', 5, 3, '2022-12-21', 389168099, 988.58);
INSERT INTO public.employee_allowances VALUES (31, 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', 19, 3, '1981-03-29', 471333905, 375.57);
INSERT INTO public.employee_allowances VALUES (32, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 15, 2, '1992-11-18', 1419536455, 213.52);
INSERT INTO public.employee_allowances VALUES (33, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 7, 2, '1998-03-23', 378086612, 407.83);
INSERT INTO public.employee_allowances VALUES (34, 'dd58823f-4b55-4692-b851-c54adddac03f', 50, 1, '1971-11-15', 757675813, 199.5);
INSERT INTO public.employee_allowances VALUES (35, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 46, 1, '2000-01-13', 804391052, 881.78);
INSERT INTO public.employee_allowances VALUES (36, '5a35b3e2-9782-491b-939b-518df92f5b75', 38, 2, '1983-07-12', 1093249599, 970.17);
INSERT INTO public.employee_allowances VALUES (37, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 45, 1, '2008-03-03', 938439143, 792.59);
INSERT INTO public.employee_allowances VALUES (38, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 12, 1, '1976-10-30', 288487648, 480.33);
INSERT INTO public.employee_allowances VALUES (39, '3670cebc-711e-40a2-961d-d9040cdf6937', 38, 2, '2013-10-10', 1499899455, 970.45);
INSERT INTO public.employee_allowances VALUES (40, '93e78342-becc-4395-8049-d0fc028d137c', 21, 2, '1991-03-21', 1074611754, 855.33);
INSERT INTO public.employee_allowances VALUES (41, 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601', 11, 1, '1992-10-19', 1135084375, 987.04);
INSERT INTO public.employee_allowances VALUES (42, 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', 50, 3, '1973-12-22', 94025252, 315.99);
INSERT INTO public.employee_allowances VALUES (43, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 32, 1, '2016-04-15', 184790788, 275.86);
INSERT INTO public.employee_allowances VALUES (44, '93e78342-becc-4395-8049-d0fc028d137c', 1, 3, '2001-10-05', 1345466573, 162.43);
INSERT INTO public.employee_allowances VALUES (45, '3e35d982-3067-4349-89db-6740c03ae1dc', 1, 2, '1986-10-21', 922051430, 902.32);
INSERT INTO public.employee_allowances VALUES (46, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 28, 2, '1991-03-13', 802412640, 667.64);
INSERT INTO public.employee_allowances VALUES (47, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 34, 3, '2021-12-31', 347488312, 355.23);
INSERT INTO public.employee_allowances VALUES (48, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 47, 2, '1977-08-20', 635177679, 193.7);
INSERT INTO public.employee_allowances VALUES (49, 'dd58823f-4b55-4692-b851-c54adddac03f', 50, 2, '1990-02-19', 39061230, 962.77);
INSERT INTO public.employee_allowances VALUES (50, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 26, 3, '2001-03-04', 1085313496, 217.75);
INSERT INTO public.employee_allowances VALUES (51, '550e8400-e29b-41d4-a716-446655440000', 1, 1, '2024-01-01', 1704067200, 500.0);


--
-- TOC entry 3539 (class 0 OID 24771)
-- Dependencies: 239
-- Data for Name: employee_deductions; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.employee_deductions VALUES (1, 'd3669caa-81d3-45eb-8dda-7114a82d904e', 44, 3, 353.96, '2018-10-13', 1023843454);
INSERT INTO public.employee_deductions VALUES (2, 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', 37, 1, 246.5, '1982-07-23', 218380580);
INSERT INTO public.employee_deductions VALUES (3, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 18, 3, 998.89, '2010-06-11', 1006162354);
INSERT INTO public.employee_deductions VALUES (4, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 18, 2, 183.49, '2017-09-28', 1410947595);
INSERT INTO public.employee_deductions VALUES (5, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 38, 1, 768.28, '1983-09-27', 613025264);
INSERT INTO public.employee_deductions VALUES (6, '93e78342-becc-4395-8049-d0fc028d137c', 16, 1, 823.36, '1975-05-10', 981630550);
INSERT INTO public.employee_deductions VALUES (7, '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e', 3, 3, 506.69, '2013-06-19', 103335044);
INSERT INTO public.employee_deductions VALUES (8, '3e35d982-3067-4349-89db-6740c03ae1dc', 39, 3, 998.25, '1988-03-28', 956234810);
INSERT INTO public.employee_deductions VALUES (9, '360ade6b-9e18-4aaf-baf2-ee27080c3336', 35, 1, 531.11, '2010-07-29', 488702490);
INSERT INTO public.employee_deductions VALUES (10, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 33, 3, 626.11, '1987-05-03', 398398104);
INSERT INTO public.employee_deductions VALUES (11, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 25, 3, 920.43, '2012-06-15', 715701160);
INSERT INTO public.employee_deductions VALUES (12, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 9, 1, 378.22, '2014-01-18', 1439773337);
INSERT INTO public.employee_deductions VALUES (13, '3670cebc-711e-40a2-961d-d9040cdf6937', 19, 2, 505.46, '1989-10-09', 568470028);
INSERT INTO public.employee_deductions VALUES (14, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 4, 2, 347.65, '2003-02-24', 724406246);
INSERT INTO public.employee_deductions VALUES (15, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 45, 2, 828.82, '2013-09-23', 1423878867);
INSERT INTO public.employee_deductions VALUES (16, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 30, 2, 778.35, '2004-05-21', 891091383);
INSERT INTO public.employee_deductions VALUES (17, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 46, 1, 656.15, '1975-01-03', 1384935311);
INSERT INTO public.employee_deductions VALUES (18, '3e35d982-3067-4349-89db-6740c03ae1dc', 8, 2, 540.16, '1974-06-09', 35739379);
INSERT INTO public.employee_deductions VALUES (19, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 45, 2, 980.36, '2022-12-23', 1094280186);
INSERT INTO public.employee_deductions VALUES (20, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 12, 1, 972.66, '2013-10-22', 1508881865);
INSERT INTO public.employee_deductions VALUES (21, '360ade6b-9e18-4aaf-baf2-ee27080c3336', 15, 2, 690.64, '2021-05-21', 1151640549);
INSERT INTO public.employee_deductions VALUES (22, 'dd58823f-4b55-4692-b851-c54adddac03f', 32, 2, 711.67, '2012-09-11', 1429202586);
INSERT INTO public.employee_deductions VALUES (23, 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', 19, 1, 100.33, '2022-10-26', 602094281);
INSERT INTO public.employee_deductions VALUES (24, '3670cebc-711e-40a2-961d-d9040cdf6937', 14, 1, 879.1, '1976-02-06', 402389542);
INSERT INTO public.employee_deductions VALUES (25, '5a35b3e2-9782-491b-939b-518df92f5b75', 32, 1, 718.7, '2023-11-27', 1328013409);
INSERT INTO public.employee_deductions VALUES (26, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 30, 2, 277.21, '1981-12-13', 167241620);
INSERT INTO public.employee_deductions VALUES (27, '3670cebc-711e-40a2-961d-d9040cdf6937', 38, 2, 955.87, '1997-01-05', 1055692805);
INSERT INTO public.employee_deductions VALUES (28, 'dd58823f-4b55-4692-b851-c54adddac03f', 39, 3, 865.86, '1987-08-21', 48658860);
INSERT INTO public.employee_deductions VALUES (29, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 22, 1, 261.06, '2012-12-11', 13267128);
INSERT INTO public.employee_deductions VALUES (30, 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', 16, 1, 777.14, '1988-09-28', 1268436486);
INSERT INTO public.employee_deductions VALUES (31, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 42, 2, 986.36, '2003-02-17', 974172592);
INSERT INTO public.employee_deductions VALUES (32, '93e78342-becc-4395-8049-d0fc028d137c', 26, 3, 329.81, '1977-06-23', 1259081452);
INSERT INTO public.employee_deductions VALUES (33, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 40, 1, 296.95, '1999-09-11', 751040958);
INSERT INTO public.employee_deductions VALUES (34, '3670cebc-711e-40a2-961d-d9040cdf6937', 47, 1, 214.28, '1992-06-28', 509522112);
INSERT INTO public.employee_deductions VALUES (35, 'd3669caa-81d3-45eb-8dda-7114a82d904e', 30, 3, 391.44, '2008-07-16', 639770075);
INSERT INTO public.employee_deductions VALUES (36, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 2, 1, 538.16, '2019-04-27', 66242403);
INSERT INTO public.employee_deductions VALUES (37, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 33, 3, 761.94, '1997-06-03', 489998682);
INSERT INTO public.employee_deductions VALUES (38, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 2, 2, 657.15, '1970-05-23', 442690749);
INSERT INTO public.employee_deductions VALUES (39, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 7, 3, 499.65, '1999-11-18', 1464185396);
INSERT INTO public.employee_deductions VALUES (40, '360ade6b-9e18-4aaf-baf2-ee27080c3336', 34, 3, 260.55, '1973-10-26', 1588058616);
INSERT INTO public.employee_deductions VALUES (41, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 39, 3, 668.58, '1971-04-07', 1668079052);
INSERT INTO public.employee_deductions VALUES (42, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 20, 2, 454.72, '2001-07-30', 1438665830);
INSERT INTO public.employee_deductions VALUES (43, '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e', 48, 2, 324.67, '2020-06-11', 663882865);
INSERT INTO public.employee_deductions VALUES (44, 'd3669caa-81d3-45eb-8dda-7114a82d904e', 36, 1, 251.9, '1980-11-23', 967765298);
INSERT INTO public.employee_deductions VALUES (45, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 2, 3, 854.81, '1978-11-21', 1278439076);
INSERT INTO public.employee_deductions VALUES (46, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 16, 3, 214.87, '2020-09-24', 834309328);
INSERT INTO public.employee_deductions VALUES (47, '37922b60-4903-4117-84ca-661ba83f9f97', 6, 2, 715.59, '2021-04-19', 564767268);
INSERT INTO public.employee_deductions VALUES (48, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 19, 1, 487.71, '1974-03-21', 124828445);
INSERT INTO public.employee_deductions VALUES (49, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 3, 3, 871.32, '2007-10-03', 606428231);
INSERT INTO public.employee_deductions VALUES (50, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 33, 2, 717.07, '2015-12-17', 1617557192);
INSERT INTO public.employee_deductions VALUES (51, '550e8400-e29b-41d4-a716-446655440000', 1, 1, 200.0, '2024-01-01', 1704067200);


--
-- TOC entry 3531 (class 0 OID 24694)
-- Dependencies: 231
-- Data for Name: employee_extra_hours; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.employee_extra_hours VALUES (1, 6, 44.36, '1997-09-28', 1649910091, '3670cebc-711e-40a2-961d-d9040cdf6937', 1);
INSERT INTO public.employee_extra_hours VALUES (2, 8, 93.33, '1974-01-18', 441024249, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 2);
INSERT INTO public.employee_extra_hours VALUES (3, 1, 65.18, '1998-12-22', 1637434947, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 1);
INSERT INTO public.employee_extra_hours VALUES (4, 10, 99.77, '1995-05-30', 202411559, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 3);
INSERT INTO public.employee_extra_hours VALUES (5, 7, 93.96, '2000-11-30', 1307889432, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 1);
INSERT INTO public.employee_extra_hours VALUES (6, 11, 48.11, '2006-05-02', 163712421, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 1);
INSERT INTO public.employee_extra_hours VALUES (7, 10, 61.03, '1997-03-02', 613261751, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 2);
INSERT INTO public.employee_extra_hours VALUES (8, 2, 18.75, '1997-04-18', 665929079, '2d6aa8fc-89b5-402d-928c-244dbb7a10a1', 2);
INSERT INTO public.employee_extra_hours VALUES (9, 7, 90.56, '2001-01-26', 564274671, '3670cebc-711e-40a2-961d-d9040cdf6937', 3);
INSERT INTO public.employee_extra_hours VALUES (10, 3, 65.47, '1980-12-01', 1190995830, '5a35b3e2-9782-491b-939b-518df92f5b75', 1);
INSERT INTO public.employee_extra_hours VALUES (11, 7, 50.79, '2021-02-20', 104242372, 'dd58823f-4b55-4692-b851-c54adddac03f', 3);
INSERT INTO public.employee_extra_hours VALUES (12, 6, 52.43, '1985-09-02', 863269958, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 2);
INSERT INTO public.employee_extra_hours VALUES (13, 2, 29.07, '1976-04-09', 861055269, '93e78342-becc-4395-8049-d0fc028d137c', 1);
INSERT INTO public.employee_extra_hours VALUES (14, 5, 25.75, '2023-10-13', 1343027128, '5a35b3e2-9782-491b-939b-518df92f5b75', 1);
INSERT INTO public.employee_extra_hours VALUES (15, 10, 29.26, '1990-03-25', 1317287893, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 2);
INSERT INTO public.employee_extra_hours VALUES (16, 5, 97.89, '2013-10-25', 1249192673, '5a35b3e2-9782-491b-939b-518df92f5b75', 1);
INSERT INTO public.employee_extra_hours VALUES (17, 6, 79.34, '1991-03-25', 307665974, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 1);
INSERT INTO public.employee_extra_hours VALUES (18, 3, 90.03, '2003-11-13', 424287671, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 1);
INSERT INTO public.employee_extra_hours VALUES (19, 4, 70.26, '2017-11-12', 895071661, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 2);
INSERT INTO public.employee_extra_hours VALUES (20, 1, 76.05, '2000-02-22', 1026102545, '3670cebc-711e-40a2-961d-d9040cdf6937', 2);
INSERT INTO public.employee_extra_hours VALUES (21, 9, 83.02, '2010-04-26', 1290187725, '360ade6b-9e18-4aaf-baf2-ee27080c3336', 2);
INSERT INTO public.employee_extra_hours VALUES (22, 7, 11.8, '2010-11-14', 324722027, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 3);
INSERT INTO public.employee_extra_hours VALUES (23, 11, 34.66, '1977-02-09', 79345228, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 1);
INSERT INTO public.employee_extra_hours VALUES (24, 6, 69.31, '1997-08-17', 1409121422, '5a35b3e2-9782-491b-939b-518df92f5b75', 3);
INSERT INTO public.employee_extra_hours VALUES (25, 6, 86.57, '1985-03-28', 1646199713, '3670cebc-711e-40a2-961d-d9040cdf6937', 2);
INSERT INTO public.employee_extra_hours VALUES (26, 1, 71.47, '1980-07-02', 1680267230, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 3);
INSERT INTO public.employee_extra_hours VALUES (27, 5, 67.54, '1975-11-09', 517714139, '3670cebc-711e-40a2-961d-d9040cdf6937', 2);
INSERT INTO public.employee_extra_hours VALUES (28, 11, 29.69, '1990-01-31', 1619350243, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 3);
INSERT INTO public.employee_extra_hours VALUES (29, 9, 56.17, '1985-02-08', 1245214876, 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601', 2);
INSERT INTO public.employee_extra_hours VALUES (30, 9, 93.93, '1986-10-15', 793870564, '3670cebc-711e-40a2-961d-d9040cdf6937', 1);
INSERT INTO public.employee_extra_hours VALUES (31, 8, 36.78, '1995-01-12', 649161046, '2d6aa8fc-89b5-402d-928c-244dbb7a10a1', 2);
INSERT INTO public.employee_extra_hours VALUES (32, 10, 73.67, '1992-09-17', 1042526005, 'dd58823f-4b55-4692-b851-c54adddac03f', 3);
INSERT INTO public.employee_extra_hours VALUES (33, 7, 11.74, '2009-07-17', 1551610357, '93e78342-becc-4395-8049-d0fc028d137c', 1);
INSERT INTO public.employee_extra_hours VALUES (34, 9, 99.83, '1985-03-22', 1449555627, '3e35d982-3067-4349-89db-6740c03ae1dc', 1);
INSERT INTO public.employee_extra_hours VALUES (35, 4, 77.54, '1981-09-07', 1248674822, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 3);
INSERT INTO public.employee_extra_hours VALUES (36, 5, 150.0, '2024-01-01', 1704067200, '550e8400-e29b-41d4-a716-446655440000', 1);


--
-- TOC entry 3533 (class 0 OID 24713)
-- Dependencies: 233
-- Data for Name: payroll; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.payroll VALUES (1, 3, '98219339', 1, '2004-09-20', '1987-03-03', 36775960);
INSERT INTO public.payroll VALUES (2, 1, '24190992', 1, '1984-06-23', '1994-10-09', 949528283);
INSERT INTO public.payroll VALUES (3, 3, '92834361', 1, '1996-11-23', '2010-04-30', 1086135817);
INSERT INTO public.payroll VALUES (4, 1, '61599970', 0, '1982-01-19', '2013-07-28', 179131716);
INSERT INTO public.payroll VALUES (5, 3, '97577881', 0, '1978-06-28', '2012-05-07', 241325900);
INSERT INTO public.payroll VALUES (6, 1, '42616177', 1, '1996-01-09', '1985-03-09', 99924163);
INSERT INTO public.payroll VALUES (7, 1, '76694240', 0, '1999-12-26', '1996-09-19', 1504570821);
INSERT INTO public.payroll VALUES (8, 2, '93324564', 1, '2021-11-07', '1996-08-17', 1489757725);
INSERT INTO public.payroll VALUES (9, 2, '26390291', 0, '1976-09-03', '1979-04-16', 259181582);
INSERT INTO public.payroll VALUES (10, 1, '91196958', 1, '2009-01-23', '1985-02-11', 817592819);
INSERT INTO public.payroll VALUES (11, 1, '32755145', 0, '1997-03-27', '2021-10-20', 29057519);
INSERT INTO public.payroll VALUES (12, 3, '04540236', 0, '1994-04-18', '1973-07-18', 1228073275);
INSERT INTO public.payroll VALUES (13, 1, '22681058', 1, '1988-04-19', '1999-12-11', 105233241);
INSERT INTO public.payroll VALUES (14, 3, '77106926', 0, '1997-02-25', '1971-09-27', 1659302060);
INSERT INTO public.payroll VALUES (15, 2, '80465942', 1, '2010-02-08', '1990-06-04', 423567424);
INSERT INTO public.payroll VALUES (16, 3, '58512135', 1, '2004-10-25', '1993-12-15', 1207252287);
INSERT INTO public.payroll VALUES (17, 3, '84380302', 0, '2002-08-11', '2014-02-22', 1443220082);
INSERT INTO public.payroll VALUES (18, 2, '16427426', 1, '1970-08-16', '1992-05-24', 212532710);
INSERT INTO public.payroll VALUES (19, 1, '87798524', 0, '2016-04-22', '2017-12-03', 219465252);
INSERT INTO public.payroll VALUES (20, 3, '89372869', 1, '2001-11-14', '1971-01-15', 916305760);
INSERT INTO public.payroll VALUES (21, 3, '87239041', 1, '1988-12-08', '1981-11-19', 231497816);
INSERT INTO public.payroll VALUES (22, 3, '52407598', 0, '2004-11-15', '1974-11-08', 212836549);
INSERT INTO public.payroll VALUES (23, 2, '25475159', 0, '1974-11-29', '2020-07-11', 1434074019);
INSERT INTO public.payroll VALUES (24, 1, '22136299', 1, '1993-06-01', '1981-08-12', 1562599213);
INSERT INTO public.payroll VALUES (25, 1, '47349407', 1, '2000-12-03', '1991-10-11', 1109775269);
INSERT INTO public.payroll VALUES (26, 2, '58777398', 0, '1993-06-08', '1987-03-07', 454819393);
INSERT INTO public.payroll VALUES (27, 2, '64852973', 0, '1999-09-30', '2016-05-27', 507272117);
INSERT INTO public.payroll VALUES (28, 2, '56077155', 1, '1978-07-19', '2023-06-13', 15356166);
INSERT INTO public.payroll VALUES (29, 3, '73458616', 1, '2012-03-11', '1978-03-26', 1120601944);
INSERT INTO public.payroll VALUES (30, 1, '20796686', 0, '2005-09-28', '2010-11-18', 1157997142);
INSERT INTO public.payroll VALUES (31, 2, '96583883', 0, '1993-05-07', '1984-03-11', 1173635724);
INSERT INTO public.payroll VALUES (32, 2, '36143764', 0, '2009-03-05', '2016-10-08', 1631094339);
INSERT INTO public.payroll VALUES (33, 1, '79935876', 0, '2004-12-09', '2000-03-09', 962278871);
INSERT INTO public.payroll VALUES (34, 1, '62666831', 0, '2002-09-16', '1998-01-04', 709102070);
INSERT INTO public.payroll VALUES (35, 2, '98582822', 0, '1985-03-09', '1999-08-26', 981866547);
INSERT INTO public.payroll VALUES (36, 3, '29060313', 1, '1980-01-07', '2006-11-10', 970704941);
INSERT INTO public.payroll VALUES (37, 1, '54246126', 1, '1992-12-15', '1990-09-18', 81607020);
INSERT INTO public.payroll VALUES (38, 1, '82819248', 1, '2008-04-13', '1984-07-11', 141660606);
INSERT INTO public.payroll VALUES (39, 2, '15918017', 1, '1971-05-07', '1997-11-13', 929782341);
INSERT INTO public.payroll VALUES (40, 2, '92523821', 0, '2007-03-23', '1973-03-03', 530824605);
INSERT INTO public.payroll VALUES (41, 3, '99241384', 1, '2004-07-31', '1986-11-04', 930421734);
INSERT INTO public.payroll VALUES (42, 3, '42377375', 0, '1988-05-03', '1996-03-04', 1004275999);
INSERT INTO public.payroll VALUES (43, 3, '72052563', 0, '1999-10-29', '2020-03-22', 713438768);
INSERT INTO public.payroll VALUES (44, 2, '84040459', 0, '1980-10-31', '2012-07-08', 166022014);
INSERT INTO public.payroll VALUES (45, 3, '27053096', 0, '1981-05-22', '2016-11-18', 615915366);
INSERT INTO public.payroll VALUES (46, 1, '54399525', 1, '2001-11-30', '1989-09-01', 371930225);
INSERT INTO public.payroll VALUES (47, 2, '73282662', 1, '1970-01-23', '1986-03-24', 1339618481);
INSERT INTO public.payroll VALUES (48, 3, '90410628', 0, '2024-01-28', '1992-12-22', 1377741408);
INSERT INTO public.payroll VALUES (49, 3, '85969728', 0, '2009-12-16', '1991-04-02', 1132302505);
INSERT INTO public.payroll VALUES (50, 1, '42038177', 1, '2013-11-09', '1996-07-26', 1302289073);
INSERT INTO public.payroll VALUES (51, 1, '12345678', 1, '2024-01-01', '2024-01-31', 1704067200);


--
-- TOC entry 3526 (class 0 OID 24639)
-- Dependencies: 226
-- Data for Name: payroll_type; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.payroll_type VALUES (1, 'Monthly');
INSERT INTO public.payroll_type VALUES (2, 'Semi-Monthly');
INSERT INTO public.payroll_type VALUES (3, 'Once');


--
-- TOC entry 3535 (class 0 OID 24727)
-- Dependencies: 235
-- Data for Name: payslip; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.payslip VALUES (1, 23, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 25, 9, 4464.78, 269.67, 4594.55, 187.55, '2013-08-27');
INSERT INTO public.payslip VALUES (2, 21, 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601', 9, 11, 4854.64, 199.38, 4893.75, 190.08, '2024-05-22');
INSERT INTO public.payslip VALUES (3, 22, 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601', 11, 24, 2157.62, 345.12, 2411.44, 152.18, '2003-01-24');
INSERT INTO public.payslip VALUES (4, 43, '93e78342-becc-4395-8049-d0fc028d137c', 23, 29, 1045.31, 165.47, 1021.94, 130.07, '2004-02-26');
INSERT INTO public.payslip VALUES (5, 39, '3e35d982-3067-4349-89db-6740c03ae1dc', 7, 7, 4787.4, 206.6, 4874.24, 138.26, '1995-06-26');
INSERT INTO public.payslip VALUES (6, 8, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 19, 14, 1832.12, 403.84, 2078.73, 95.45, '1999-09-07');
INSERT INTO public.payslip VALUES (7, 32, '3e35d982-3067-4349-89db-6740c03ae1dc', 18, 10, 4586.85, 352.42, 4799.77, 183.51, '2008-03-08');
INSERT INTO public.payslip VALUES (8, 13, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 15, 19, 2673.75, 448.15, 3056.91, 198.78, '1970-11-28');
INSERT INTO public.payslip VALUES (9, 28, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 23, 30, 1154.27, 131.84, 1178.8, 168.87, '1989-01-09');
INSERT INTO public.payslip VALUES (10, 40, '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e', 11, 22, 1582.31, 425.96, 1893.75, 96.6, '1971-03-18');
INSERT INTO public.payslip VALUES (11, 5, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 2, 29, 4051.11, 348.85, 4342.94, 160.7, '2013-05-10');
INSERT INTO public.payslip VALUES (12, 21, '2d6aa8fc-89b5-402d-928c-244dbb7a10a1', 23, 27, 2331.43, 218.82, 2404.5, 72.25, '2001-01-28');
INSERT INTO public.payslip VALUES (13, 47, '37922b60-4903-4117-84ca-661ba83f9f97', 7, 9, 1846.92, 171.66, 1865.26, 67.44, '1984-01-16');
INSERT INTO public.payslip VALUES (14, 18, '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e', 10, 11, 1628.16, 283.48, 1721.0, 115.28, '2020-10-29');
INSERT INTO public.payslip VALUES (15, 7, 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', 13, 8, 1108.99, 337.21, 1342.69, 127.62, '2001-01-17');
INSERT INTO public.payslip VALUES (16, 47, '93e78342-becc-4395-8049-d0fc028d137c', 9, 26, 1065.12, 102.29, 986.43, 145.66, '2007-07-04');
INSERT INTO public.payslip VALUES (17, 36, '37922b60-4903-4117-84ca-661ba83f9f97', 11, 1, 3251.44, 146.05, 3237.39, 185.74, '1986-10-08');
INSERT INTO public.payslip VALUES (18, 21, '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e', 9, 27, 2070.34, 215.83, 2127.65, 125.42, '2001-04-28');
INSERT INTO public.payslip VALUES (19, 36, '37922b60-4903-4117-84ca-661ba83f9f97', 3, 20, 2608.31, 363.9, 2883.16, 118.89, '2016-10-13');
INSERT INTO public.payslip VALUES (20, 36, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 3, 8, 4338.51, 381.75, 4651.85, 193.62, '1992-08-15');
INSERT INTO public.payslip VALUES (21, 9, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 20, 8, 2407.32, 193.31, 2432.96, 70.18, '2007-11-14');
INSERT INTO public.payslip VALUES (22, 38, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 24, 20, 1097.66, 367.71, 1351.77, 158.51, '1978-01-22');
INSERT INTO public.payslip VALUES (23, 14, '2d6aa8fc-89b5-402d-928c-244dbb7a10a1', 29, 7, 4827.65, 199.54, 4877.31, 189.69, '1987-10-06');
INSERT INTO public.payslip VALUES (24, 19, '3670cebc-711e-40a2-961d-d9040cdf6937', 12, 18, 3469.07, 235.85, 3576.21, 137.44, '2009-08-26');
INSERT INTO public.payslip VALUES (25, 44, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 23, 13, 4120.6, 224.06, 4263.03, 94.22, '1978-06-13');
INSERT INTO public.payslip VALUES (26, 19, '3670cebc-711e-40a2-961d-d9040cdf6937', 1, 5, 2457.3, 276.54, 2629.07, 159.2, '1994-01-31');
INSERT INTO public.payslip VALUES (27, 19, '360ade6b-9e18-4aaf-baf2-ee27080c3336', 18, 15, 3585.16, 219.03, 3737.87, 188.89, '1999-12-27');
INSERT INTO public.payslip VALUES (28, 12, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 11, 13, 1896.28, 454.98, 2263.87, 75.9, '2014-10-05');
INSERT INTO public.payslip VALUES (29, 11, '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e', 6, 8, 2838.26, 334.52, 3100.57, 193.03, '1995-09-06');
INSERT INTO public.payslip VALUES (30, 48, '3670cebc-711e-40a2-961d-d9040cdf6937', 28, 10, 3984.2, 434.19, 4225.53, 64.86, '2012-09-30');
INSERT INTO public.payslip VALUES (31, 27, 'e4c1c60e-5582-456c-9319-99ac6da65a59', 25, 16, 3235.08, 118.49, 3166.23, 118.52, '1975-05-01');
INSERT INTO public.payslip VALUES (32, 47, '9631b51e-3cee-4c4f-b604-23c43c9da9c9', 20, 16, 4177.68, 332.0, 4400.2, 98.53, '1997-11-23');
INSERT INTO public.payslip VALUES (33, 19, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 20, 29, 3020.77, 217.58, 3093.1, 98.7, '1975-04-10');
INSERT INTO public.payslip VALUES (34, 22, 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763', 30, 4, 2170.99, 231.36, 2214.94, 50.92, '1981-10-12');
INSERT INTO public.payslip VALUES (35, 47, 'dd58823f-4b55-4692-b851-c54adddac03f', 26, 1, 1474.33, 484.44, 1883.01, 79.97, '1972-03-26');
INSERT INTO public.payslip VALUES (36, 39, '3670cebc-711e-40a2-961d-d9040cdf6937', 22, 4, 2660.88, 435.11, 3025.63, 157.93, '1976-02-17');
INSERT INTO public.payslip VALUES (37, 1, 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858', 15, 3, 3444.33, 283.85, 3614.47, 142.29, '2013-05-29');
INSERT INTO public.payslip VALUES (38, 35, '37922b60-4903-4117-84ca-661ba83f9f97', 29, 5, 1969.87, 413.7, 2320.5, 184.0, '1979-07-24');
INSERT INTO public.payslip VALUES (39, 44, '5a35b3e2-9782-491b-939b-518df92f5b75', 23, 28, 3068.0, 217.01, 3195.79, 164.48, '1992-04-11');
INSERT INTO public.payslip VALUES (40, 47, 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be', 21, 8, 2930.62, 460.38, 3231.43, 78.69, '2009-11-10');
INSERT INTO public.payslip VALUES (41, 7, 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e', 12, 15, 1855.14, 198.12, 1899.56, 147.44, '2013-07-23');
INSERT INTO public.payslip VALUES (42, 31, '5a35b3e2-9782-491b-939b-518df92f5b75', 1, 2, 1548.93, 103.32, 1599.86, 131.36, '1996-07-02');
INSERT INTO public.payslip VALUES (43, 10, '3670cebc-711e-40a2-961d-d9040cdf6937', 22, 17, 1697.31, 384.77, 1980.14, 90.56, '1995-11-07');
INSERT INTO public.payslip VALUES (44, 3, '360ade6b-9e18-4aaf-baf2-ee27080c3336', 30, 10, 2755.82, 295.51, 2962.31, 76.9, '1991-06-21');
INSERT INTO public.payslip VALUES (45, 39, 'dd58823f-4b55-4692-b851-c54adddac03f', 20, 16, 3244.73, 438.21, 3600.33, 122.83, '2017-02-10');
INSERT INTO public.payslip VALUES (46, 7, 'd3669caa-81d3-45eb-8dda-7114a82d904e', 18, 26, 4989.89, 113.3, 4916.32, 70.69, '1998-07-18');
INSERT INTO public.payslip VALUES (47, 50, 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601', 16, 16, 4267.83, 240.1, 4422.9, 172.05, '1997-03-08');
INSERT INTO public.payslip VALUES (48, 4, '7d937d48-010f-4b4f-bd0b-1a67f68f8185', 5, 12, 3679.48, 343.17, 3919.69, 95.05, '1975-05-26');
INSERT INTO public.payslip VALUES (49, 34, 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36', 24, 4, 3741.69, 228.98, 3836.16, 187.12, '2006-05-28');
INSERT INTO public.payslip VALUES (50, 17, 'fe8d7a50-80bd-49d5-b029-c73642a3f41b', 9, 27, 4963.93, 157.56, 5063.28, 155.54, '2009-07-10');
INSERT INTO public.payslip VALUES (51, 1, '550e8400-e29b-41d4-a716-446655440000', 20, 0, 5000.0, 500.0, 5500.0, 200.0, '2024-01-01');


--
-- TOC entry 3522 (class 0 OID 24609)
-- Dependencies: 222
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.status VALUES (1, 'New', 'Hand east kid oil yeah mean.');
INSERT INTO public.status VALUES (2, 'Computed', 'Television wish score involve up. Guy remember sea wish rule very future include.');


--
-- TOC entry 3541 (class 0 OID 50351)
-- Dependencies: 241
-- Data for Name: user_activity_log; Type: TABLE DATA; Schema: public; Owner: ud_admin
--

INSERT INTO public.user_activity_log VALUES (1, 'create', '2024-04-15 17:04:07', '2d6aa8fc-89b5-402d-928c-244dbb7a10a1');
INSERT INTO public.user_activity_log VALUES (2, 'delete', '2024-01-30 11:25:26', '37922b60-4903-4117-84ca-661ba83f9f97');
INSERT INTO public.user_activity_log VALUES (3, 'update', '2024-01-30 22:24:50', 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858');
INSERT INTO public.user_activity_log VALUES (4, 'delete', '2024-01-20 06:31:53', '37922b60-4903-4117-84ca-661ba83f9f97');
INSERT INTO public.user_activity_log VALUES (5, 'create', '2024-01-04 10:55:56', '5a35b3e2-9782-491b-939b-518df92f5b75');
INSERT INTO public.user_activity_log VALUES (6, 'logout', '2024-01-24 17:07:26', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (7, 'login', '2024-01-01 10:24:16', '93e78342-becc-4395-8049-d0fc028d137c');
INSERT INTO public.user_activity_log VALUES (8, 'update', '2024-04-09 11:10:49', '2d6aa8fc-89b5-402d-928c-244dbb7a10a1');
INSERT INTO public.user_activity_log VALUES (9, 'update', '2024-05-03 16:56:52', 'fe8d7a50-80bd-49d5-b029-c73642a3f41b');
INSERT INTO public.user_activity_log VALUES (10, 'logout', '2024-03-23 22:01:08', 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36');
INSERT INTO public.user_activity_log VALUES (11, 'delete', '2024-01-15 05:55:27', '3e35d982-3067-4349-89db-6740c03ae1dc');
INSERT INTO public.user_activity_log VALUES (12, 'update', '2024-04-01 08:01:34', '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e');
INSERT INTO public.user_activity_log VALUES (13, 'logout', '2024-04-24 14:34:17', 'e4c1c60e-5582-456c-9319-99ac6da65a59');
INSERT INTO public.user_activity_log VALUES (14, 'create', '2024-04-18 17:54:33', '37922b60-4903-4117-84ca-661ba83f9f97');
INSERT INTO public.user_activity_log VALUES (15, 'update', '2024-05-13 00:45:07', '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e');
INSERT INTO public.user_activity_log VALUES (16, 'update', '2024-04-20 03:10:33', 'fcc69a8d-cb2d-423c-a7fc-6ea99b549858');
INSERT INTO public.user_activity_log VALUES (17, 'delete', '2024-04-03 09:42:09', '93e78342-becc-4395-8049-d0fc028d137c');
INSERT INTO public.user_activity_log VALUES (18, 'login', '2024-06-05 12:54:44', '3670cebc-711e-40a2-961d-d9040cdf6937');
INSERT INTO public.user_activity_log VALUES (19, 'update', '2024-05-23 14:33:38', '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e');
INSERT INTO public.user_activity_log VALUES (20, 'update', '2024-04-23 12:31:31', 'e4c1c60e-5582-456c-9319-99ac6da65a59');
INSERT INTO public.user_activity_log VALUES (21, 'logout', '2024-03-19 18:27:16', 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e');
INSERT INTO public.user_activity_log VALUES (22, 'create', '2024-02-26 00:50:08', 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36');
INSERT INTO public.user_activity_log VALUES (23, 'create', '2024-03-21 06:35:06', 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601');
INSERT INTO public.user_activity_log VALUES (24, 'login', '2024-05-09 03:55:49', 'e4c1c60e-5582-456c-9319-99ac6da65a59');
INSERT INTO public.user_activity_log VALUES (25, 'login', '2024-03-31 02:41:21', '37922b60-4903-4117-84ca-661ba83f9f97');
INSERT INTO public.user_activity_log VALUES (26, 'create', '2024-02-05 03:34:15', '9631b51e-3cee-4c4f-b604-23c43c9da9c9');
INSERT INTO public.user_activity_log VALUES (27, 'delete', '2024-04-08 08:43:25', '7d937d48-010f-4b4f-bd0b-1a67f68f8185');
INSERT INTO public.user_activity_log VALUES (28, 'login', '2024-02-18 07:50:02', 'dd58823f-4b55-4692-b851-c54adddac03f');
INSERT INTO public.user_activity_log VALUES (29, 'delete', '2024-02-01 23:13:03', '7d937d48-010f-4b4f-bd0b-1a67f68f8185');
INSERT INTO public.user_activity_log VALUES (30, 'delete', '2024-04-29 22:59:07', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (31, 'update', '2024-04-27 10:10:57', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (32, 'create', '2024-02-06 22:45:32', '3e35d982-3067-4349-89db-6740c03ae1dc');
INSERT INTO public.user_activity_log VALUES (33, 'update', '2024-03-12 20:27:48', '5a35b3e2-9782-491b-939b-518df92f5b75');
INSERT INTO public.user_activity_log VALUES (34, 'update', '2024-03-18 17:40:26', '9631b51e-3cee-4c4f-b604-23c43c9da9c9');
INSERT INTO public.user_activity_log VALUES (35, 'login', '2024-01-16 20:03:03', '5a35b3e2-9782-491b-939b-518df92f5b75');
INSERT INTO public.user_activity_log VALUES (36, 'logout', '2024-04-18 09:28:23', '5a35b3e2-9782-491b-939b-518df92f5b75');
INSERT INTO public.user_activity_log VALUES (37, 'create', '2024-03-05 08:52:56', '5a35b3e2-9782-491b-939b-518df92f5b75');
INSERT INTO public.user_activity_log VALUES (38, 'update', '2024-05-16 05:42:12', 'fe8d7a50-80bd-49d5-b029-c73642a3f41b');
INSERT INTO public.user_activity_log VALUES (39, 'delete', '2024-03-31 06:33:36', '3e35d982-3067-4349-89db-6740c03ae1dc');
INSERT INTO public.user_activity_log VALUES (40, 'delete', '2024-03-12 09:38:58', '3e35d982-3067-4349-89db-6740c03ae1dc');
INSERT INTO public.user_activity_log VALUES (41, 'login', '2024-02-29 21:44:23', '2d6aa8fc-89b5-402d-928c-244dbb7a10a1');
INSERT INTO public.user_activity_log VALUES (42, 'delete', '2024-04-16 20:49:09', 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e');
INSERT INTO public.user_activity_log VALUES (43, 'login', '2024-02-10 17:59:38', 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36');
INSERT INTO public.user_activity_log VALUES (44, 'create', '2024-03-18 15:55:07', 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e');
INSERT INTO public.user_activity_log VALUES (45, 'delete', '2024-04-07 02:25:29', 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e');
INSERT INTO public.user_activity_log VALUES (46, 'login', '2024-04-24 18:39:52', '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e');
INSERT INTO public.user_activity_log VALUES (47, 'update', '2024-02-17 23:35:30', 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763');
INSERT INTO public.user_activity_log VALUES (48, 'delete', '2024-06-01 06:58:24', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (49, 'login', '2024-01-19 13:49:35', 'e4c1c60e-5582-456c-9319-99ac6da65a59');
INSERT INTO public.user_activity_log VALUES (50, 'logout', '2024-01-03 15:55:41', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (51, 'logout', '2024-01-19 01:48:00', 'fe8d7a50-80bd-49d5-b029-c73642a3f41b');
INSERT INTO public.user_activity_log VALUES (52, 'delete', '2024-05-23 02:33:20', '3e35d982-3067-4349-89db-6740c03ae1dc');
INSERT INTO public.user_activity_log VALUES (53, 'logout', '2024-01-12 05:46:47', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (54, 'update', '2024-02-18 07:29:10', 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601');
INSERT INTO public.user_activity_log VALUES (55, 'logout', '2024-02-01 17:29:03', 'e4c1c60e-5582-456c-9319-99ac6da65a59');
INSERT INTO public.user_activity_log VALUES (56, 'logout', '2024-06-07 21:36:50', '2d6aa8fc-89b5-402d-928c-244dbb7a10a1');
INSERT INTO public.user_activity_log VALUES (57, 'logout', '2024-03-07 15:23:45', 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e');
INSERT INTO public.user_activity_log VALUES (58, 'login', '2024-01-06 17:09:52', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (59, 'update', '2024-05-14 09:24:03', '360ade6b-9e18-4aaf-baf2-ee27080c3336');
INSERT INTO public.user_activity_log VALUES (60, 'login', '2024-03-26 15:59:30', '9631b51e-3cee-4c4f-b604-23c43c9da9c9');
INSERT INTO public.user_activity_log VALUES (61, 'logout', '2024-01-06 05:34:23', '93e78342-becc-4395-8049-d0fc028d137c');
INSERT INTO public.user_activity_log VALUES (62, 'create', '2024-06-09 18:09:23', 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be');
INSERT INTO public.user_activity_log VALUES (63, 'update', '2024-04-22 04:39:16', 'dd58823f-4b55-4692-b851-c54adddac03f');
INSERT INTO public.user_activity_log VALUES (64, 'update', '2024-04-19 07:12:28', '5a35b3e2-9782-491b-939b-518df92f5b75');
INSERT INTO public.user_activity_log VALUES (65, 'logout', '2024-05-20 23:06:16', '360ade6b-9e18-4aaf-baf2-ee27080c3336');
INSERT INTO public.user_activity_log VALUES (66, 'create', '2024-03-15 11:03:42', '37922b60-4903-4117-84ca-661ba83f9f97');
INSERT INTO public.user_activity_log VALUES (67, 'logout', '2024-03-09 05:36:06', '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e');
INSERT INTO public.user_activity_log VALUES (68, 'update', '2024-03-11 15:00:33', 'fe8d7a50-80bd-49d5-b029-c73642a3f41b');
INSERT INTO public.user_activity_log VALUES (69, 'login', '2024-01-13 19:52:09', '2d6aa8fc-89b5-402d-928c-244dbb7a10a1');
INSERT INTO public.user_activity_log VALUES (70, 'login', '2024-02-11 02:51:25', '360ade6b-9e18-4aaf-baf2-ee27080c3336');
INSERT INTO public.user_activity_log VALUES (71, 'login', '2024-01-17 22:30:26', '93e78342-becc-4395-8049-d0fc028d137c');
INSERT INTO public.user_activity_log VALUES (72, 'logout', '2024-03-05 19:17:31', 'dd58823f-4b55-4692-b851-c54adddac03f');
INSERT INTO public.user_activity_log VALUES (73, 'login', '2024-04-11 22:36:37', 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601');
INSERT INTO public.user_activity_log VALUES (74, 'update', '2024-05-23 10:58:29', 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be');
INSERT INTO public.user_activity_log VALUES (75, 'login', '2024-02-06 09:00:19', 'd5b6220b-1efb-4c6f-ae0c-484a5cefa7be');
INSERT INTO public.user_activity_log VALUES (76, 'create', '2024-04-23 15:52:46', '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e');
INSERT INTO public.user_activity_log VALUES (77, 'logout', '2024-04-03 06:01:15', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (78, 'delete', '2024-05-30 05:43:51', '37922b60-4903-4117-84ca-661ba83f9f97');
INSERT INTO public.user_activity_log VALUES (79, 'logout', '2024-01-26 06:11:28', '3e35d982-3067-4349-89db-6740c03ae1dc');
INSERT INTO public.user_activity_log VALUES (80, 'create', '2024-02-15 22:27:26', '37922b60-4903-4117-84ca-661ba83f9f97');
INSERT INTO public.user_activity_log VALUES (81, 'create', '2024-01-04 09:27:43', 'd3669caa-81d3-45eb-8dda-7114a82d904e');
INSERT INTO public.user_activity_log VALUES (82, 'login', '2024-05-08 05:23:39', 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36');
INSERT INTO public.user_activity_log VALUES (83, 'create', '2024-01-13 01:01:22', '360ade6b-9e18-4aaf-baf2-ee27080c3336');
INSERT INTO public.user_activity_log VALUES (84, 'update', '2024-03-14 10:10:15', '7d937d48-010f-4b4f-bd0b-1a67f68f8185');
INSERT INTO public.user_activity_log VALUES (85, 'logout', '2024-05-02 08:34:44', 'dd58823f-4b55-4692-b851-c54adddac03f');
INSERT INTO public.user_activity_log VALUES (86, 'update', '2024-02-02 21:21:00', '3e35d982-3067-4349-89db-6740c03ae1dc');
INSERT INTO public.user_activity_log VALUES (87, 'logout', '2024-06-01 18:37:33', 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601');
INSERT INTO public.user_activity_log VALUES (88, 'delete', '2024-02-21 12:56:43', 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601');
INSERT INTO public.user_activity_log VALUES (89, 'create', '2024-04-11 09:47:54', 'bb2435c2-d49b-4d10-a3f6-e323f9465b2e');
INSERT INTO public.user_activity_log VALUES (90, 'update', '2024-04-22 16:28:09', '9631b51e-3cee-4c4f-b604-23c43c9da9c9');
INSERT INTO public.user_activity_log VALUES (91, 'login', '2024-02-09 07:44:26', '9631b51e-3cee-4c4f-b604-23c43c9da9c9');
INSERT INTO public.user_activity_log VALUES (92, 'delete', '2024-05-17 06:27:00', '2d6aa8fc-89b5-402d-928c-244dbb7a10a1');
INSERT INTO public.user_activity_log VALUES (93, 'logout', '2024-01-05 08:36:45', '7d937d48-010f-4b4f-bd0b-1a67f68f8185');
INSERT INTO public.user_activity_log VALUES (94, 'delete', '2024-02-20 11:17:45', '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e');
INSERT INTO public.user_activity_log VALUES (95, 'delete', '2024-06-03 10:45:48', 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36');
INSERT INTO public.user_activity_log VALUES (96, 'update', '2024-05-01 02:18:34', '7d937d48-010f-4b4f-bd0b-1a67f68f8185');
INSERT INTO public.user_activity_log VALUES (97, 'logout', '2024-03-12 07:27:11', 'faa61fb1-d27f-4f3b-b52c-2e7e5227e601');
INSERT INTO public.user_activity_log VALUES (98, 'update', '2024-01-21 13:44:09', '7b5ff0e0-97ec-4f27-9213-d0d90d1e9a1e');
INSERT INTO public.user_activity_log VALUES (99, 'update', '2024-04-10 13:06:00', 'a8ba7013-0f10-4f87-a2fe-6e73dba9bc36');
INSERT INTO public.user_activity_log VALUES (100, 'update', '2024-04-27 13:37:59', 'cc9c66d6-ce4a-42dd-9e93-0a3b8fba4763');
INSERT INTO public.user_activity_log VALUES (101, 'login', '2024-01-01 00:00:00', '550e8400-e29b-41d4-a716-446655440000');


--
-- TOC entry 3564 (class 0 OID 0)
-- Dependencies: 227
-- Name: Position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public."Position_id_seq"', 11, true);


--
-- TOC entry 3565 (class 0 OID 0)
-- Dependencies: 220
-- Name: Role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public."Role_id_seq"', 2, true);


--
-- TOC entry 3566 (class 0 OID 0)
-- Dependencies: 223
-- Name: allowance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.allowance_id_seq', 51, true);


--
-- TOC entry 3567 (class 0 OID 0)
-- Dependencies: 215
-- Name: deduction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.deduction_id_seq', 49, true);


--
-- TOC entry 3568 (class 0 OID 0)
-- Dependencies: 218
-- Name: department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.department_id_seq', 5, true);


--
-- TOC entry 3569 (class 0 OID 0)
-- Dependencies: 236
-- Name: employee_allowances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.employee_allowances_id_seq', 51, true);


--
-- TOC entry 3570 (class 0 OID 0)
-- Dependencies: 238
-- Name: employee_deductions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.employee_deductions_id_seq', 51, true);


--
-- TOC entry 3571 (class 0 OID 0)
-- Dependencies: 230
-- Name: employee_extra_hours_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.employee_extra_hours_id_seq', 36, true);


--
-- TOC entry 3572 (class 0 OID 0)
-- Dependencies: 232
-- Name: payroll_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.payroll_id_seq', 51, true);


--
-- TOC entry 3573 (class 0 OID 0)
-- Dependencies: 225
-- Name: payroll_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.payroll_type_id_seq', 3, true);


--
-- TOC entry 3574 (class 0 OID 0)
-- Dependencies: 234
-- Name: payslip_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.payslip_id_seq', 51, true);


--
-- TOC entry 3575 (class 0 OID 0)
-- Dependencies: 221
-- Name: status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.status_id_seq', 2, true);


--
-- TOC entry 3576 (class 0 OID 0)
-- Dependencies: 240
-- Name: user_activity_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.user_activity_log_id_seq', 101, true);


--
-- TOC entry 3319 (class 2606 OID 24621)
-- Name: allowance allowance_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.allowance
    ADD CONSTRAINT allowance_pk PRIMARY KEY (id);


--
-- TOC entry 3311 (class 2606 OID 24583)
-- Name: deduction deduction_pkey; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.deduction
    ADD CONSTRAINT deduction_pkey PRIMARY KEY (id);


--
-- TOC entry 3315 (class 2606 OID 24595)
-- Name: department department_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pk PRIMARY KEY (id);


--
-- TOC entry 3345 (class 2606 OID 24753)
-- Name: employee_allowances employee_allowances_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_pk PRIMARY KEY (id);


--
-- TOC entry 3347 (class 2606 OID 24778)
-- Name: employee_deductions employee_deductions_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_pk PRIMARY KEY (id);


--
-- TOC entry 3337 (class 2606 OID 24701)
-- Name: employee_extra_hours employee_extra_hours_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_pk PRIMARY KEY (id);


--
-- TOC entry 3327 (class 2606 OID 50152)
-- Name: employee employee_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pk PRIMARY KEY ("UUID");


--
-- TOC entry 3329 (class 2606 OID 24667)
-- Name: employee employee_unique; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique UNIQUE (employee_code);


--
-- TOC entry 3331 (class 2606 OID 24669)
-- Name: employee employee_unique_1; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_1 UNIQUE (email);


--
-- TOC entry 3333 (class 2606 OID 24671)
-- Name: employee employee_unique_2; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_2 UNIQUE (bank_account);


--
-- TOC entry 3335 (class 2606 OID 32770)
-- Name: employee employee_unique_3; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_3 UNIQUE (phone);


--
-- TOC entry 3339 (class 2606 OID 24718)
-- Name: payroll payroll_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_pk PRIMARY KEY (id);


--
-- TOC entry 3321 (class 2606 OID 24644)
-- Name: payroll_type payroll_type_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll_type
    ADD CONSTRAINT payroll_type_pk PRIMARY KEY (id);


--
-- TOC entry 3341 (class 2606 OID 24720)
-- Name: payroll payroll_unique; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_unique UNIQUE (reference_number);


--
-- TOC entry 3343 (class 2606 OID 24734)
-- Name: payslip payslip_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_pk PRIMARY KEY (id);


--
-- TOC entry 3323 (class 2606 OID 24651)
-- Name: Position position_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_pk PRIMARY KEY (id);


--
-- TOC entry 3325 (class 2606 OID 24653)
-- Name: Position position_unique; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_unique UNIQUE (name);


--
-- TOC entry 3313 (class 2606 OID 24607)
-- Name: Role role_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Role"
    ADD CONSTRAINT role_pk PRIMARY KEY (id);


--
-- TOC entry 3317 (class 2606 OID 24614)
-- Name: status status_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pk PRIMARY KEY (id);


--
-- TOC entry 3349 (class 2606 OID 50359)
-- Name: user_activity_log user_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.user_activity_log
    ADD CONSTRAINT user_activity_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3366 (class 2620 OID 50568)
-- Name: employee check_negative_salary; Type: TRIGGER; Schema: public; Owner: ud_admin
--

CREATE TRIGGER check_negative_salary BEFORE INSERT OR UPDATE ON public.employee FOR EACH ROW EXECUTE FUNCTION public.prevent_negative_salary();


--
-- TOC entry 3359 (class 2606 OID 24759)
-- Name: employee_allowances employee_allowances_allowance_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_allowance_fk FOREIGN KEY (allowance_fk) REFERENCES public.allowance(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3360 (class 2606 OID 50173)
-- Name: employee_allowances employee_allowances_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3361 (class 2606 OID 24764)
-- Name: employee_allowances employee_allowances_payroll_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3362 (class 2606 OID 24784)
-- Name: employee_deductions employee_deductions_deduction_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_deduction_fk FOREIGN KEY (deduction_fk) REFERENCES public.deduction(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3363 (class 2606 OID 50178)
-- Name: employee_deductions employee_deductions_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3364 (class 2606 OID 24789)
-- Name: employee_deductions employee_deductions_payroll_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3354 (class 2606 OID 50183)
-- Name: employee_extra_hours employee_extra_hours_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3355 (class 2606 OID 24707)
-- Name: employee_extra_hours employee_extra_hours_payroll_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3351 (class 2606 OID 24674)
-- Name: employee employee_position_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_position_fk FOREIGN KEY (position_fk) REFERENCES public."Position"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3352 (class 2606 OID 58117)
-- Name: employee employee_role_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_role_fk FOREIGN KEY (role_fk) REFERENCES public."Role"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3353 (class 2606 OID 24679)
-- Name: employee employee_status_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_status_fk FOREIGN KEY (status_fk) REFERENCES public.status(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3356 (class 2606 OID 24721)
-- Name: payroll payroll_payroll_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_payroll_type_fk FOREIGN KEY (paroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3357 (class 2606 OID 50188)
-- Name: payslip payslip_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3358 (class 2606 OID 24740)
-- Name: payslip payslip_payroll_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_payroll_fk FOREIGN KEY (payroll_fk) REFERENCES public.payroll(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3350 (class 2606 OID 24654)
-- Name: Position position_department_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_department_fk FOREIGN KEY (department_fk) REFERENCES public.department(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3365 (class 2606 OID 58112)
-- Name: user_activity_log user_activity_log_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.user_activity_log
    ADD CONSTRAINT user_activity_log_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2024-06-11 22:28:59

--
-- PostgreSQL database dump complete
--

