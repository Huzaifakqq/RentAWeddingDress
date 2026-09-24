using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace RentAWeddingDressAPI.DTOs
{
    // ✅ One size line in a multi-size order
    public class BookingItemDTO
    {
        public int SizeId { get; set; }
        public int Quantity { get; set; }
    }

    // ✅ Check Availability Request
    public class CheckAvailabilityDTO
    {
        public int DressId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public List<BookingItemDTO> Items { get; set; }
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

    // ✅ Confirm Booking Request (supports multiple sizes)
    public class ConfirmBookingDTO
    {
        public int UserId { get; set; }
        public int DressId { get; set; }
        public int UserAddressId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public List<BookingItemDTO> Items { get; set; }
    }

    // ✅ Cancel Booking Request
    public class CancelBookingDTO
    {
        public int UserId { get; set; }
        public int BookingId { get; set; }
    }

    // ✅ Reschedule Booking Request
    public class RescheduleDTO
    {
        public int UserId { get; set; }
        public int BookingId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
