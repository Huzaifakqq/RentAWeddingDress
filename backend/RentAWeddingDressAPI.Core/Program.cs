using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Formatters;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Npgsql;
using RentAWeddingDressAPI;

// ✅ Match SQL Server datetime behavior (local time, no timezone enforcement).
//    The original app is built entirely on DateTime.Now — same semantics here.
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

// ✅ Controllers with JSON settings that EXACTLY match the old Web API 2 output:
//    PascalCase names (frontend reads "Message", "UserId", "Dtitle", ...)
builder.Services.AddControllers()
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.PropertyNamingPolicy = null;
        o.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
    });

// ✅ EF Core + PostgreSQL (replaces the EF Database-First/EDMX context)
//    Lazy-loading proxies = same behavior as the old EF6 context (virtual navs),
//    e.g. booking.BookingDetails / dress.DressCategory after a plain FirstOrDefault.
builder.Services.AddDbContext<RentAWeddingDressEntities2>(o =>
    o.UseLazyLoadingProxies()
     .UseNpgsql(builder.Configuration.GetConnectionString("Default")
        ?? "Host=localhost;Database=RentAWeddingDress;Username=postgres;Password=postgres"));

// ✅ CORS — same purpose as the CorsHandler in the .NET Framework project
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p
    .AllowAnyOrigin()
    .AllowAnyMethod()
    .AllowAnyHeader()));

// ✅ Parity with Web API 2: string results were JSON-serialized as "text",
//    but ASP.NET Core's StringOutputFormatter would emit text/plain.
//    (The Flutter app jsonDecodes response bodies.)
builder.Services.Configure<MvcOptions>(o =>
    o.OutputFormatters.RemoveType<StringOutputFormatter>());

// ✅ Cloudinary (optional): when creds are configured (Render env vars), dress
//    images upload to Cloudinary — Render's disk is ephemeral and loses files
//    on every redeploy/restart. Without creds everything runs on local disk
//    (the normal local-dev path).
var cc = builder.Configuration.GetSection("Cloudinary");
string cloudName = cc["CloudName"], apiKey = cc["ApiKey"], apiSecret = cc["ApiSecret"];
CloudinaryDotNet.Cloudinary cloudinary = null;
if (!string.IsNullOrWhiteSpace(cloudName) &&
    !string.IsNullOrWhiteSpace(apiKey) &&
    !string.IsNullOrWhiteSpace(apiSecret))
{
    var account = new CloudinaryDotNet.Account(cloudName, apiKey, apiSecret);
    cloudinary = new CloudinaryDotNet.Cloudinary(account);
}
// Holder (not the raw client) — a null Cloudinary can't be constructor-injected
builder.Services.AddSingleton(new CloudinaryHolder { Client = cloudinary });

var app = builder.Build();

app.UseCors();

// ✅ Serve dress images saved under Content/images (like IIS did).
//    IMPORTANT: no MVC route may ever match Content/images/* — ASP.NET Core's
//    StaticFileMiddleware skips any path where an endpoint matched
//    (ValidateNoEndpointDelegate), so a controller route there silently
//    breaks local image serving. The Cloudinary fallback lives in plain
//    middleware below instead.
var imagesDir = Path.Combine(builder.Environment.ContentRootPath, "Content");
Directory.CreateDirectory(imagesDir);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(imagesDir),
    RequestPath = "/Content"
});

// ✅ Cloudinary fallback (cloud deploys only): static files just fell through,
//    meaning the file isn't on the local disk (Render's disk is ephemeral).
//    Redirect to the Cloudinary CDN; in local-disk mode (cloudinary == null)
//    we simply fall through → 404, same as before.
app.Use(async (ctx, next) =>
{
    bool isGetOrHead = HttpMethods.IsGet(ctx.Request.Method) ||
                       HttpMethods.IsHead(ctx.Request.Method);

    if (isGetOrHead &&
        cloudinary != null &&
        ctx.Request.Path.StartsWithSegments("/Content/images", out var rem))
    {
        string fileName = rem.Value.TrimStart('/');

        // Safety: only plain file names (no traversal)
        if (!string.IsNullOrWhiteSpace(fileName) &&
            !fileName.Contains("..") &&
            !fileName.Contains('/') &&
            !fileName.Contains('\\'))
        {
            string ext = Path.GetExtension(fileName);
            string publicId = Path.GetFileNameWithoutExtension(fileName);

            // https://res.cloudinary.com/{cloud}/image/upload/{public_id}.{ext}
            ctx.Response.Redirect(
                $"https://res.cloudinary.com/{cloudName}/image/upload/{publicId}{ext}");
            return;
        }
    }

    await next();
});

app.MapControllers();

app.Run();
