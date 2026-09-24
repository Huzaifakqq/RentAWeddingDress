using System;
using System.Collections.Generic;

namespace RentAWeddingDressAPI.DTOs
{
    public class DressFilterDTO
    {
        public string Search { get; set; }

        public int? CategoryId { get; set; }

        public int? SubCategoryId { get; set; }

        public string Gender { get; set; }

        public List<int> SizeIds { get; set; }

        public string Occasion { get; set; }

        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public int? Condition { get; set; }
        public int? FromAgeYears { get; set; }
        public int? FromAgeMonths { get; set; }
        public int? ToAgeYears { get; set; }
        public int? ToAgeMonths { get; set; }

        // ✅ LOCATION FILTER
        public double? UserLat { get; set; }
        public double? UserLng { get; set; }
        public double? MaxKm { get; set; }
    }

    // ✅ Shop owner sets location once for all dresses
    public class ShopLocationDTO
    {
        public int UserId { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}