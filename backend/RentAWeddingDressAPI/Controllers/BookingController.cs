using RentAWeddingDressAPI.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace RentAWeddingDressAPI.Controllers
{
    [RoutePrefix("api/bookings")]
    public class BookingController : ApiController
    {
        RentAWeddingDressEntities2 db = new RentAWeddingDressEntities2();

        // ✅ CHECK AVAILABILITY
        [HttpPost]
        [Route("check")]
        public IHttpActionResult CheckAvailability(CheckAvailabilityDTO model)
        {
            if (model.StartDate > model.EndDate)
                return BadRequest("End date must be greater than start date.");

            var dress = db.Dresses.FirstOrDefault(d => d.D_id == model.DressId);

            if (dress == null)
                return NotFound();

            bool isBooked = db.BookingDetails.Any(b =>
                    b.D_id == model.DressId &&
                    (b.BookingRequest.Status == 0 ||
                     b.BookingRequest.Status == 1 ||
                     b.BookingRequest.Status == 4 ||
                     b.BookingRequest.Status == 5 ||
                     b.BookingRequest.Status == 6) &&
                    b.BookingRequest.StartingDate <= model.EndDate &&
                    b.BookingRequest.ReturnDate >= model.StartDate
                    );

            int numberOfDays = (model.EndDate - model.StartDate).Days + 1;
            decimal rentPerDay = dress.RentPrice;
            decimal totalCost = rentPerDay * numberOfDays;

            if (isBooked)
            {
                return Ok(new AvailabilityResponseDTO
                {
                    IsAvailable = false,
                    Message = "Dress is not available for selected dates."
                });
            }

            return Ok(new AvailabilityResponseDTO
            {
                IsAvailable = true,
                NumberOfDays = numberOfDays,
                RentPerDay = rentPerDay,
                TotalCost = totalCost,
                Message = "Dress is available for selected dates."
            });
        }

        // ✅ CONFIRM BOOKING
        [HttpPost]
        [Route("confirm")]
        public IHttpActionResult ConfirmBooking(ConfirmBookingDTO model)
        {
            if (model.StartDate > model.EndDate)
                return BadRequest("Invalid date selection.");

            var dress = db.Dresses.FirstOrDefault(d => d.D_id == model.DressId);
            if (dress == null)
                return NotFound();

            bool isBooked = db.BookingDetails.Any(b =>
                    b.D_id == model.DressId &&
                    (b.BookingRequest.Status == 0 ||
                     b.BookingRequest.Status == 1 ||
                     b.BookingRequest.Status == 4 ||
                     b.BookingRequest.Status == 5 ||
                     b.BookingRequest.Status == 6) &&
                    b.BookingRequest.StartingDate <= model.EndDate &&
                    b.BookingRequest.ReturnDate >= model.StartDate
                );

            if (isBooked)
                return BadRequest("Dress is no longer available for selected dates.");

            int numberOfDays = (model.EndDate - model.StartDate).Days + 1;
            decimal totalPrice = dress.RentPrice * numberOfDays;

            var bookingRequest = new BookingRequest
            {
                U_id = model.UserId,
                UserAddressID = model.UserAddressId,
                StartingDate = model.StartDate,
                ReturnDate = model.EndDate,
                NoOfDays = numberOfDays,
                Status = 0
            };

            db.BookingRequests.Add(bookingRequest);
            db.SaveChanges();

            var bookingDetail = new BookingDetail
            {
                BR_id = bookingRequest.BR_id,
                D_id = model.DressId,
                TotalPrice = totalPrice
            };

            db.BookingDetails.Add(bookingDetail);
            db.SaveChanges();

            return Ok(new
            {
                Message = "Booking confirmed successfully.",
                BookingId = bookingRequest.BR_id,
                TotalPrice = totalPrice
            });
        }

    }
}
