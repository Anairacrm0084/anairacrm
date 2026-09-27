-- ANAIRA marketplace -> POS bridge.
-- The marketplace never becomes the restaurant operational order owner.
-- Anaira POS remains the canonical KOT/KDS/billing engine; this queue is the integration contract.
create or replace function public.anaira_enqueue_delivery_order_to_pos()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.anaira_pos_sync_queue(restaurant_id,delivery_order_id,event_type,status,payload)
  values(new.restaurant_id,new.id,'order.created','queued',jsonb_build_object('delivery_order_id',new.id,'order_code',new.order_code,'source',new.source,'status',new.status,'payment_status',new.payment_status,'subtotal',new.subtotal,'total_amount',new.total_amount,'customer_id',new.customer_id));
  return new;
end; $$;
drop trigger if exists anaira_delivery_order_pos_bridge on public.delivery_orders;
create trigger anaira_delivery_order_pos_bridge after insert on public.delivery_orders for each row execute function public.anaira_enqueue_delivery_order_to_pos();
