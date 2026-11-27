-- Tighten the newly replaced marketplace SECURITY DEFINER RPCs.
alter function public.anaira_marketplace_hotel_search(date,date,integer,integer,text) set search_path='';
alter function public.anaira_marketplace_stay_search(text,date,date,integer,integer,text) set search_path='';
alter function public.anaira_marketplace_camp_search(date,date,integer,integer,text) set search_path='';
alter function public.anaira_marketplace_hms_hospitality_search(text,date,date,integer,integer,text) set search_path='';

grant execute on function public.anaira_marketplace_hotel_search(date,date,integer,integer,text) to service_role;
grant execute on function public.anaira_marketplace_stay_search(text,date,date,integer,integer,text) to service_role;
grant execute on function public.anaira_marketplace_camp_search(date,date,integer,integer,text) to service_role;
grant execute on function public.anaira_marketplace_hms_hospitality_search(text,date,date,integer,integer,text) to service_role;

create index if not exists ana_platform_store_marketplace_approved_by_idx
  on public.anaira_platform_stores(marketplace_approved_by)
  where marketplace_approved_by is not null;
