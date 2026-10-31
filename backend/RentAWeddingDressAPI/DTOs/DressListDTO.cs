using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace RentAWeddingDressAPI.DTOs
{
    public class DressListDTO
    {
        public int D_id { get; set; }
        public string Title { get; set; }
        public decimal RentPrice { get; set; }
        public string Gender { get; set; }
        public string Image { get; set; }
        public string Occasion { get; set; }
        public double Rating { get; set; }

        // ✅ Per-copy identification (age + condition) on browse cards
        public int Condition { get; set; }
        public string AgeDisplay { get; set; }
    }
}