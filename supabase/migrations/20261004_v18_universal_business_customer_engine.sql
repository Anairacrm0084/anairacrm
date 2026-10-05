-- V18 Universal Business Commerce + Chat + Customer Journey
BEGIN;

CREATE TABLE IF NOT EXISTS public.anaira_business_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  business_type text NOT NULL,
  transaction_type text NOT NULL CHECK (transaction_type IN ('booking','appointment','order','purchase','enquiry','subscription','donation','membership','service_request','site_visit','shipment')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('draft','pending','payment_pending','confirmed','in_progress','completed','cancelled','failed','expired','refunded')),
  customer_id uuid,
  customer_name text,
  customer_email text,
  customer_phone text,
  scheduled_at timestamptz,
  scheduled_end_at timestamptz,
  currency text NOT NULL DEFAULT 'INR',
  subtotal numeric(14,2) NOT NULL DEFAULT 0,
  discount numeric(14,2) NOT NULL DEFAULT 0,
  tax numeric(14,2) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL DEFAULT 0,
  payment_status text NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid','pending','paid','partial','refunded','failed')),
  payment_method text,
  source text NOT NULL DEFAULT 'public_storefront',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  idempotency_key text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id,idempotency_key)
);
CREATE INDEX IF NOT EXISTS anaira_business_transactions_business_idx ON public.anaira_business_transactions(business_id,created_at DESC);
CREATE INDEX IF NOT EXISTS anaira_business_transactions_status_idx ON public.anaira_business_transactions(business_id,status,scheduled_at);

CREATE TABLE IF NOT EXISTS public.anaira_business_transaction_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES public.anaira_business_transactions(id) ON DELETE CASCADE,
  catalog_item_id uuid,
  name text NOT NULL,
  quantity numeric(12,3) NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price numeric(14,2) NOT NULL DEFAULT 0,
  total_price numeric(14,2) NOT NULL DEFAULT 0,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_business_tx_items_tx_idx ON public.anaira_business_transaction_items(transaction_id);

CREATE TABLE IF NOT EXISTS public.anaira_business_transaction_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES public.anaira_business_transactions(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  from_status text,
  to_status text,
  actor_user_id uuid,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_business_tx_events_tx_idx ON public.anaira_business_transaction_events(transaction_id,created_at DESC);

CREATE TABLE IF NOT EXISTS public.anaira_business_conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  customer_id uuid,
  customer_name text,
  customer_email text,
  customer_phone text,
  transaction_id uuid REFERENCES public.anaira_business_transactions(id) ON DELETE SET NULL,
  subject text,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','assigned','waiting_customer','waiting_business','resolved','closed')),
  assigned_user_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_message_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_business_conversations_business_idx ON public.anaira_business_conversations(business_id,last_message_at DESC);

CREATE TABLE IF NOT EXISTS public.anaira_business_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.anaira_business_conversations(id) ON DELETE CASCADE,
  sender_type text NOT NULL CHECK (sender_type IN ('customer','staff','system')),
  sender_user_id uuid,
  body text NOT NULL,
  attachments jsonb NOT NULL DEFAULT '[]'::jsonb,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_business_messages_conversation_idx ON public.anaira_business_messages(conversation_id,created_at);

ALTER TABLE public.anaira_business_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anaira_business_transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anaira_business_transaction_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anaira_business_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anaira_business_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business tx tenant access" ON public.anaira_business_transactions;
CREATE POLICY "business tx tenant access" ON public.anaira_business_transactions
FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id))
WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));

DROP POLICY IF EXISTS "business tx item tenant access" ON public.anaira_business_transaction_items;
CREATE POLICY "business tx item tenant access" ON public.anaira_business_transaction_items
FOR ALL TO authenticated USING (
  EXISTS (SELECT 1 FROM public.anaira_business_transactions t WHERE t.id=transaction_id AND (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(t.business_id)))
) WITH CHECK (
  EXISTS (SELECT 1 FROM public.anaira_business_transactions t WHERE t.id=transaction_id AND (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(t.business_id)))
);

DROP POLICY IF EXISTS "business tx event tenant access" ON public.anaira_business_transaction_events;
CREATE POLICY "business tx event tenant access" ON public.anaira_business_transaction_events
FOR ALL TO authenticated USING (
  EXISTS (SELECT 1 FROM public.anaira_business_transactions t WHERE t.id=transaction_id AND (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(t.business_id)))
) WITH CHECK (
  EXISTS (SELECT 1 FROM public.anaira_business_transactions t WHERE t.id=transaction_id AND (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(t.business_id)))
);

DROP POLICY IF EXISTS "business conversation tenant access" ON public.anaira_business_conversations;
CREATE POLICY "business conversation tenant access" ON public.anaira_business_conversations
FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id))
WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));

DROP POLICY IF EXISTS "business message tenant access" ON public.anaira_business_messages;
CREATE POLICY "business message tenant access" ON public.anaira_business_messages
FOR ALL TO authenticated USING (
  EXISTS (SELECT 1 FROM public.anaira_business_conversations c WHERE c.id=conversation_id AND (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(c.business_id)))
) WITH CHECK (
  EXISTS (SELECT 1 FROM public.anaira_business_conversations c WHERE c.id=conversation_id AND (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(c.business_id)))
);

CREATE OR REPLACE FUNCTION public.anaira_business_transaction_touch()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at=now(); RETURN NEW; END $$;
DROP TRIGGER IF EXISTS trg_anaira_business_transaction_touch ON public.anaira_business_transactions;
CREATE TRIGGER trg_anaira_business_transaction_touch BEFORE UPDATE ON public.anaira_business_transactions FOR EACH ROW EXECUTE FUNCTION public.anaira_business_transaction_touch();

CREATE OR REPLACE FUNCTION public.anaira_business_conversation_touch()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at=now(); NEW.last_message_at=now(); RETURN NEW; END $$;
DROP TRIGGER IF EXISTS trg_anaira_business_conversation_touch ON public.anaira_business_conversations;
CREATE TRIGGER trg_anaira_business_conversation_touch BEFORE UPDATE ON public.anaira_business_conversations FOR EACH ROW EXECUTE FUNCTION public.anaira_business_conversation_touch();

GRANT SELECT, INSERT, UPDATE ON public.anaira_business_catalog_items TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.anaira_business_transactions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.anaira_business_transaction_items TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.anaira_business_transaction_events TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.anaira_business_conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.anaira_business_messages TO authenticated;

COMMIT;
