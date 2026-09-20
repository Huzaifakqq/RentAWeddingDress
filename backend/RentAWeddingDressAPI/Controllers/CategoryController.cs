using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace RentAWeddingDressAPI.Controllers
{
    [RoutePrefix("api/categories")]
    public class CategoryController : ApiController
    {
        RentAWeddingDressEntities2 db = new RentAWeddingDressEntities2();

        // ✅ Get All Categories (First Dropdown)
        [HttpGet]
        [Route("all")]
        public IHttpActionResult GetCategories()
        {
            var categories = db.DressCategories
                .Select(c => new
                {
                    c.Category_id,
                    c.Cname
                }).ToList();

            return Ok(categories);
        }

        // ✅ Get SubCategories by CategoryId (Second Dropdown)
        [HttpGet]
        [Route("{categoryId}/subcategories")]
        public IHttpActionResult GetSubCategories(int categoryId)
        {
            var subcategories = db.SubCategories
                .Where(s => s.Category_id == categoryId)
                .Select(s => new
                {
                    s.SubCategory_id,
                    s.SCname
                }).ToList();

            return Ok(subcategories);
        }
    }
}
