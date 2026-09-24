using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;

namespace RentAWeddingDressAPI
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // Show real exception details during development
            config.IncludeErrorDetailPolicy = IncludeErrorDetailPolicy.Always;

            // Web API configuration and services

            // Web API routes
            config.MapHttpAttributeRoutes();

            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );
        }
    }
}
