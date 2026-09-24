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

        // ✅ 1. GET CUSTOMER RENTALS (one row per booking, multi-size combined)
        [HttpGet]
        [Route("user/{userId}")]
        public IHttpActionResult GetMyRentals(int userId)
        {
            var raw = db.BookingRequests
                .Where(b => b.U_id == userId)
                .OrderByDescending(b => b.BR_id)
                .Select(b => new
                {
                    b.BR_id,
                    b.StartingDate,
                    b.ReturnDate,
                    b.Status,
                    Det = b.BookingDetails.Select(d => new
                    {
                        d.D_id,
                        Title = d.Dress.Dtitle,
                        Image = d.Dress.DressImages
                                    .Select(i => i.ImgPath)
                                    .FirstOrDefault(),
                        d.TotalPrice,
                        d.Rating,
                        d.Quantity,
                        d.Size_id
                    })
                })
                .AsEnumerable()
                .Select(x => new
                {
                    x.BR_id,
                    x.StartingDate,
                    x.ReturnDate,
                    x.Status,
                    Det = x.Det.ToList()
                })
                .ToList();

            var rentals = raw.Select(x => new MyRentalDTO
            {
                BookingId = x.BR_id,
                DressId = x.Det.Select(d => d.D_id).FirstOrDefault(),
                DressTitle = x.Det.Select(d => d.Title).FirstOrDefault(),
                Image = x.Det.Select(d => d.Image).FirstOrDefault(),
                StartDate = x.StartingDate,
                EndDate = x.ReturnDate,
                TotalPrice = x.Det.Sum(d => d.TotalPrice),
                Status = x.Status ?? 0,
                Rating = x.Det.Select(d => d.Rating).FirstOrDefault(r => r != null),
                SizeSummary = string.Join(", ", x.Det.Select(d =>
                {
                    string name = d.Size_id == null
                        ? "?"
                        : db.Sizes.Where(s => s.Size_id == d.Size_id)
                                  .Select(s => s.SizeName).FirstOrDefault();
                    return name + " x " + (d.Quantity ?? 1);
                }))
            }).ToList();

            return Ok(rentals);
        }

        // ✅ 2. GET OWNER BOOKINGS (one row per booking on owner's dresses)
        [HttpGet]
        [Route("owner/{ownerId}")]
        public IHttpActionResult GetOwnerBookings(int ownerId)
        {
            var raw = db.BookingDetails
                .Where(d => d.Dress.U_id == ownerId)
                .Select(d => new
                {
                    d.BR_id,
                    d.D_id,
                    Title = d.Dress.Dtitle,
                    Image = d.Dress.DressImages
                                .Select(i => i.ImgPath)
                                .FirstOrDefault(),
                    d.TotalPrice,
                    d.Rating,
                    d.Quantity,
                    d.Size_id,
                    d.BookingRequest.StartingDate,
                    d.BookingRequest.ReturnDate,
                    d.BookingRequest.Status
                })
                .ToList();

            var bookings = raw
                .GroupBy(x => x.BR_id)
                .Select(g => new MyRentalDTO
                {
                    BookingId = g.Key,
                    DressId = g.Select(x => x.D_id).FirstOrDefault(),
                    DressTitle = g.Select(x => x.Title).FirstOrDefault(),
                    Image = g.Select(x => x.Image).FirstOrDefault(),
                    StartDate = g.Select(x => x.StartingDate).FirstOrDefault(),
                    EndDate = g.Select(x => x.ReturnDate).FirstOrDefault(),
                    TotalPrice = g.Sum(x => x.TotalPrice),
                    Status = g.Select(x => x.Status).FirstOrDefault() ?? 0,
                    Rating = g.Select(x => x.Rating).FirstOrDefault(r => r != null),
                    SizeSummary = string.Join(", ", g.Select(x =>
                    {
                        string name = x.Size_id == null
                            ? "?"
                            : db.Sizes.Where(s => s.Size_id == x.Size_id)
                                      .Select(s => s.SizeName).FirstOrDefault();
                        return name + " x " + (x.Quantity ?? 1);
                    }))
                })
                .OrderByDescending(x => x.BookingId)
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
                    // Cancel goes through /bookings/cancel (penalty logic)
                    if (newStatus == 1 || newStatus == 3)
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