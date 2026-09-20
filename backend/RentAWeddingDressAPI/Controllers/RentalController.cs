using System;
using System.Linq;
using System.Web.Http;
using RentAWeddingDressAPI.DTOs;

namespace RentAWeddingDressAPI.Controllers
{
    [RoutePrefix("api/rentals")]
    public class RentalController : ApiController
    {
        RentAWeddingDressEntities2 db = new RentAWeddingDressEntities2();

        // ✅ 1. GET CUSTOMER RENTALS
        [HttpGet]
        [Route("user/{userId}")]
        public IHttpActionResult GetMyRentals(int userId)
        {
            var rentals = db.BookingRequests
                .Where(b => b.U_id == userId)
                .OrderByDescending(b => b.BR_id)
                .SelectMany(b => b.BookingDetails.Select(d => new MyRentalDTO
                {
                    BookingId = b.BR_id,
                    DressId = d.D_id,
                    DressTitle = d.Dress.Dtitle,
                    Image = d.Dress.DressImages
                                .Select(i => i.ImgPath)
                                .FirstOrDefault(),
                    StartDate = b.StartingDate,
                    EndDate = b.ReturnDate,
                    TotalPrice = d.TotalPrice,
                    Status = b.Status ?? 0,
                    Rating = d.Rating
                }))
                .ToList();

            return Ok(rentals);
        }

        // ✅ 2. GET OWNER BOOKINGS
        [HttpGet]
        [Route("owner/{ownerId}")]
        public IHttpActionResult GetOwnerBookings(int ownerId)
        {
            var bookings = db.BookingDetails
                .Where(d => d.Dress.U_id == ownerId)
                .OrderByDescending(d => d.BR_id)
                .Select(d => new MyRentalDTO
                {
                    BookingId = d.BR_id,
                    DressId = d.D_id,
                    DressTitle = d.Dress.Dtitle,
                    Image = d.Dress.DressImages
                                .Select(i => i.ImgPath)
                                .FirstOrDefault(),
                    StartDate = d.BookingRequest.StartingDate,
                    EndDate = d.BookingRequest.ReturnDate,
                    TotalPrice = d.TotalPrice,
                    Status = d.BookingRequest.Status ?? 0,
                    Rating = d.Rating
                })
                .ToList();

            return Ok(bookings);
        }

        // ✅ 3. UPDATE BOOKING STATUS
        [HttpPost]
        [Route("update-status")]
        public IHttpActionResult UpdateStatus(UpdateStatusDTO model)
        {
            var booking = db.BookingRequests
                            .FirstOrDefault(b => b.BR_id == model.BookingId);

            if (booking == null)
                return NotFound();

            int currentStatus = booking.Status ?? 0;
            int newStatus = model.Status;

            // ✅ VALID TRANSITIONS
            bool isValid = false;

            switch (currentStatus)
            {
                case 0: // Pending
                    if (newStatus == 1 || newStatus == 2 || newStatus == 3)
                        isValid = true;
                    break;

                case 1: // Accepted
                    if (newStatus == 4)
                        isValid = true;
                    break;

                case 4: // Picked by Owner
                    if (newStatus == 5)
                        isValid = true;
                    break;

                case 5: // Pickup Confirmed
                    if (newStatus == 6)
                        isValid = true;
                    break;

                case 6: // Return Requested
                    if (newStatus == 7)
                        isValid = true;
                    break;
            }

            if (!isValid)
                return BadRequest("Invalid status transition.");

            booking.Status = newStatus;
            db.SaveChanges();

            return Ok("Booking status updated successfully.");
        }

        // ✅ 4. ADD REVIEW (Only After Completion)
        [HttpPost]
        [Route("add-review")]
        public IHttpActionResult AddReview(AddReviewDTO model)
        {
            if (model == null)
                return BadRequest("Invalid data.");

            // ✅ Validate rating range
            if (model.Rating < 1 || model.Rating > 5)
                return BadRequest("Rating must be between 1 and 5.");

            var booking = db.BookingRequests
                            .FirstOrDefault(b => b.BR_id == model.BookingId);

            if (booking == null)
                return NotFound();

            // ✅ Only allow review after completion
            if (booking.Status != 7)
                return BadRequest("Review allowed only after booking is completed.");

            var bookingDetail = db.BookingDetails
                                  .FirstOrDefault(d =>
                                      d.BR_id == model.BookingId &&
                                      d.D_id == model.DressId);

            if (bookingDetail == null)
                return NotFound();

            // ✅ Prevent duplicate review
            if (bookingDetail.Rating != null)
                return BadRequest("Review already submitted.");

            // ✅ Save rating only (no feedback)
            bookingDetail.Rating = model.Rating;

            db.SaveChanges();

            return Ok(new
            {
                Message = "Review submitted successfully."
            });
        }
    }
}