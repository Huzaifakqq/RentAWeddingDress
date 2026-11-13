using Microsoft.AspNetCore.Mvc;

namespace RentAWeddingDressAPI.Controllers
{
    // ✅ Ported from Web API 2 → ASP.NET Core (same routes + JSON)
    [Route("api/categories")]
    public class CategoryController : ControllerBase
    {
        private readonly RentAWeddingDressEntities2 db;

        public CategoryController(RentAWeddingDressEntities2 context)
        {
            db = context;
        }

        // ✅ Get All Categories (First Dropdown)
        [HttpGet]
        [Route("all")]
        public ActionResult GetCategories()
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
        public ActionResult GetSubCategories(int categoryId)
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
