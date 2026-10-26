interface Env {
  DB: D1Database;
  APP_ENV: string;
  FRONTEND_ORIGIN: string;
}
type JsonRecord = Record<string, unknown>;
function json(data: JsonRecord, status = 200, extraHeaders: HeadersInit = {}): Response {
  return new Response(JSON.stringify(data), { status, headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", "x-content-type-options": "nosniff", "referrer-policy": "no-referrer", ...extraHeaders } });
}
function corsHeaders(request: Request, env: Env): HeadersInit {
  const origin = request.headers.get("Origin");
  const headers: Record<string,string> = { Vary:"Origin", "Access-Control-Allow-Methods":"GET, OPTIONS", "Access-Control-Allow-Headers":"Content-Type, Authorization", "Access-Control-Max-Age":"600" };
  if (origin && origin === env.FRONTEND_ORIGIN) { headers["Access-Control-Allow-Origin"] = origin; headers["Access-Control-Allow-Credentials"] = "true"; }
  return headers;
}
async function handleRequest(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url); const headers = corsHeaders(request, env);
  if (request.method === "OPTIONS") return new Response(null,{status:204,headers});
  if (url.pathname === "/api/health" && request.method === "GET") return json({data:{status:"ok",service:"maximo-ai-api",environment:env.APP_ENV||"unknown",timestamp:new Date().toISOString()}},200,headers);
  if (url.pathname === "/api/dashboard/summary" && request.method === "GET") {
    try {
      const rows = await env.DB.prepare(`
        SELECT
          (SELECT COUNT(*) FROM service_requests WHERE status IN ('NEW','REVIEW','MORE_INFO')) AS service_requests_open,
          (SELECT COUNT(*) FROM work_orders WHERE status NOT IN ('CLOSE','CAN')) AS work_orders_open,
          (SELECT COUNT(*) FROM work_orders WHERE status = 'INPRG') AS work_orders_in_progress,
          (SELECT COUNT(*) FROM pm_schedules WHERE status = 'ACTIVE' AND next_due_date IS NOT NULL AND date(next_due_date) <= date('now', '+7 day')) AS pm_due_soon,
          (SELECT COUNT(*) FROM work_orders WHERE work_type = 'EM' AND status NOT IN ('CLOSE','CAN')) AS emergency_work_orders
      `).first<{service_requests_open:number;work_orders_open:number;work_orders_in_progress:number;pm_due_soon:number;emergency_work_orders:number}>();
      return json({data:{serviceRequestsOpen:rows?.service_requests_open??0,workOrdersOpen:rows?.work_orders_open??0,workOrdersInProgress:rows?.work_orders_in_progress??0,pmDueSoon:rows?.pm_due_soon??0,emergencyWorkOrders:rows?.emergency_work_orders??0}},200,headers);
    } catch(error) {
      console.error(JSON.stringify({level:"error",event:"dashboard_summary_failed",message:error instanceof Error?error.message:"Unknown error"}));
      return json({error:{code:"DASHBOARD_SUMMARY_UNAVAILABLE",message:"Dashboard summary is temporarily unavailable."}},503,headers);
    }
  }
  return json({error:{code:"NOT_FOUND",message:"Endpoint not found."}},404,headers);
}
export default { async fetch(request:Request,env:Env):Promise<Response> { try { return await handleRequest(request,env); } catch(error) { console.error(JSON.stringify({level:"error",event:"unhandled_request_error",message:error instanceof Error?error.message:"Unknown error"})); return json({error:{code:"INTERNAL_ERROR",message:"An unexpected error occurred."}},500); } } };
