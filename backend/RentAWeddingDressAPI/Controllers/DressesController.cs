using RentAWeddingDressAPI.DTOs;
using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;

namespace RentAWeddingDressAPI.Controllers
{
    [RoutePrefix("api/dresses")]
    public class DressesController : ApiController
    {
        RentAWeddingDressEntities2 db = new RentAWeddingDressEntities2();

        // ✅ FILTER API
        [HttpPost]
        [Route("filter")]
        public IHttpActionResult FilterDresses(DressFilterDTO filter)
        {
            var query = db.Dresses.AsQueryable();

            // ✅ 1. Search by Title
            if (!string.IsNullOrEmpty(filter.Search))
            {
                query = query.Where(d => d.Dtitle.Contains(filter.Search));
            }

            // ✅ 2. Filter by Category
            if (filter.CategoryId.HasValue)
            {
                query = query.Where(d => d.Category_id == filter.CategoryId);

                // ✅ Auto Gender Rule Based on Category
                var category = db.DressCategories
                                 .FirstOrDefault(c => c.Category_id == filter.CategoryId);

                if (category != null)
                {
                    if (category.Cname == "Bridal")
                        query = query.Where(d => d.Gender == "Female");

                    else if (category.Cname == "Groom")
                        query = query.Where(d => d.Gender == "Male");
                }
            }

            // ✅ 3. Filter by SubCategory
            if (filter.SubCategoryId.HasValue)
            {
                query = query.Where(d => d.SubCategory_id == filter.SubCategoryId);
            }

            // ✅ 4. Manual Gender Filter
            if (!string.IsNullOrEmpty(filter.Gender))
            {
                query = query.Where(d => d.Gender == filter.Gender);
            }


            // ✅ 6. Filter by Size
            if (filter.SizeIds != null && filter.SizeIds.Any())
            {
                query = query.Where(d =>
                    d.DressSizes.Any(s => filter.SizeIds.Contains(s.Size_id)));
            }

            // ✅ 7. Filter by Occasion
            if (!string.IsNullOrEmpty(filter.Occasion))
            {
                query = query.Where(d =>
                    d.DressOccasions.Any(o => o.Occasion == filter.Occasion));
            }

            // ✅ 8. Filter by Date Availability
            if (filter.StartDate.HasValue && filter.EndDate.HasValue)
            {
                query = query.Where(d =>
                    !d.BookingDetails.Any(b =>
                        (b.BookingRequest.Status == 0 ||
                         b.BookingRequest.Status == 1 ||
                         b.BookingRequest.Status == 4 ||
                         b.BookingRequest.Status == 5 ||
                         b.BookingRequest.Status == 6) &&
                        b.BookingRequest.StartingDate <= filter.EndDate &&
                        b.BookingRequest.ReturnDate >= filter.StartDate
                    ));
            }

            // ✅ Price Range
            if (filter.MinPrice.HasValue)
            {
                query = query.Where(d => d.RentPrice >= filter.MinPrice.Value);
            }

            if (filter.MaxPrice.HasValue)
            {
                query = query.Where(d => d.RentPrice <= filter.MaxPrice.Value);
            }

            // ✅ Condition Filter
            if (filter.Condition.HasValue)
            {
                query = query.Where(d => d.Condition == filter.Condition.Value);
            }

            // ✅ Final Result
            var result = query.Select(d => new DressListDTO
            {
                D_id = d.D_id,
                Title = d.Dtitle,
                RentPrice = d.RentPrice,
                Gender = d.Gender,
                Image = d.DressImages.Select(i => i.ImgPath).FirstOrDefault(),
                Occasion = d.DressOccasions.Select(o => o.Occasion).FirstOrDefault(),
                Rating = d.BookingDetails
                            .Where(b => b.Rating != null)
                            .Select(b => (double?)b.Rating)
                            .Average() ?? 0
            }).ToList();

            return Ok(result);
        }

        // ✅ DRESS DETAILS API
        [HttpGet]
        [Route("{id}")]
        public IHttpActionResult GetDressDetails(int id)
        {
            var dress = db.Dresses.FirstOrDefault(d => d.D_id == id);

            if (dress == null)
                return NotFound();

            var result = new DressDetailsDTO
            {
                D_id = dress.D_id,
                Title = dress.Dtitle,
                RentPrice = dress.RentPrice,
                Gender = dress.Gender,
                OwnerId = dress.U_id,

                // ✅ Show Condition as 9/10
                Condition = dress.Condition + "/10",

                Category = dress.DressCategory.Cname,
                SubCategory = dress.SubCategory.SCname,
                Description = dress.Description,

                Images = dress.DressImages
                                .Select(i => i.ImgPath)
                                .ToList(),

                Occasions = dress.DressOccasions
                                .Select(o => o.Occasion)
                                .ToList(),

                Sizes = dress.DressSizes
                                .Select(s => s.Size.SizeName)
                                .ToList(),

                AverageRating = dress.BookingDetails
                                .Where(b => b.Rating != null)
                                .Select(b => (double?)b.Rating)
                                .Average() ?? 0,

                               Reviews = dress.BookingDetails
                                    //.Where(b => b.Rating != null && b.Feedback != null)
                                    .Where(b => b.Rating != null)
                                    .OrderByDescending(b => b.BookingRequest.StartingDate)
                                    .Take(3)
                                    .Select(b => new ReviewDTO
                                    {
                                        UserName = b.BookingRequest.User.Name,
                                        Date = b.BookingRequest.StartingDate,
                                        Rating = b.Rating.Value,
                                        Feedback = b.Feedback
                                    }).ToList()
            };

            return Ok(result);
        }
        [HttpGet]
        [Route("{id}/reviews")]
        public IHttpActionResult GetAllReviews(int id)
        {
            var reviews = db.BookingDetails
                .Where(b => b.D_id == id && b.Rating != null)
                .OrderByDescending(b => b.BookingRequest.StartingDate)
                .Select(b => new ReviewDTO
                {
                    UserName = b.BookingRequest.User.Name,
                    Date = b.BookingRequest.StartingDate,
                    Rating = b.Rating.Value,
                    Feedback = b.Feedback
                }).ToList();

            return Ok(reviews);
        }
        [HttpPost]
        [Route("upload-image")]
        public IHttpActionResult UploadImage()
        {
            var request = System.Web.HttpContext.Current.Request;

            if (request.Files.Count == 0)
                return BadRequest("No file uploaded.");

            var file = request.Files[0];

            // ✅ Generate unique file name
            string extension = Path.GetExtension(file.FileName);
            string newFileName = Guid.NewGuid().ToString() + extension;

            // ✅ Get full save path
            string savePath = System.Web.HttpContext.Current.Server
                                .MapPath("~/Content/images/" + newFileName);

            // ✅ Save file
            file.SaveAs(savePath);

            // ✅ Return relative path
            return Ok(new
            {
                ImagePath = "Content/images/" + newFileName
            });
        }
        [HttpPost]
        [Route("create")]
        public IHttpActionResult CreateDress(CreateDressDTO model)
        {
            if (model == null)
                return BadRequest("Invalid data.");

            if (string.IsNullOrEmpty(model.Dtitle))
                return BadRequest("Title is required.");

            var dress = new Dress
            {
                U_id = model.UserId,
                Dtitle = model.Dtitle,
                Category_id = model.CategoryId,
                SubCategory_id = model.SubCategoryId,
                Gender = model.Gender,
                Condition = model.Condition,
                RentPrice = model.RentPrice,
                Description = model.Description
            };

            db.Dresses.Add(dress);
            db.SaveChanges();

            // ✅ Save Images
            if (model.ImagePaths != null)
            {
                foreach (var img in model.ImagePaths)
                {
                    db.DressImages.Add(new DressImage
                    {
                        D_id = dress.D_id,
                        ImgPath = img
                    });
                }
            }

            // ✅ Save Occasions
            if (model.Occasions != null)
            {
                foreach (var occasion in model.Occasions)
                {
                    db.DressOccasions.Add(new DressOccasion
                    {
                        D_id = dress.D_id,
                        Occasion = occasion
                    });
                }
            }

            // ✅ Save Sizes
            if (model.SizeIds != null)
            {
                foreach (var sizeId in model.SizeIds)
                {
                    db.DressSizes.Add(new DressSize
                    {
                        D_id = dress.D_id,
                        Size_id = sizeId
                    });
                }
            }

            db.SaveChanges();

            return Ok(new
            {
                Message = "Dress uploaded successfully",
                DressId = dress.D_id
            });
        }
        [HttpGet]
        [Route("categories")]
        public IHttpActionResult GetCategories()
        {
            var data = db.DressCategories
                .Select(c => new
                {
                    c.Category_id,
                    c.Cname
                }).ToList();

            return Ok(data);
        }
        [HttpGet]
        [Route("categories/{categoryId}/subcategories")]
        public IHttpActionResult GetSubCategories(int categoryId)
        {
            var data = db.SubCategories
                .Where(s => s.Category_id == categoryId)
                .Select(s => new
                {
                    s.SubCategory_id,
                    s.SCname
                }).ToList();

            return Ok(data);
        }
        [HttpGet]
        [Route("sizes")]
        public IHttpActionResult GetSizes()
        {
            var sizes = db.Sizes
                .Select(s => new
                {
                    s.Size_id,
                    s.SizeName
                }).ToList();

            return Ok(sizes);
        }
    }
}