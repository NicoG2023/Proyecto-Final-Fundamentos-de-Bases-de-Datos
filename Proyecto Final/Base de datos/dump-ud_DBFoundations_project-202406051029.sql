--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2 (Debian 16.2-1.pgdg120+2)
-- Dumped by pg_dump version 16.2

-- Started on 2024-06-05 10:29:23

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
-- TOC entry 3511 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 229 (class 1259 OID 24646)
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
-- TOC entry 228 (class 1259 OID 24645)
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
-- TOC entry 3512 (class 0 OID 0)
-- Dependencies: 228
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
-- TOC entry 3513 (class 0 OID 0)
-- Dependencies: 220
-- Name: Role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public."Role_id_seq" OWNED BY public."Role".id;


--
-- TOC entry 225 (class 1259 OID 24622)
-- Name: User; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public."User" (
    "UUID" text NOT NULL,
    name character varying(80) NOT NULL,
    password text NOT NULL,
    username character varying(50) NOT NULL,
    role_fk integer NOT NULL
);


ALTER TABLE public."User" OWNER TO ud_admin;

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
-- TOC entry 3514 (class 0 OID 0)
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
-- TOC entry 3515 (class 0 OID 0)
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
-- TOC entry 3516 (class 0 OID 0)
-- Dependencies: 218
-- Name: department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.department_id_seq OWNED BY public.department.id;


--
-- TOC entry 230 (class 1259 OID 24659)
-- Name: employee; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.employee (
    "UUID" text NOT NULL,
    employee_code character varying(10) NOT NULL,
    name character varying(200) NOT NULL,
    position_fk integer NOT NULL,
    lastname character varying(200) NOT NULL,
    email character varying(100) NOT NULL,
    status_fk integer NOT NULL,
    bank_account text NOT NULL,
    salary numeric NOT NULL,
    phone integer NOT NULL
);


ALTER TABLE public.employee OWNER TO ud_admin;

--
-- TOC entry 238 (class 1259 OID 24746)
-- Name: employee_allowances; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.employee_allowances (
    id integer NOT NULL,
    employee_fk text NOT NULL,
    allowance_fk integer NOT NULL,
    payroll_type_fk integer NOT NULL,
    effective_date character varying NOT NULL,
    date_created bigint NOT NULL,
    amount numeric NOT NULL
);


ALTER TABLE public.employee_allowances OWNER TO ud_admin;

--
-- TOC entry 3517 (class 0 OID 0)
-- Dependencies: 238
-- Name: COLUMN employee_allowances.amount; Type: COMMENT; Schema: public; Owner: ud_admin
--

COMMENT ON COLUMN public.employee_allowances.amount IS 'es el precio y datos de un solo allowance de los varios que puede tener un empleado';


--
-- TOC entry 237 (class 1259 OID 24745)
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
-- TOC entry 3518 (class 0 OID 0)
-- Dependencies: 237
-- Name: employee_allowances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.employee_allowances_id_seq OWNED BY public.employee_allowances.id;


--
-- TOC entry 240 (class 1259 OID 24771)
-- Name: employee_deductions; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.employee_deductions (
    id integer NOT NULL,
    employee_fk text NOT NULL,
    deduction_fk integer NOT NULL,
    payroll_type_fk integer NOT NULL,
    amount numeric NOT NULL,
    effective_date date NOT NULL,
    date_created bigint NOT NULL
);


ALTER TABLE public.employee_deductions OWNER TO ud_admin;

--
-- TOC entry 3519 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN employee_deductions.amount; Type: COMMENT; Schema: public; Owner: ud_admin
--

COMMENT ON COLUMN public.employee_deductions.amount IS 'precio y datos de uno de los varios deductions que puede tener un empleado';


--
-- TOC entry 239 (class 1259 OID 24770)
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
-- TOC entry 3520 (class 0 OID 0)
-- Dependencies: 239
-- Name: employee_deductions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.employee_deductions_id_seq OWNED BY public.employee_deductions.id;


--
-- TOC entry 232 (class 1259 OID 24694)
-- Name: employee_extra_hours; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.employee_extra_hours (
    id integer NOT NULL,
    hours smallint NOT NULL,
    amount numeric NOT NULL,
    effective_date date NOT NULL,
    date_created bigint NOT NULL,
    employee_fk text,
    payroll_type_fk integer NOT NULL
);


ALTER TABLE public.employee_extra_hours OWNER TO ud_admin;

--
-- TOC entry 231 (class 1259 OID 24693)
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
-- TOC entry 3521 (class 0 OID 0)
-- Dependencies: 231
-- Name: employee_extra_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.employee_extra_hours_id_seq OWNED BY public.employee_extra_hours.id;


--
-- TOC entry 234 (class 1259 OID 24713)
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
-- TOC entry 233 (class 1259 OID 24712)
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
-- TOC entry 3522 (class 0 OID 0)
-- Dependencies: 233
-- Name: payroll_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.payroll_id_seq OWNED BY public.payroll.id;


--
-- TOC entry 227 (class 1259 OID 24639)
-- Name: payroll_type; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.payroll_type (
    id integer NOT NULL,
    name character varying(80) NOT NULL
);


ALTER TABLE public.payroll_type OWNER TO ud_admin;

--
-- TOC entry 226 (class 1259 OID 24638)
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
-- TOC entry 3523 (class 0 OID 0)
-- Dependencies: 226
-- Name: payroll_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.payroll_type_id_seq OWNED BY public.payroll_type.id;


--
-- TOC entry 236 (class 1259 OID 24727)
-- Name: payslip; Type: TABLE; Schema: public; Owner: ud_admin
--

CREATE TABLE public.payslip (
    id integer NOT NULL,
    payroll_fk integer NOT NULL,
    employee_fk text NOT NULL,
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
-- TOC entry 3524 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN payslip.net; Type: COMMENT; Schema: public; Owner: ud_admin
--

COMMENT ON COLUMN public.payslip.net IS 'Salario total del empleado sumado y restado allowances y deductions';


--
-- TOC entry 235 (class 1259 OID 24726)
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
-- TOC entry 3525 (class 0 OID 0)
-- Dependencies: 235
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
-- TOC entry 3526 (class 0 OID 0)
-- Dependencies: 221
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ud_admin
--

ALTER SEQUENCE public.status_id_seq OWNED BY public.status.id;


--
-- TOC entry 3272 (class 2604 OID 24649)
-- Name: Position id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Position" ALTER COLUMN id SET DEFAULT nextval('public."Position_id_seq"'::regclass);


--
-- TOC entry 3267 (class 2604 OID 24602)
-- Name: Role id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Role" ALTER COLUMN id SET DEFAULT nextval('public."Role_id_seq"'::regclass);


--
-- TOC entry 3270 (class 2604 OID 24619)
-- Name: allowance id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.allowance ALTER COLUMN id SET DEFAULT nextval('public.allowance_id_seq'::regclass);


--
-- TOC entry 3266 (class 2604 OID 24581)
-- Name: deduction id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.deduction ALTER COLUMN id SET DEFAULT nextval('public.deduction_id_seq'::regclass);


--
-- TOC entry 3268 (class 2604 OID 24593)
-- Name: department id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.department ALTER COLUMN id SET DEFAULT nextval('public.department_id_seq'::regclass);


--
-- TOC entry 3276 (class 2604 OID 24749)
-- Name: employee_allowances id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances ALTER COLUMN id SET DEFAULT nextval('public.employee_allowances_id_seq'::regclass);


--
-- TOC entry 3277 (class 2604 OID 24774)
-- Name: employee_deductions id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions ALTER COLUMN id SET DEFAULT nextval('public.employee_deductions_id_seq'::regclass);


--
-- TOC entry 3273 (class 2604 OID 24697)
-- Name: employee_extra_hours id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_extra_hours ALTER COLUMN id SET DEFAULT nextval('public.employee_extra_hours_id_seq'::regclass);


--
-- TOC entry 3274 (class 2604 OID 24716)
-- Name: payroll id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll ALTER COLUMN id SET DEFAULT nextval('public.payroll_id_seq'::regclass);


--
-- TOC entry 3271 (class 2604 OID 24642)
-- Name: payroll_type id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll_type ALTER COLUMN id SET DEFAULT nextval('public.payroll_type_id_seq'::regclass);


--
-- TOC entry 3275 (class 2604 OID 24730)
-- Name: payslip id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payslip ALTER COLUMN id SET DEFAULT nextval('public.payslip_id_seq'::regclass);


--
-- TOC entry 3269 (class 2604 OID 24612)
-- Name: status id; Type: DEFAULT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.status ALTER COLUMN id SET DEFAULT nextval('public.status_id_seq'::regclass);


--
-- TOC entry 3494 (class 0 OID 24646)
-- Dependencies: 229
-- Data for Name: Position; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3482 (class 0 OID 24584)
-- Dependencies: 217
-- Data for Name: Role; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3490 (class 0 OID 24622)
-- Dependencies: 225
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3489 (class 0 OID 24616)
-- Dependencies: 224
-- Data for Name: allowance; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3481 (class 0 OID 24578)
-- Dependencies: 216
-- Data for Name: deduction; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3484 (class 0 OID 24590)
-- Dependencies: 219
-- Data for Name: department; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3495 (class 0 OID 24659)
-- Dependencies: 230
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3503 (class 0 OID 24746)
-- Dependencies: 238
-- Data for Name: employee_allowances; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3505 (class 0 OID 24771)
-- Dependencies: 240
-- Data for Name: employee_deductions; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3497 (class 0 OID 24694)
-- Dependencies: 232
-- Data for Name: employee_extra_hours; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3499 (class 0 OID 24713)
-- Dependencies: 234
-- Data for Name: payroll; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3492 (class 0 OID 24639)
-- Dependencies: 227
-- Data for Name: payroll_type; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3501 (class 0 OID 24727)
-- Dependencies: 236
-- Data for Name: payslip; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3487 (class 0 OID 24609)
-- Dependencies: 222
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: ud_admin
--



--
-- TOC entry 3527 (class 0 OID 0)
-- Dependencies: 228
-- Name: Position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public."Position_id_seq"', 1, false);


--
-- TOC entry 3528 (class 0 OID 0)
-- Dependencies: 220
-- Name: Role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public."Role_id_seq"', 1, false);


--
-- TOC entry 3529 (class 0 OID 0)
-- Dependencies: 223
-- Name: allowance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.allowance_id_seq', 1, false);


--
-- TOC entry 3530 (class 0 OID 0)
-- Dependencies: 215
-- Name: deduction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.deduction_id_seq', 1, false);


--
-- TOC entry 3531 (class 0 OID 0)
-- Dependencies: 218
-- Name: department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.department_id_seq', 1, false);


--
-- TOC entry 3532 (class 0 OID 0)
-- Dependencies: 237
-- Name: employee_allowances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.employee_allowances_id_seq', 1, false);


--
-- TOC entry 3533 (class 0 OID 0)
-- Dependencies: 239
-- Name: employee_deductions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.employee_deductions_id_seq', 1, false);


--
-- TOC entry 3534 (class 0 OID 0)
-- Dependencies: 231
-- Name: employee_extra_hours_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.employee_extra_hours_id_seq', 1, false);


--
-- TOC entry 3535 (class 0 OID 0)
-- Dependencies: 233
-- Name: payroll_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.payroll_id_seq', 1, false);


--
-- TOC entry 3536 (class 0 OID 0)
-- Dependencies: 226
-- Name: payroll_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.payroll_type_id_seq', 1, false);


--
-- TOC entry 3537 (class 0 OID 0)
-- Dependencies: 235
-- Name: payslip_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.payslip_id_seq', 1, false);


--
-- TOC entry 3538 (class 0 OID 0)
-- Dependencies: 221
-- Name: status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ud_admin
--

SELECT pg_catalog.setval('public.status_id_seq', 1, false);


--
-- TOC entry 3287 (class 2606 OID 24621)
-- Name: allowance allowance_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.allowance
    ADD CONSTRAINT allowance_pk PRIMARY KEY (id);


--
-- TOC entry 3279 (class 2606 OID 24583)
-- Name: deduction deduction_pkey; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.deduction
    ADD CONSTRAINT deduction_pkey PRIMARY KEY (id);


--
-- TOC entry 3283 (class 2606 OID 24595)
-- Name: department department_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pk PRIMARY KEY (id);


--
-- TOC entry 3319 (class 2606 OID 24753)
-- Name: employee_allowances employee_allowances_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_pk PRIMARY KEY (id);


--
-- TOC entry 3321 (class 2606 OID 24778)
-- Name: employee_deductions employee_deductions_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_pk PRIMARY KEY (id);


--
-- TOC entry 3311 (class 2606 OID 24701)
-- Name: employee_extra_hours employee_extra_hours_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_pk PRIMARY KEY (id);


--
-- TOC entry 3301 (class 2606 OID 24665)
-- Name: employee employee_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pk PRIMARY KEY ("UUID");


--
-- TOC entry 3303 (class 2606 OID 24667)
-- Name: employee employee_unique; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique UNIQUE (employee_code);


--
-- TOC entry 3305 (class 2606 OID 24669)
-- Name: employee employee_unique_1; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_1 UNIQUE (email);


--
-- TOC entry 3307 (class 2606 OID 24671)
-- Name: employee employee_unique_2; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_2 UNIQUE (bank_account);


--
-- TOC entry 3309 (class 2606 OID 24673)
-- Name: employee employee_unique_3; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_unique_3 UNIQUE (phone);


--
-- TOC entry 3313 (class 2606 OID 24718)
-- Name: payroll payroll_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_pk PRIMARY KEY (id);


--
-- TOC entry 3295 (class 2606 OID 24644)
-- Name: payroll_type payroll_type_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll_type
    ADD CONSTRAINT payroll_type_pk PRIMARY KEY (id);


--
-- TOC entry 3315 (class 2606 OID 24720)
-- Name: payroll payroll_unique; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_unique UNIQUE (reference_number);


--
-- TOC entry 3317 (class 2606 OID 24734)
-- Name: payslip payslip_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_pk PRIMARY KEY (id);


--
-- TOC entry 3297 (class 2606 OID 24651)
-- Name: Position position_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_pk PRIMARY KEY (id);


--
-- TOC entry 3299 (class 2606 OID 24653)
-- Name: Position position_unique; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_unique UNIQUE (name);


--
-- TOC entry 3281 (class 2606 OID 24607)
-- Name: Role role_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Role"
    ADD CONSTRAINT role_pk PRIMARY KEY (id);


--
-- TOC entry 3285 (class 2606 OID 24614)
-- Name: status status_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pk PRIMARY KEY (id);


--
-- TOC entry 3289 (class 2606 OID 24628)
-- Name: User user_pk; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT user_pk PRIMARY KEY ("UUID");


--
-- TOC entry 3291 (class 2606 OID 24630)
-- Name: User user_unique; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT user_unique UNIQUE (password);


--
-- TOC entry 3293 (class 2606 OID 24632)
-- Name: User user_unique_1; Type: CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT user_unique_1 UNIQUE (username);


--
-- TOC entry 3331 (class 2606 OID 24759)
-- Name: employee_allowances employee_allowances_allowance_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_allowance_fk FOREIGN KEY (allowance_fk) REFERENCES public.allowance(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3332 (class 2606 OID 24754)
-- Name: employee_allowances employee_allowances_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3333 (class 2606 OID 24764)
-- Name: employee_allowances employee_allowances_payroll_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_allowances
    ADD CONSTRAINT employee_allowances_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3334 (class 2606 OID 24784)
-- Name: employee_deductions employee_deductions_deduction_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_deduction_fk FOREIGN KEY (deduction_fk) REFERENCES public.deduction(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3335 (class 2606 OID 24779)
-- Name: employee_deductions employee_deductions_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3336 (class 2606 OID 24789)
-- Name: employee_deductions employee_deductions_payroll_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_deductions
    ADD CONSTRAINT employee_deductions_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3326 (class 2606 OID 24702)
-- Name: employee_extra_hours employee_extra_hours_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3327 (class 2606 OID 24707)
-- Name: employee_extra_hours employee_extra_hours_payroll_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee_extra_hours
    ADD CONSTRAINT employee_extra_hours_payroll_type_fk FOREIGN KEY (payroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3324 (class 2606 OID 24674)
-- Name: employee employee_position_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_position_fk FOREIGN KEY (position_fk) REFERENCES public."Position"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3325 (class 2606 OID 24679)
-- Name: employee employee_status_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_status_fk FOREIGN KEY (status_fk) REFERENCES public.status(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3328 (class 2606 OID 24721)
-- Name: payroll payroll_payroll_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_payroll_type_fk FOREIGN KEY (paroll_type_fk) REFERENCES public.payroll_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3329 (class 2606 OID 24735)
-- Name: payslip payslip_employee_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_employee_fk FOREIGN KEY (employee_fk) REFERENCES public.employee("UUID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3330 (class 2606 OID 24740)
-- Name: payslip payslip_payroll_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public.payslip
    ADD CONSTRAINT payslip_payroll_fk FOREIGN KEY (payroll_fk) REFERENCES public.payroll(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3323 (class 2606 OID 24654)
-- Name: Position position_department_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT position_department_fk FOREIGN KEY (department_fk) REFERENCES public.department(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3322 (class 2606 OID 24633)
-- Name: User user_role_fk; Type: FK CONSTRAINT; Schema: public; Owner: ud_admin
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT user_role_fk FOREIGN KEY (role_fk) REFERENCES public."Role"(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2024-06-05 10:29:23

--
-- PostgreSQL database dump complete
--

