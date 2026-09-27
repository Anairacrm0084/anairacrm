import { NextResponse } from "next/server";
import { supabase } from "../../../../lib/supabase";

export async function GET(request) {
  if (!supabase) return NextResponse.json({ ok:false, error:"Supabase env is missing" }, {status:500});
  const { searchParams } = new URL(request.url);
  const q = searchParams.get("q") || "";
  let query = supabase.from("crm_customers").select("*").order("created_at",{ascending:false}).limit(100);
  if (q) query = query.or(`full_name.ilike.%${q}%,phone.ilike.%${q}%,email.ilike.%${q}%`);
  const {data,error} = await query;
  if (error) return NextResponse.json({ok:false,error:error.message},{status:400});
  return NextResponse.json({ok:true,data});
}

export async function POST(request) {
  if (!supabase) return NextResponse.json({ok:false,error:"Supabase env is missing"},{status:500});
  const body = await request.json();
  const {data,error} = await supabase.from("crm_customers").insert({
    full_name: body.full_name,
    phone: body.phone || null,
    email: body.email || null,
    customer_type: body.customer_type || "guest",
    notes: body.notes || null
  }).select("*").single();
  if (error) return NextResponse.json({ok:false,error:error.message},{status:400});
  return NextResponse.json({ok:true,data},{status:201});
}