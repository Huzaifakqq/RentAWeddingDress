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
    }
}