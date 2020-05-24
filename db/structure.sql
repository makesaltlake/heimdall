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
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: delayed_jobs_after_delete_row_tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delayed_jobs_after_delete_row_tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
        running_count integer;
      BEGIN
        IF OLD.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
          IF OLD.id % 20 = 0 THEN
            running_count := (SELECT COUNT(*) FROM (
              SELECT 1 as one FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't' LIMIT OLD.max_concurrent
            ) subquery_for_count);
            IF running_count < OLD.max_concurrent THEN
              UPDATE delayed_jobs SET next_in_strand = 't' WHERE id IN (
                SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
                j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT (OLD.max_concurrent - running_count) FOR UPDATE
              );
            END IF;
          ELSE
            UPDATE delayed_jobs SET next_in_strand = 't' WHERE id =
              (SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
                j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT 1 FOR UPDATE);
          END IF;
        END IF;
        RETURN OLD;
      END;
      $$;


--
-- Name: delayed_jobs_before_insert_row_tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delayed_jobs_before_insert_row_tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF NEW.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
          IF (SELECT COUNT(*) FROM (
              SELECT 1 AS one FROM delayed_jobs WHERE strand = NEW.strand LIMIT NEW.max_concurrent
            ) subquery_for_count) = NEW.max_concurrent THEN
            NEW.next_in_strand := 'f';
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$;


--
-- Name: half_md5_as_bigint(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.half_md5_as_bigint(strand character varying) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
      DECLARE
        strand_md5 bytea;
      BEGIN
        strand_md5 := decode(md5(strand), 'hex');
        RETURN (CAST(get_byte(strand_md5, 0) AS bigint) << 56) +
                                  (CAST(get_byte(strand_md5, 1) AS bigint) << 48) +
                                  (CAST(get_byte(strand_md5, 2) AS bigint) << 40) +
                                  (CAST(get_byte(strand_md5, 3) AS bigint) << 32) +
                                  (CAST(get_byte(strand_md5, 4) AS bigint) << 24) +
                                  (get_byte(strand_md5, 5) << 16) +
                                  (get_byte(strand_md5, 6) << 8) +
                                   get_byte(strand_md5, 7);
      END;
      $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: active_admin_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_admin_comments (
    id bigint NOT NULL,
    namespace character varying,
    body text,
    resource_type character varying,
    resource_id bigint,
    author_type character varying,
    author_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_admin_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_admin_comments_id_seq OWNED BY public.active_admin_comments.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: badge_reader_certifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_reader_certifications (
    id bigint NOT NULL,
    badge_reader_id bigint NOT NULL,
    certification_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: badge_reader_certifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badge_reader_certifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badge_reader_certifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badge_reader_certifications_id_seq OWNED BY public.badge_reader_certifications.id;


--
-- Name: badge_reader_manual_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_reader_manual_users (
    id bigint NOT NULL,
    badge_reader_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: badge_reader_manual_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badge_reader_manual_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badge_reader_manual_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badge_reader_manual_users_id_seq OWNED BY public.badge_reader_manual_users.id;


--
-- Name: badge_readers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_readers (
    id bigint NOT NULL,
    name character varying,
    description text,
    api_token character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    api_token_regenerated_at timestamp without time zone,
    restricted_access boolean DEFAULT false NOT NULL
);


--
-- Name: badge_readers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badge_readers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badge_readers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badge_readers_id_seq OWNED BY public.badge_readers.id;


--
-- Name: badge_scans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_scans (
    id bigint NOT NULL,
    badge_reader_id bigint,
    user_id bigint,
    scanned_at timestamp without time zone,
    submitted_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: badge_scans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badge_scans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badge_scans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badge_scans_id_seq OWNED BY public.badge_scans.id;


--
-- Name: badge_writers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_writers (
    id bigint NOT NULL,
    name character varying,
    description text,
    api_token character varying,
    api_token_regenerated_at timestamp without time zone,
    currently_programming_user_id bigint,
    currently_programming_until timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_programmed_user_id bigint,
    last_programmed_at timestamp without time zone
);


--
-- Name: badge_writers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.badge_writers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: badge_writers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.badge_writers_id_seq OWNED BY public.badge_writers.id;


--
-- Name: certification_instructors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.certification_instructors (
    id bigint NOT NULL,
    certification_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: certification_instructors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.certification_instructors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: certification_instructors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.certification_instructors_id_seq OWNED BY public.certification_instructors.id;


--
-- Name: certification_issuances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.certification_issuances (
    id bigint NOT NULL,
    certification_id bigint NOT NULL,
    user_id bigint NOT NULL,
    issued_at date,
    active boolean DEFAULT true,
    certifier_id bigint,
    notes text,
    revocation_reason text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    revoked_by_id bigint
);


--
-- Name: certification_issuances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.certification_issuances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: certification_issuances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.certification_issuances_id_seq OWNED BY public.certification_issuances.id;


--
-- Name: certifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.certifications (
    id bigint NOT NULL,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: certifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.certifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: certifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.certifications_id_seq OWNED BY public.certifications.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    queue character varying(255) NOT NULL,
    run_at timestamp without time zone NOT NULL,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tag character varying(255),
    max_attempts integer,
    strand character varying(255),
    next_in_strand boolean DEFAULT true NOT NULL,
    source character varying(255),
    max_concurrent integer DEFAULT 1 NOT NULL,
    expires_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.failed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler character varying(512000),
    last_error text,
    queue character varying(255),
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tag character varying(255),
    max_attempts integer,
    strand character varying(255),
    original_job_id bigint,
    source character varying(255),
    expires_at timestamp without time zone
);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: households; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.households (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: households_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.households_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: households_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.households_id_seq OWNED BY public.households.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying,
    super_user boolean DEFAULT false NOT NULL,
    badge_number character varying,
    household_id bigint NOT NULL,
    subscription_active boolean,
    subscription_id character varying,
    subscription_created timestamp without time zone,
    badge_token character varying,
    badge_token_set_at timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    item_type character varying NOT NULL,
    item_id bigint NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object jsonb,
    object_changes jsonb,
    created_at timestamp without time zone,
    metadata jsonb
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: active_admin_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_admin_comments ALTER COLUMN id SET DEFAULT nextval('public.active_admin_comments_id_seq'::regclass);


--
-- Name: badge_reader_certifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_reader_certifications ALTER COLUMN id SET DEFAULT nextval('public.badge_reader_certifications_id_seq'::regclass);


--
-- Name: badge_reader_manual_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_reader_manual_users ALTER COLUMN id SET DEFAULT nextval('public.badge_reader_manual_users_id_seq'::regclass);


--
-- Name: badge_readers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_readers ALTER COLUMN id SET DEFAULT nextval('public.badge_readers_id_seq'::regclass);


--
-- Name: badge_scans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_scans ALTER COLUMN id SET DEFAULT nextval('public.badge_scans_id_seq'::regclass);


--
-- Name: badge_writers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_writers ALTER COLUMN id SET DEFAULT nextval('public.badge_writers_id_seq'::regclass);


--
-- Name: certification_instructors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_instructors ALTER COLUMN id SET DEFAULT nextval('public.certification_instructors_id_seq'::regclass);


--
-- Name: certification_issuances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_issuances ALTER COLUMN id SET DEFAULT nextval('public.certification_issuances_id_seq'::regclass);


--
-- Name: certifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications ALTER COLUMN id SET DEFAULT nextval('public.certifications_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: households id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.households ALTER COLUMN id SET DEFAULT nextval('public.households_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: active_admin_comments active_admin_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_admin_comments
    ADD CONSTRAINT active_admin_comments_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: badge_reader_certifications badge_reader_certifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_reader_certifications
    ADD CONSTRAINT badge_reader_certifications_pkey PRIMARY KEY (id);


--
-- Name: badge_reader_manual_users badge_reader_manual_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_reader_manual_users
    ADD CONSTRAINT badge_reader_manual_users_pkey PRIMARY KEY (id);


--
-- Name: badge_readers badge_readers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_readers
    ADD CONSTRAINT badge_readers_pkey PRIMARY KEY (id);


--
-- Name: badge_scans badge_scans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_scans
    ADD CONSTRAINT badge_scans_pkey PRIMARY KEY (id);


--
-- Name: badge_writers badge_writers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_writers
    ADD CONSTRAINT badge_writers_pkey PRIMARY KEY (id);


--
-- Name: certification_instructors certification_instructors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_instructors
    ADD CONSTRAINT certification_instructors_pkey PRIMARY KEY (id);


--
-- Name: certification_issuances certification_issuances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_issuances
    ADD CONSTRAINT certification_issuances_pkey PRIMARY KEY (id);


--
-- Name: certifications certifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT certifications_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: households households_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.households
    ADD CONSTRAINT households_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: get_delayed_jobs_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX get_delayed_jobs_index ON public.delayed_jobs USING btree (queue, priority, run_at, id) WHERE ((locked_at IS NULL) AND next_in_strand);


--
-- Name: index_active_admin_comments_on_author_type_and_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_admin_comments_on_author_type_and_author_id ON public.active_admin_comments USING btree (author_type, author_id);


--
-- Name: index_active_admin_comments_on_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_admin_comments_on_namespace ON public.active_admin_comments USING btree (namespace);


--
-- Name: index_active_admin_comments_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_admin_comments_on_resource_type_and_resource_id ON public.active_admin_comments USING btree (resource_type, resource_id);


--
-- Name: index_badge_reader_certifications_on_badge_reader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_reader_certifications_on_badge_reader_id ON public.badge_reader_certifications USING btree (badge_reader_id);


--
-- Name: index_badge_reader_certifications_on_certification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_reader_certifications_on_certification_id ON public.badge_reader_certifications USING btree (certification_id);


--
-- Name: index_badge_reader_certifications_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_badge_reader_certifications_unique ON public.badge_reader_certifications USING btree (badge_reader_id, certification_id);


--
-- Name: index_badge_reader_manual_users_on_badge_reader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_reader_manual_users_on_badge_reader_id ON public.badge_reader_manual_users USING btree (badge_reader_id);


--
-- Name: index_badge_reader_manual_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_reader_manual_users_on_user_id ON public.badge_reader_manual_users USING btree (user_id);


--
-- Name: index_badge_reader_manual_users_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_badge_reader_manual_users_unique ON public.badge_reader_manual_users USING btree (badge_reader_id, user_id);


--
-- Name: index_badge_scans_on_badge_reader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_scans_on_badge_reader_id ON public.badge_scans USING btree (badge_reader_id);


--
-- Name: index_badge_scans_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_scans_on_user_id ON public.badge_scans USING btree (user_id);


--
-- Name: index_badge_writers_on_currently_programming_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_writers_on_currently_programming_user_id ON public.badge_writers USING btree (currently_programming_user_id);


--
-- Name: index_badge_writers_on_last_programmed_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_badge_writers_on_last_programmed_user_id ON public.badge_writers USING btree (last_programmed_user_id);


--
-- Name: index_certification_instructors_on_certification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_certification_instructors_on_certification_id ON public.certification_instructors USING btree (certification_id);


--
-- Name: index_certification_instructors_on_certification_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_certification_instructors_on_certification_id_and_user_id ON public.certification_instructors USING btree (certification_id, user_id);


--
-- Name: index_certification_instructors_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_certification_instructors_on_user_id ON public.certification_instructors USING btree (user_id);


--
-- Name: index_certification_issuances_on_certification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_certification_issuances_on_certification_id ON public.certification_issuances USING btree (certification_id);


--
-- Name: index_certification_issuances_on_certification_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_certification_issuances_on_certification_id_and_user_id ON public.certification_issuances USING btree (certification_id, user_id) WHERE (active = true);


--
-- Name: index_certification_issuances_on_certifier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_certification_issuances_on_certifier_id ON public.certification_issuances USING btree (certifier_id);


--
-- Name: index_certification_issuances_on_revoked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_certification_issuances_on_revoked_by_id ON public.certification_issuances USING btree (revoked_by_id);


--
-- Name: index_certification_issuances_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_certification_issuances_on_user_id ON public.certification_issuances USING btree (user_id);


--
-- Name: index_delayed_jobs_on_locked_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_locked_by ON public.delayed_jobs USING btree (locked_by) WHERE (locked_by IS NOT NULL);


--
-- Name: index_delayed_jobs_on_run_at_and_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_run_at_and_tag ON public.delayed_jobs USING btree (run_at, tag);


--
-- Name: index_delayed_jobs_on_strand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_strand ON public.delayed_jobs USING btree (strand, id);


--
-- Name: index_delayed_jobs_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_tag ON public.delayed_jobs USING btree (tag);


--
-- Name: index_users_on_badge_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_badge_token ON public.users USING btree (badge_token);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_household_id ON public.users USING btree (household_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_metadata ON public.versions USING gin (metadata);


--
-- Name: index_versions_on_object; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_object ON public.versions USING gin (object);


--
-- Name: index_versions_on_object_changes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_object_changes ON public.versions USING gin (object_changes);


--
-- Name: delayed_jobs delayed_jobs_after_delete_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON public.delayed_jobs FOR EACH ROW WHEN (((old.strand IS NOT NULL) AND (old.next_in_strand = true))) EXECUTE PROCEDURE public.delayed_jobs_after_delete_row_tr_fn();


--
-- Name: delayed_jobs delayed_jobs_before_insert_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON public.delayed_jobs FOR EACH ROW WHEN ((new.strand IS NOT NULL)) EXECUTE PROCEDURE public.delayed_jobs_before_insert_row_tr_fn();


--
-- Name: certification_issuances fk_rails_21953e8e38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_issuances
    ADD CONSTRAINT fk_rails_21953e8e38 FOREIGN KEY (revoked_by_id) REFERENCES public.users(id);


--
-- Name: badge_reader_certifications fk_rails_2f8bb70c0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_reader_certifications
    ADD CONSTRAINT fk_rails_2f8bb70c0e FOREIGN KEY (badge_reader_id) REFERENCES public.badge_readers(id);


--
-- Name: badge_writers fk_rails_32034669f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_writers
    ADD CONSTRAINT fk_rails_32034669f0 FOREIGN KEY (last_programmed_user_id) REFERENCES public.users(id);


--
-- Name: certification_instructors fk_rails_36d6e25e4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_instructors
    ADD CONSTRAINT fk_rails_36d6e25e4c FOREIGN KEY (certification_id) REFERENCES public.certifications(id);


--
-- Name: badge_reader_manual_users fk_rails_3b64e9d396; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_reader_manual_users
    ADD CONSTRAINT fk_rails_3b64e9d396 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: certification_issuances fk_rails_4e734beac3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_issuances
    ADD CONSTRAINT fk_rails_4e734beac3 FOREIGN KEY (certifier_id) REFERENCES public.users(id);


--
-- Name: users fk_rails_5121351c36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_5121351c36 FOREIGN KEY (household_id) REFERENCES public.households(id);


--
-- Name: certification_issuances fk_rails_68f52511ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_issuances
    ADD CONSTRAINT fk_rails_68f52511ca FOREIGN KEY (certification_id) REFERENCES public.certifications(id);


--
-- Name: badge_scans fk_rails_7d850092c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_scans
    ADD CONSTRAINT fk_rails_7d850092c6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: certification_instructors fk_rails_81b503280a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_instructors
    ADD CONSTRAINT fk_rails_81b503280a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: badge_reader_manual_users fk_rails_ae4ea9e215; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_reader_manual_users
    ADD CONSTRAINT fk_rails_ae4ea9e215 FOREIGN KEY (badge_reader_id) REFERENCES public.badge_readers(id);


--
-- Name: badge_reader_certifications fk_rails_cc4cb2a586; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_reader_certifications
    ADD CONSTRAINT fk_rails_cc4cb2a586 FOREIGN KEY (certification_id) REFERENCES public.certifications(id);


--
-- Name: badge_writers fk_rails_dc219c3789; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_writers
    ADD CONSTRAINT fk_rails_dc219c3789 FOREIGN KEY (currently_programming_user_id) REFERENCES public.users(id);


--
-- Name: badge_scans fk_rails_eccca2d09b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_scans
    ADD CONSTRAINT fk_rails_eccca2d09b FOREIGN KEY (badge_reader_id) REFERENCES public.badge_readers(id);


--
-- Name: certification_issuances fk_rails_f94e62222f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_issuances
    ADD CONSTRAINT fk_rails_f94e62222f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20200509012404'),
('20200509015628'),
('20200509021800'),
('20200509030021'),
('20200509051257'),
('20200509072715'),
('20200509082715'),
('20200509090049'),
('20200509090404'),
('20200509211533'),
('20200511102058'),
('20200511102904'),
('20200511105701'),
('20200516145940'),
('20200516145941'),
('20200516145942'),
('20200516145943'),
('20200516145944'),
('20200516145945'),
('20200516145946'),
('20200516145947'),
('20200516145948'),
('20200516145949'),
('20200516145950'),
('20200516145951'),
('20200516145952'),
('20200516145953'),
('20200516145954'),
('20200516145955'),
('20200516145956'),
('20200516145957'),
('20200516145958'),
('20200516145959'),
('20200516145960'),
('20200516145961'),
('20200516145962'),
('20200516145963'),
('20200516150411'),
('20200523235430'),
('20200524052326'),
('20200524080043'),
('20200524094055'),
('20200524101824'),
('20200524102747');


