using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace RentAWeddingDressAPI.DTOs
{
    public class DressDetailsDTO
    {
        public int OwnerId { get; set; }
        public int D_id { get; set; }
        public string Title { get; set; }
        public decimal RentPrice { get; set; }
        public string Gender { get; set; }
        public string Condition { get; set; }
        public string Category { get; set; }
        public string SubCategory { get; set; }
        public string Description { get; set; }

        public List<string> Images { get; set; }
        public List<string> Occasions { get; set; }
        public List<string> Sizes { get; set; }

        public double AverageRating { get; set; }

        public List<ReviewDTO> Reviews { get; set; }
    }

    public class ReviewDTO
    {
        public string UserName { get; set; }
        public DateTime Date { get; set; }
        public int Rating { get; set; }
        public string Feedback { get; set; }
    }
}