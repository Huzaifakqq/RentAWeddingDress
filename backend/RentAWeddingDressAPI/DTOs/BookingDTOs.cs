using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace RentAWeddingDressAPI.DTOs
{
    // ✅ Check Availability Request
    public class CheckAvailabilityDTO
    {
        public int DressId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }

    // ✅ Check Availability Response
    public class AvailabilityResponseDTO
    {
        public bool IsAvailable { get; set; }
        public int NumberOfDays { get; set; }
        public decimal RentPerDay { get; set; }
        public decimal TotalCost { get; set; }
        public string Message { get; set; }
    }

    // ✅ Confirm Booking Request
    public class ConfirmBookingDTO
    {
        public int UserId { get; set; }
        public int DressId { get; set; }
        public int UserAddressId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}