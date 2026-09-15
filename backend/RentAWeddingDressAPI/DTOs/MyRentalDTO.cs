using System;

namespace RentAWeddingDressAPI.DTOs
{
    public class MyRentalDTO
    {
        public int BookingId { get; set; }
        public int DressId { get; set; }
        public string DressTitle { get; set; }
        public string Image { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal TotalPrice { get; set; }
        public int Status { get; set; }
        public int? Rating { get; set; }
    }

    public class UpdateStatusDTO
    {
        public int BookingId { get; set; }
        public int Status { get; set; }
    }

    public class AddReviewDTO
    {
        public int BookingId { get; set; }
        public int DressId { get; set; }
        public int Rating { get; set; }
        public string Feedback { get; set; }
    }
}