using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;

namespace RentAWeddingDressAPI
{
    // ✅ CORS handler: lets the Flutter WEB build (e.g. hosted on Vercel)
    //    call this API from the browser. The Android app doesn't need this,
    //    but browsers block cross-origin API calls unless the server allows it.
    //    No NuGet package required — works on any machine that clones the repo.
    public class CorsHandler : DelegatingHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken cancellationToken)
        {
            // Browser preflight (OPTIONS) — answer directly without hitting a controller
            if (request.Method == HttpMethod.Options)
            {
                var ok = request.CreateResponse(HttpStatusCode.OK);
                AddCorsHeaders(request, ok);
                return Task.FromResult(ok);
            }

            return base.SendAsync(request, cancellationToken).ContinueWith(
                t =>
                {
                    var response = t.Result;
                    AddCorsHeaders(request, response);
                    return response;
                },
                TaskContinuationOptions.ExecuteSynchronously);
        }

        private static void AddCorsHeaders(HttpRequestMessage request, HttpResponseMessage response)
        {
            // Echo the caller's Origin (safe here: API uses no cookies/auth headers)
            string origin = "*";
            if (request.Headers.Contains("Origin"))
            {
                origin = request.Headers.GetValues("Origin").FirstOrDefault() ?? "*";
            }

            if (!response.Headers.Contains("Access-Control-Allow-Origin"))
                response.Headers.Add("Access-Control-Allow-Origin", origin);

            if (!response.Headers.Contains("Vary"))
                response.Headers.Add("Vary", "Origin");

            if (!response.Headers.Contains("Access-Control-Allow-Methods"))
                response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");

            if (!response.Headers.Contains("Access-Control-Allow-Headers"))
                response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
        }
    }
}
