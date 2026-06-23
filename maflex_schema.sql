--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 15.8

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: estado_pedido_enum; Type: TYPE; Schema: public; Owner: supabase_admin
--

CREATE TYPE public.estado_pedido_enum AS ENUM (
    'En preparación',
    'Listo para repartir',
    'Completado'
);


ALTER TYPE public.estado_pedido_enum OWNER TO supabase_admin;

--
-- Name: estado_reparto_enum; Type: TYPE; Schema: public; Owner: supabase_admin
--

CREATE TYPE public.estado_reparto_enum AS ENUM (
    'Armando',
    'En curso',
    'Finalizado'
);


ALTER TYPE public.estado_reparto_enum OWNER TO supabase_admin;

--
-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: supabase_admin
--

CREATE FUNCTION public.is_admin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT coalesce(
    (SELECT (raw_app_meta_data ->> 'role') = 'admin'
     FROM auth.users
     WHERE id = auth.uid()),
    false
  );
$$;


ALTER FUNCTION public.is_admin() OWNER TO supabase_admin;

--
-- Name: is_repartidor(); Type: FUNCTION; Schema: public; Owner: supabase_admin
--

CREATE FUNCTION public.is_repartidor() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.repartidores WHERE id = auth.uid()
  );
$$;


ALTER FUNCTION public.is_repartidor() OWNER TO supabase_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: articulos; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.articulos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    categoria_id uuid NOT NULL
);


ALTER TABLE public.articulos OWNER TO supabase_admin;

--
-- Name: TABLE articulos; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON TABLE public.articulos IS 'Representan bultos enteros de logística (sin peso, volumen ni precio).';


--
-- Name: categorias; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.categorias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    parent_id uuid
);


ALTER TABLE public.categorias OWNER TO supabase_admin;

--
-- Name: TABLE categorias; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON TABLE public.categorias IS 'Estructura de árbol libre para clasificar artículos.';


--
-- Name: COLUMN categorias.parent_id; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON COLUMN public.categorias.parent_id IS 'NULL = categoría raíz.';


--
-- Name: chat_incidencias; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.chat_incidencias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reparto_id uuid NOT NULL,
    emisor_id uuid NOT NULL,
    mensaje text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chat_incidencias OWNER TO supabase_admin;

--
-- Name: TABLE chat_incidencias; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON TABLE public.chat_incidencias IS 'Canal de comunicación bidireccional por reparto.';


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.clientes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    direccion_fisica text NOT NULL,
    latitud numeric,
    longitud numeric
);


ALTER TABLE public.clientes OWNER TO supabase_admin;

--
-- Name: TABLE clientes; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON TABLE public.clientes IS 'Sujetos abstractos de logística. No tienen cuenta de usuario.';


--
-- Name: pedido_articulos; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.pedido_articulos (
    pedido_id uuid NOT NULL,
    articulo_id uuid NOT NULL
);


ALTER TABLE public.pedido_articulos OWNER TO supabase_admin;

--
-- Name: TABLE pedido_articulos; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON TABLE public.pedido_articulos IS 'Relación N:M entre pedidos y artículos.';


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.pedidos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cliente_id uuid NOT NULL,
    fecha_estimada_preparacion date,
    estado_informativo public.estado_pedido_enum DEFAULT 'En preparación'::public.estado_pedido_enum NOT NULL
);


ALTER TABLE public.pedidos OWNER TO supabase_admin;

--
-- Name: repartidores; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.repartidores (
    id uuid NOT NULL,
    nombre text NOT NULL,
    estado_disponibilidad boolean DEFAULT true NOT NULL
);


ALTER TABLE public.repartidores OWNER TO supabase_admin;

--
-- Name: TABLE repartidores; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON TABLE public.repartidores IS 'Usuarios reales del sistema. El id se mapea directamente a auth.users.';


--
-- Name: reparto_pedidos; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.reparto_pedidos (
    reparto_id uuid NOT NULL,
    pedido_id uuid NOT NULL
);


ALTER TABLE public.reparto_pedidos OWNER TO supabase_admin;

--
-- Name: TABLE reparto_pedidos; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON TABLE public.reparto_pedidos IS 'Relación N:M entre repartos y pedidos.';


--
-- Name: repartos; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.repartos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    repartidor_id uuid,
    estado_operativo public.estado_reparto_enum DEFAULT 'Armando'::public.estado_reparto_enum NOT NULL,
    fecha_estipulada date,
    costo_km numeric DEFAULT 0 NOT NULL,
    distancia_total_km numeric DEFAULT 0 NOT NULL
);


ALTER TABLE public.repartos OWNER TO supabase_admin;

--
-- Name: ubicacion_repartidores; Type: TABLE; Schema: public; Owner: supabase_admin
--

CREATE TABLE public.ubicacion_repartidores (
    repartidor_id uuid NOT NULL,
    latitud numeric NOT NULL,
    longitud numeric NOT NULL,
    ultima_actualizacion timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ubicacion_repartidores OWNER TO supabase_admin;

--
-- Name: TABLE ubicacion_repartidores; Type: COMMENT; Schema: public; Owner: supabase_admin
--

COMMENT ON TABLE public.ubicacion_repartidores IS 'Posición en vivo más reciente de cada repartidor (UPSERT constante).';


--
-- Name: articulos articulos_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.articulos
    ADD CONSTRAINT articulos_pkey PRIMARY KEY (id);


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- Name: chat_incidencias chat_incidencias_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.chat_incidencias
    ADD CONSTRAINT chat_incidencias_pkey PRIMARY KEY (id);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);


--
-- Name: pedido_articulos pedido_articulos_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.pedido_articulos
    ADD CONSTRAINT pedido_articulos_pkey PRIMARY KEY (pedido_id, articulo_id);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);


--
-- Name: repartidores repartidores_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.repartidores
    ADD CONSTRAINT repartidores_pkey PRIMARY KEY (id);


--
-- Name: reparto_pedidos reparto_pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.reparto_pedidos
    ADD CONSTRAINT reparto_pedidos_pkey PRIMARY KEY (reparto_id, pedido_id);


--
-- Name: repartos repartos_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.repartos
    ADD CONSTRAINT repartos_pkey PRIMARY KEY (id);


--
-- Name: ubicacion_repartidores ubicacion_repartidores_pkey; Type: CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.ubicacion_repartidores
    ADD CONSTRAINT ubicacion_repartidores_pkey PRIMARY KEY (repartidor_id);


--
-- Name: idx_articulos_categoria; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_articulos_categoria ON public.articulos USING btree (categoria_id);


--
-- Name: idx_categorias_parent; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_categorias_parent ON public.categorias USING btree (parent_id);


--
-- Name: idx_chat_incidencias_created; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_chat_incidencias_created ON public.chat_incidencias USING btree (created_at);


--
-- Name: idx_chat_incidencias_reparto; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_chat_incidencias_reparto ON public.chat_incidencias USING btree (reparto_id);


--
-- Name: idx_pedidos_cliente; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_pedidos_cliente ON public.pedidos USING btree (cliente_id);


--
-- Name: idx_pedidos_estado; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_pedidos_estado ON public.pedidos USING btree (estado_informativo);


--
-- Name: idx_repartos_estado; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_repartos_estado ON public.repartos USING btree (estado_operativo);


--
-- Name: idx_repartos_fecha; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_repartos_fecha ON public.repartos USING btree (fecha_estipulada);


--
-- Name: idx_repartos_repartidor; Type: INDEX; Schema: public; Owner: supabase_admin
--

CREATE INDEX idx_repartos_repartidor ON public.repartos USING btree (repartidor_id);


--
-- Name: articulos articulos_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.articulos
    ADD CONSTRAINT articulos_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categorias(id) ON DELETE RESTRICT;


--
-- Name: categorias categorias_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categorias(id) ON DELETE CASCADE;


--
-- Name: chat_incidencias chat_incidencias_emisor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.chat_incidencias
    ADD CONSTRAINT chat_incidencias_emisor_id_fkey FOREIGN KEY (emisor_id) REFERENCES auth.users(id);


--
-- Name: chat_incidencias chat_incidencias_reparto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.chat_incidencias
    ADD CONSTRAINT chat_incidencias_reparto_id_fkey FOREIGN KEY (reparto_id) REFERENCES public.repartos(id) ON DELETE CASCADE;


--
-- Name: pedido_articulos pedido_articulos_articulo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.pedido_articulos
    ADD CONSTRAINT pedido_articulos_articulo_id_fkey FOREIGN KEY (articulo_id) REFERENCES public.articulos(id) ON DELETE RESTRICT;


--
-- Name: pedido_articulos pedido_articulos_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.pedido_articulos
    ADD CONSTRAINT pedido_articulos_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id) ON DELETE CASCADE;


--
-- Name: pedidos pedidos_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE RESTRICT;


--
-- Name: repartidores repartidores_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.repartidores
    ADD CONSTRAINT repartidores_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: reparto_pedidos reparto_pedidos_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.reparto_pedidos
    ADD CONSTRAINT reparto_pedidos_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id) ON DELETE CASCADE;


--
-- Name: reparto_pedidos reparto_pedidos_reparto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.reparto_pedidos
    ADD CONSTRAINT reparto_pedidos_reparto_id_fkey FOREIGN KEY (reparto_id) REFERENCES public.repartos(id) ON DELETE CASCADE;


--
-- Name: repartos repartos_repartidor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.repartos
    ADD CONSTRAINT repartos_repartidor_id_fkey FOREIGN KEY (repartidor_id) REFERENCES public.repartidores(id) ON DELETE SET NULL;


--
-- Name: ubicacion_repartidores ubicacion_repartidores_repartidor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: supabase_admin
--

ALTER TABLE ONLY public.ubicacion_repartidores
    ADD CONSTRAINT ubicacion_repartidores_repartidor_id_fkey FOREIGN KEY (repartidor_id) REFERENCES public.repartidores(id) ON DELETE CASCADE;


--
-- Name: articulos admin_all_articulos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_articulos ON public.articulos USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: categorias admin_all_categorias; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_categorias ON public.categorias USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: chat_incidencias admin_all_chat_incidencias; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_chat_incidencias ON public.chat_incidencias USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: clientes admin_all_clientes; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_clientes ON public.clientes USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: pedido_articulos admin_all_pedido_articulos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_pedido_articulos ON public.pedido_articulos USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: pedidos admin_all_pedidos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_pedidos ON public.pedidos USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: repartidores admin_all_repartidores; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_repartidores ON public.repartidores USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: reparto_pedidos admin_all_reparto_pedidos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_reparto_pedidos ON public.reparto_pedidos USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: repartos admin_all_repartos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_repartos ON public.repartos USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: ubicacion_repartidores admin_all_ubicacion_repartidores; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY admin_all_ubicacion_repartidores ON public.ubicacion_repartidores USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- Name: articulos; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.articulos ENABLE ROW LEVEL SECURITY;

--
-- Name: categorias; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;

--
-- Name: chat_incidencias; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.chat_incidencias ENABLE ROW LEVEL SECURITY;

--
-- Name: clientes; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

--
-- Name: pedido_articulos; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.pedido_articulos ENABLE ROW LEVEL SECURITY;

--
-- Name: pedidos; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;

--
-- Name: chat_incidencias repartidor_insert_chat; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_insert_chat ON public.chat_incidencias FOR INSERT WITH CHECK (((emisor_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.repartos
  WHERE ((repartos.id = chat_incidencias.reparto_id) AND (repartos.repartidor_id = auth.uid()))))));


--
-- Name: ubicacion_repartidores repartidor_insert_ubicacion; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_insert_ubicacion ON public.ubicacion_repartidores FOR INSERT WITH CHECK ((repartidor_id = auth.uid()));


--
-- Name: articulos repartidor_select_articulos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_articulos ON public.articulos FOR SELECT USING (public.is_repartidor());


--
-- Name: categorias repartidor_select_categorias; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_categorias ON public.categorias FOR SELECT USING (public.is_repartidor());


--
-- Name: chat_incidencias repartidor_select_chat; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_chat ON public.chat_incidencias FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.repartos
  WHERE ((repartos.id = chat_incidencias.reparto_id) AND (repartos.repartidor_id = auth.uid())))));


--
-- Name: clientes repartidor_select_clientes; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_clientes ON public.clientes FOR SELECT USING (public.is_repartidor());


--
-- Name: pedido_articulos repartidor_select_pedido_articulos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_pedido_articulos ON public.pedido_articulos FOR SELECT USING ((EXISTS ( SELECT 1
   FROM (public.reparto_pedidos
     JOIN public.repartos ON ((repartos.id = reparto_pedidos.reparto_id)))
  WHERE ((reparto_pedidos.pedido_id = pedido_articulos.pedido_id) AND (repartos.repartidor_id = auth.uid())))));


--
-- Name: pedidos repartidor_select_pedidos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_pedidos ON public.pedidos FOR SELECT USING ((EXISTS ( SELECT 1
   FROM (public.reparto_pedidos
     JOIN public.repartos ON ((repartos.id = reparto_pedidos.reparto_id)))
  WHERE ((reparto_pedidos.pedido_id = pedidos.id) AND (repartos.repartidor_id = auth.uid())))));


--
-- Name: reparto_pedidos repartidor_select_reparto_pedidos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_reparto_pedidos ON public.reparto_pedidos FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.repartos
  WHERE ((repartos.id = reparto_pedidos.reparto_id) AND (repartos.repartidor_id = auth.uid())))));


--
-- Name: repartos repartidor_select_repartos; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_repartos ON public.repartos FOR SELECT USING ((repartidor_id = auth.uid()));


--
-- Name: repartidores repartidor_select_self; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_self ON public.repartidores FOR SELECT USING ((auth.uid() = id));


--
-- Name: ubicacion_repartidores repartidor_select_ubicacion; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_select_ubicacion ON public.ubicacion_repartidores FOR SELECT USING ((repartidor_id = auth.uid()));


--
-- Name: ubicacion_repartidores repartidor_update_ubicacion; Type: POLICY; Schema: public; Owner: supabase_admin
--

CREATE POLICY repartidor_update_ubicacion ON public.ubicacion_repartidores FOR UPDATE USING ((repartidor_id = auth.uid())) WITH CHECK ((repartidor_id = auth.uid()));


--
-- Name: repartidores; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.repartidores ENABLE ROW LEVEL SECURITY;

--
-- Name: reparto_pedidos; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.reparto_pedidos ENABLE ROW LEVEL SECURITY;

--
-- Name: repartos; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.repartos ENABLE ROW LEVEL SECURITY;

--
-- Name: ubicacion_repartidores; Type: ROW SECURITY; Schema: public; Owner: supabase_admin
--

ALTER TABLE public.ubicacion_repartidores ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION is_admin(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.is_admin() TO postgres;
GRANT ALL ON FUNCTION public.is_admin() TO anon;
GRANT ALL ON FUNCTION public.is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.is_admin() TO service_role;


--
-- Name: FUNCTION is_repartidor(); Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION public.is_repartidor() TO postgres;
GRANT ALL ON FUNCTION public.is_repartidor() TO anon;
GRANT ALL ON FUNCTION public.is_repartidor() TO authenticated;
GRANT ALL ON FUNCTION public.is_repartidor() TO service_role;


--
-- Name: TABLE articulos; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.articulos TO postgres;
GRANT ALL ON TABLE public.articulos TO anon;
GRANT ALL ON TABLE public.articulos TO authenticated;
GRANT ALL ON TABLE public.articulos TO service_role;


--
-- Name: TABLE categorias; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.categorias TO postgres;
GRANT ALL ON TABLE public.categorias TO anon;
GRANT ALL ON TABLE public.categorias TO authenticated;
GRANT ALL ON TABLE public.categorias TO service_role;


--
-- Name: TABLE chat_incidencias; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.chat_incidencias TO postgres;
GRANT ALL ON TABLE public.chat_incidencias TO anon;
GRANT ALL ON TABLE public.chat_incidencias TO authenticated;
GRANT ALL ON TABLE public.chat_incidencias TO service_role;


--
-- Name: TABLE clientes; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.clientes TO postgres;
GRANT ALL ON TABLE public.clientes TO anon;
GRANT ALL ON TABLE public.clientes TO authenticated;
GRANT ALL ON TABLE public.clientes TO service_role;


--
-- Name: TABLE pedido_articulos; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.pedido_articulos TO postgres;
GRANT ALL ON TABLE public.pedido_articulos TO anon;
GRANT ALL ON TABLE public.pedido_articulos TO authenticated;
GRANT ALL ON TABLE public.pedido_articulos TO service_role;


--
-- Name: TABLE pedidos; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.pedidos TO postgres;
GRANT ALL ON TABLE public.pedidos TO anon;
GRANT ALL ON TABLE public.pedidos TO authenticated;
GRANT ALL ON TABLE public.pedidos TO service_role;


--
-- Name: TABLE repartidores; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.repartidores TO postgres;
GRANT ALL ON TABLE public.repartidores TO anon;
GRANT ALL ON TABLE public.repartidores TO authenticated;
GRANT ALL ON TABLE public.repartidores TO service_role;


--
-- Name: TABLE reparto_pedidos; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.reparto_pedidos TO postgres;
GRANT ALL ON TABLE public.reparto_pedidos TO anon;
GRANT ALL ON TABLE public.reparto_pedidos TO authenticated;
GRANT ALL ON TABLE public.reparto_pedidos TO service_role;


--
-- Name: TABLE repartos; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.repartos TO postgres;
GRANT ALL ON TABLE public.repartos TO anon;
GRANT ALL ON TABLE public.repartos TO authenticated;
GRANT ALL ON TABLE public.repartos TO service_role;


--
-- Name: TABLE ubicacion_repartidores; Type: ACL; Schema: public; Owner: supabase_admin
--

GRANT ALL ON TABLE public.ubicacion_repartidores TO postgres;
GRANT ALL ON TABLE public.ubicacion_repartidores TO anon;
GRANT ALL ON TABLE public.ubicacion_repartidores TO authenticated;
GRANT ALL ON TABLE public.ubicacion_repartidores TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- PostgreSQL database dump complete
--

