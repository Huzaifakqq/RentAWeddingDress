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

        // ✅ Delivery pin from Google Maps (optional; stored on UserAddress)
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
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

    // ✅ RIDER: accept / update action on a delivery
    public class RiderActionDTO
    {
        public int BookingId { get; set; }
        public int RiderId { get; set; }

        // "picked" | "delivered" (only used by the action endpoint)
        public string Action { get; set; }
    }

    // ✅ RIDER: one order in the available / my-deliveries feed
    public class RiderOrderDTO
    {
        public int BookingId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int NoOfDays { get; set; }
        public int? Status { get; set; }

        public string CustomerName { get; set; }
        public string CustomerContact { get; set; }
        public string Address { get; set; }
        public decimal? DeliveryLat { get; set; }
        public decimal? DeliveryLng { get; set; }

        public string DressTitle { get; set; }
        public string DressImage { get; set; }
        public decimal? ShopLat { get; set; }
        public decimal? ShopLng { get; set; }

        public decimal TotalPrice { get; set; }

        // Hours until delivery (computed server-side for the countdown)
        public double HoursUntil { get; set; }
    }
}
