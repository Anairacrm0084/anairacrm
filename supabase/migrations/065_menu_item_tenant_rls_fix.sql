-- Fix Business Admin menu item CRUD tenant RLS
drop policy if exists anaira_marketplace_menu_items_tenant on public.anaira_marketplace_menu_items;
create policy anaira_marketplace_menu_items_tenant on public.anaira_marketplace_menu_items
for all to authenticated
using (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id())
with check (public.anaira_current_is_super_admin() or restaurant_id=public.anaira_current_restaurant_id());
create index if not exists anaira_marketplace_menu_items_restaurant_idx
on public.anaira_marketplace_menu_items(restaurant_id,active,display_order);
