using Microsoft.AspNetCore.Mvc;
using RentAWeddingDressAPI.DTOs;

namespace RentAWeddingDressAPI.Controllers
{
    // ✅ Ported from Web API 2 → ASP.NET Core (same routes + JSON)
    [Route("api/dresses")]
    public class DressesController : ControllerBase
    {
        private readonly RentAWeddingDressEntities2 db;
        private readonly IWebHostEnvironment env;
        private readonly CloudinaryDotNet.Cloudinary cloudinary;

        public DressesController(RentAWeddingDressEntities2 context,
                                 IWebHostEnvironment environment,
                                 CloudinaryHolder holder)
        {
            db = context;
            env = environment;
            cloudinary = holder.Client; // null = local-disk mode
        }

        // ✅ FILTER API
        [HttpPost]
        [Route("filter")]
        public ActionResult FilterDresses([FromBody] DressFilterDTO filter)
        {
            if (filter == null)
                filter = new DressFilterDTO();

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

            // ✅ Age Filter
            if (filter.FromAgeYears.HasValue || filter.FromAgeMonths.HasValue ||
                filter.ToAgeYears.HasValue || filter.ToAgeMonths.HasValue)
            {
                int fromMonths = ((filter.FromAgeYears ?? 0) * 12) + (filter.FromAgeMonths ?? 0);
                int toMonths = ((filter.ToAgeYears ?? 0) * 12) + (filter.ToAgeMonths ?? 0);
                if (toMonths == 0) toMonths = 999;

                query = query.Where(d =>
                    (((d.AgeYears ?? 0) * 12) + (d.AgeMonths ?? 0)) >= fromMonths &&
                    (((d.AgeYears ?? 0) * 12) + (d.AgeMonths ?? 0)) <= toMonths);
            }

            // ✅ LOCATION FILTER (bounding box, simple for exam)
            if (filter.UserLat.HasValue && filter.UserLng.HasValue)
            {
                double userLat = filter.UserLat.Value;
                double userLng = filter.UserLng.Value;
                double maxKm = filter.MaxKm ?? 50;

                double latDelta = maxKm / 111.0;
                double lngDelta = maxKm /
                    (111.0 * Math.Cos(userLat * Math.PI / 180.0));

                decimal minLat = (decimal)(userLat - latDelta);
                decimal maxLat = (decimal)(userLat + latDelta);
                decimal minLng = (decimal)(userLng - lngDelta);
                decimal maxLng = (decimal)(userLng + lngDelta);

                query = query.Where(d =>
                    d.Latitude >= minLat && d.Latitude <= maxLat &&
                    d.Longitude >= minLng && d.Longitude <= maxLng);
            }

            // ✅ Final Result (materialize first — FormatAge can't translate to SQL)
            var raw = query.Select(d => new
            {
                d.D_id,
                Title = d.Dtitle,
                d.RentPrice,
                d.Gender,
                Image = d.DressImages.Select(i => i.ImgPath).FirstOrDefault(),
                Occasion = d.DressOccasions.Select(o => o.Occasion).FirstOrDefault(),
                Rating = d.BookingDetails
                            .Where(b => b.Rating != null)
                            .Select(b => (double?)b.Rating)
                            .Average() ?? 0,
                d.Condition,
                d.AgeYears,
                d.AgeMonths,
                d.AgeDays
            }).ToList();

            var result = raw.Select(r => new DressListDTO
            {
                D_id = r.D_id,
                Title = r.Title,
                RentPrice = r.RentPrice,
                Gender = r.Gender,
                Image = r.Image,
                Occasion = r.Occasion,
                Rating = r.Rating,
                Condition = r.Condition ?? 0,
                AgeDisplay = FormatAge(r.AgeYears, r.AgeMonths, r.AgeDays)
            }).ToList();

            return Ok(result);
        }

        // ✅ MY LISTINGS — every dress uploaded by the logged-in owner
        [HttpGet]
        [Route("user/{userId}")]
        public ActionResult GetMyListings(int userId)
        {
            var raw = db.Dresses
                .Where(d => d.U_id == userId)
                .Select(d => new
                {
                    d.D_id,
                    Title = d.Dtitle,
                    d.RentPrice,
                    d.Gender,
                    Image = d.DressImages.Select(i => i.ImgPath).FirstOrDefault(),
                    Occasion = d.DressOccasions.Select(o => o.Occasion).FirstOrDefault(),
                    Rating = d.BookingDetails
                                .Where(b => b.Rating != null)
                                .Select(b => (double?)b.Rating)
                                .Average() ?? 0,
                    d.Condition,
                    d.AgeYears,
                    d.AgeMonths,
                    d.AgeDays
                }).ToList();

            var result = raw.Select(r => new DressListDTO
            {
                D_id = r.D_id,
                Title = r.Title,
                RentPrice = r.RentPrice,
                Gender = r.Gender,
                Image = r.Image,
                Occasion = r.Occasion,
                Rating = r.Rating,
                Condition = r.Condition ?? 0,
                AgeDisplay = FormatAge(r.AgeYears, r.AgeMonths, r.AgeDays)
            }).ToList();

            return Ok(result);
        }

        // ✅ DRESS DETAILS API
        [HttpGet]
        [Route("{id}")]
        public ActionResult GetDressDetails(int id)
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

                // ✅ Show Dress Age + Condition
                Condition = dress.Condition ?? 0,
                AgeDisplay = FormatAge(dress.AgeYears, dress.AgeMonths, dress.AgeDays),

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

                SizeStocks = dress.DressSizes
                                .Select(s => new SizeStockDTO
                                {
                                    SizeId = s.Size_id,
                                    SizeName = s.Size.SizeName,
                                    Stock = s.Stock ?? 1
                                }).ToList(),

                AverageRating = dress.BookingDetails
                                .Where(b => b.Rating != null)
                                .Select(b => (double?)b.Rating)
                                .Average() ?? 0,

                               Reviews = dress.BookingDetails
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
        public ActionResult GetAllReviews(int id)
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

        // ✅ Same contract as Web API 2: multipart field "file" → { "ImagePath": "Content/images/..." }
        //    With Cloudinary configured (cloud deploy) the BYTES go to Cloudinary but the
        //    stored path format stays identical, so the app & DB format never change.
        [HttpPost]
        [Route("upload-image")]
        public ActionResult UploadImage([FromForm] IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { Message = "No file uploaded." });

            // ✅ Generate unique file name
            string extension = Path.GetExtension(file.FileName);
            string newFileName = Guid.NewGuid().ToString() + extension;
            string relativePath = "Content/images/" + newFileName;

            if (cloudinary != null)
            {
                // ☁️ Cloud mode: store on Cloudinary (Render's disk is ephemeral)
                var uploadParams = new CloudinaryDotNet.Actions.ImageUploadParams
                {
                    File = new CloudinaryDotNet.FileDescription(newFileName, file.OpenReadStream()),
                    PublicId = Path.GetFileNameWithoutExtension(newFileName),
                    Format = extension.TrimStart('.'),
                    Overwrite = false,
                    UniqueFilename = false
                };

                var result = cloudinary.Upload(uploadParams);

                if (result.StatusCode != System.Net.HttpStatusCode.OK)
                    return BadRequest(new { Message = "Image upload failed." });

                return Ok(new { ImagePath = relativePath });
            }

            // 💾 Local mode (normal dev): save to Content/images like IIS did
            string imagesDir = Path.Combine(env.ContentRootPath, "Content", "images");
            Directory.CreateDirectory(imagesDir);
            string savePath = Path.Combine(imagesDir, newFileName);

            using (var stream = System.IO.File.Create(savePath))
            {
                file.CopyTo(stream);
            }

            // ✅ Return relative path
            return Ok(new
            {
                ImagePath = relativePath
            });
        }

        [HttpPost]
        [Route("create")]
        public ActionResult CreateDress([FromBody] CreateDressDTO model)
        {
            if (model == null)
                return BadRequest(new { Message = "Invalid data." });

            if (string.IsNullOrEmpty(model.Dtitle))
                return BadRequest(new { Message = "Title is required." });

            // ✅ Auto-copy shop location from any existing dress of this owner
            var existingWithLocation = db.Dresses
                .Where(d => d.U_id == model.UserId &&
                            d.Latitude != null && d.Longitude != null)
                .FirstOrDefault();

            // ✅ MULTI-COPY UPLOAD: one separate listing (Dress row) per physical copy,
            //    each with its own size, age and condition → shown individually on browse
            if (model.Copies != null && model.Copies.Count > 0)
            {
                var createdIds = new System.Collections.Generic.List<int>();

                foreach (var copy in model.Copies)
                {
                    var copyDress = new Dress
                    {
                        U_id = model.UserId,
                        Dtitle = model.Dtitle,
                        Category_id = model.CategoryId,
                        SubCategory_id = model.SubCategoryId,
                        Gender = model.Gender,
                        Condition = copy.Condition,
                        AgeYears = copy.AgeYears,
                        AgeMonths = copy.AgeMonths,
                        AgeDays = copy.AgeDays,
                        // ✅ Per-copy price (better-condition copy can cost more)
                        RentPrice = copy.Price ?? model.RentPrice,
                        Description = model.Description,
                        Latitude = existingWithLocation?.Latitude,
                        Longitude = existingWithLocation?.Longitude
                    };

                    db.Dresses.Add(copyDress);
                    db.SaveChanges(); // get D_id for child rows

                    // Same images for every copy (shared photo set)
                    if (model.ImagePaths != null)
                    {
                        foreach (var img in model.ImagePaths)
                            db.DressImages.Add(new DressImage { D_id = copyDress.D_id, ImgPath = img });
                    }

                    // Same occasions for every copy
                    if (model.Occasions != null)
                    {
                        foreach (var occasion in model.Occasions)
                            db.DressOccasions.Add(new DressOccasion { D_id = copyDress.D_id, Occasion = occasion });
                    }

                    // One physical copy = one size, stock 1
                    db.DressSizes.Add(new DressSize
                    {
                        D_id = copyDress.D_id,
                        Size_id = copy.SizeId,
                        Stock = 1
                    });

                    db.SaveChanges();
                    createdIds.Add(copyDress.D_id);
                }

                return Ok(new
                {
                    Message = model.Copies.Count + " copies uploaded successfully",
                    DressId = createdIds[0],
                    DressIds = createdIds
                });
            }

            // ✅ SINGLE COPY (legacy path): one listing, sizes with stock
            var dress = new Dress
            {
                U_id = model.UserId,
                Dtitle = model.Dtitle,
                Category_id = model.CategoryId,
                SubCategory_id = model.SubCategoryId,
                Gender = model.Gender,
                Condition = model.Condition,
                AgeYears = model.AgeYears,
                AgeMonths = model.AgeMonths,
                AgeDays = model.AgeDays,
                RentPrice = model.RentPrice,
                Description = model.Description,
                // Inherit shop pin so Near Me works for new uploads
                Latitude = existingWithLocation?.Latitude,
                Longitude = existingWithLocation?.Longitude
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

            // ✅ Save Sizes with Stock
            if (model.SizeIds != null)
            {
                foreach (var sizeId in model.SizeIds)
                {
                    int stock = 1;
                    if (model.SizeStock != null && model.SizeStock.ContainsKey(sizeId))
                        stock = model.SizeStock[sizeId];

                    db.DressSizes.Add(new DressSize
                    {
                        D_id = dress.D_id,
                        Size_id = sizeId,
                        Stock = stock
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
        public ActionResult GetCategories()
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
        public ActionResult GetSubCategories(int categoryId)
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
        public ActionResult GetSizes()
        {
            var sizes = db.Sizes
                .Select(s => new
                {
                    s.Size_id,
                    s.SizeName
                }).ToList();

            return Ok(sizes);
        }

        private string FormatAge(int? years, int? months, int? days)
        {
            var parts = new System.Collections.Generic.List<string>();
            int y = years ?? 0;
            int m = months ?? 0;
            int d = days ?? 0;
            if (y > 0) parts.Add($"{y} year{(y > 1 ? "s" : "")}");
            if (m > 0) parts.Add($"{m} month{(m > 1 ? "s" : "")}");
            if (d > 0) parts.Add($"{d} day{(d > 1 ? "s" : "")}");
            return parts.Count > 0 ? string.Join(" ", parts) + " old" : "New";
        }
    }
}
