import { NextResponse } from "next/server";
import { calculateRoomRate } from "../../../../lib/pricingEngine";

export async function POST(request) {
  try {
    const body = await request.json();
    const result = calculateRoomRate(body);
    return NextResponse.json({ ok: true, result });
  } catch (error) {
    return NextResponse.json({ ok: false, error: error.message }, { status: 400 });
  }
}