using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace RentAWeddingDressAPI.DTOs
{
    public class CreateDressDTO
    {
        public int UserId { get; set; }

        public string Dtitle { get; set; }

        public int CategoryId { get; set; }

        public int SubCategoryId { get; set; }

        public string Gender { get; set; }

        public int Condition { get; set; }

        public int AgeYears { get; set; }

        public int AgeMonths { get; set; }

        public int AgeDays { get; set; }

        public decimal RentPrice { get; set; }

        public string Description { get; set; }

        public List<string> Occasions { get; set; }

        public List<int> SizeIds { get; set; }

        public List<string> ImagePaths { get; set; }
    }
}